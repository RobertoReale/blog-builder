<#
  run.ps1 — Runs the blog prompts in sequence via Claude Code (headless mode),
  one step at a time, each in a NEW SESSION (so the context window never fills up),
  and after each step independently verifies that the build (and unit tests) pass.
  If something breaks, it STOPS: it never builds on top of a broken state.

  USAGE:
    .\run.ps1                              # runs all steps, stopping at the first error
    .\run.ps1 -Pause                       # also pauses after each step to inspect output
    .\run.ps1 -StartStep 3                 # resumes from step 3 (after you fixed an error)
    .\run.ps1 -StartStep 3 -EndStep 5      # runs only steps 3, 4, and 5
#>

param(
  [int]$StartStep = 0,
  [int]$EndStep = -1,
  [switch]$Pause
)

$ErrorActionPreference = "Continue" # Changed from Stop to prevent 2>&1 from crashing on external stderr

# Step order. Step 0 (foundation) creates the project; the others extend it.
$prompts = @(
  "prompt_blog_00_foundation.txt",  # 0  Foundation
  "prompt_blog_01_testing.txt",     # 1  Testing (Vitest + Playwright)
  "prompt_blog_02_seo.txt",         # 2  Feature 01 - SEO
  "prompt_blog_03_reading_ux.txt",  # 3  Feature 02 - Reading UX
  "prompt_blog_04_search.txt",      # 4  Feature 03 - Search (Pagefind)
  "prompt_blog_05_series.txt",      # 5  Feature 04 - Series
  "prompt_blog_06_related.txt",     # 6  Feature 05 - Related
  "prompt_blog_07_keystatic.txt",   # 7  Feature 06 - Keystatic CMS
  "prompt_blog_08_e2e_check.txt"    # 8  E2E integration check
)

$stepNames = @(
  "Foundation",
  "Testing setup",
  "SEO",
  "Reading UX",
  "Search",
  "Series",
  "Related articles",
  "Keystatic CMS",
  "E2E integration check"
)

# --- Preliminary checks ----------------------------------------------------
function Assert-Command($name, $hint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: '$name' not found. $hint" -ForegroundColor Red
    exit 1
  }
}
Assert-Command "claude" "Install Claude Code (see SETUP.md) and reopen the terminal."
Assert-Command "node"   "Install Node.js LTS from https://nodejs.org"
Assert-Command "npm"    "Install Node.js LTS from https://nodejs.org"

if (-not (Test-Path "CLAUDE.md")) {
  Write-Host "ERROR: CLAUDE.md not found. Run this script from the folder that contains it." -ForegroundColor Red
  exit 1
}

New-Item -ItemType Directory -Force -Path "logs" | Out-Null

# --- Verification gate (anti-drift mechanism) ------------------------------
function Test-Project([bool]$InstallNeeded = $true) {
  if (-not (Test-Path "package.json")) {
    Write-Host "  (package.json not present yet — skipping verification)" -ForegroundColor DarkGray
    return $true
  }

  if ($InstallNeeded) {
    Write-Host "  -> npm install" -ForegroundColor Cyan
    npm install --no-audit --no-fund 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) { return $false }
  } else {
    Write-Host "  -> npm install (skipped — package.json unchanged)" -ForegroundColor DarkGray
  }

  Write-Host "  -> npm run build" -ForegroundColor Cyan
  npm run build 2>&1 | Out-Host
  if ($LASTEXITCODE -ne 0) { return $false }

  $pkg = Get-Content package.json -Raw | ConvertFrom-Json
  if ($pkg.scripts.'test:unit') {
    Write-Host "  -> npm run test:unit" -ForegroundColor Cyan
    npm run test:unit 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) { return $false }
  }
  return $true
}

# --- Git init (if needed) -------------------------------------------------
if (-not (Test-Path ".git")) {
  git init | Out-Null
  git add -A | Out-Null
  $null = git commit -m "Initial commit (pre-pipeline)" --quiet 2>&1
}

# --- Main loop -------------------------------------------------------------
$instruction = @"
You are working in a project folder that contains CLAUDE.md: read it FIRST and follow every rule in it.
Your standard input contains the instructions for the current task: execute them EXACTLY, without adding
unrequested features. When done, run 'npm run build' (and 'npm run test:unit' if that script exists) and
fix any errors until they pass. Do not go beyond the task you received.
"@

$stopAt = if ($EndStep -ge 0 -and $EndStep -lt $prompts.Count) { $EndStep } else { $prompts.Count - 1 }

for ($i = $StartStep; $i -le $stopAt; $i++) {
  $file = $prompts[$i]
  Write-Host ""
  Write-Host "===================================================" -ForegroundColor White
  Write-Host " STEP $i  ->  $file" -ForegroundColor White
  Write-Host "===================================================" -ForegroundColor White

  if (-not (Test-Path $file)) {
    Write-Host "ERROR: prompt file missing: $file" -ForegroundColor Red
    break
  }

  # Capture package.json state before Claude runs to detect dependency changes
  $pkgBefore = if (Test-Path "package.json") { Get-Content "package.json" -Raw } else { $null }

  # Separate NEW session: context is only CLAUDE.md + files already on disk.
  # The actual prompt is passed via stdin (avoids quoting issues with long texts).
  Get-Content $file -Raw | claude -p $instruction `
    --permission-mode acceptEdits `
    --allowedTools "Bash,Read,Edit,Write,Glob,Grep,MultiEdit" `
    --output-format stream-json 2>&1 | Tee-Object -FilePath "logs\step_$i.json"
  $claudeExit = $LASTEXITCODE

  if ($claudeExit -ne 0) {
    Write-Host ""
    Write-Host "Claude terminated with an error at step $i. Stopping." -ForegroundColor Red
    Write-Host "Check logs\step_$i.json, fix the issue, then resume with:  .\run.ps1 -StartStep $i" -ForegroundColor Yellow
    break
  }

  # Skip npm install if package.json is unchanged and node_modules already exists
  $pkgAfter = if (Test-Path "package.json") { Get-Content "package.json" -Raw } else { $null }
  $installNeeded = (-not (Test-Path "node_modules")) -or ($pkgBefore -ne $pkgAfter)

  Write-Host ""
  Write-Host "  Independent verification of step $i..." -ForegroundColor Cyan
  if (-not (Test-Project -InstallNeeded $installNeeded)) {
    Write-Host ""
    Write-Host "BUILD/TEST FAILED at step $i ($file)." -ForegroundColor Red
    Write-Host "Stopping here intentionally, to prevent building on a broken state." -ForegroundColor Red
    Write-Host ""
    Write-Host "WHAT TO DO NOW:" -ForegroundColor Yellow
    Write-Host "  1) Open this folder in VS Code." -ForegroundColor Yellow
    Write-Host "  2) Run 'claude' (interactive) and describe/paste the build error." -ForegroundColor Yellow
    Write-Host "  3) When 'npm run build' passes again, resume with:" -ForegroundColor Yellow
    Write-Host "       .\run.ps1 -StartStep $i" -ForegroundColor Yellow
    break
  }

  # Git checkpoint: commit generated code so each step is a rollback point
  git add -A
  $null = git commit -m "Step ${i}: $($stepNames[$i])" --quiet 2>&1

  Write-Host ""
  Write-Host "  STEP $i OK — build (and unit tests) passed." -ForegroundColor Green

  if ($i -eq $stopAt) {
    Write-Host ""
    if ($stopAt -eq $prompts.Count - 1) {
      Write-Host "DONE. All steps completed and verified." -ForegroundColor Green
      Write-Host "Start the blog with:  npm run dev   (then open http://localhost:4321)" -ForegroundColor Green
      Write-Host "Full E2E tests (optional):  npm run test:e2e" -ForegroundColor Green
    } else {
      Write-Host "DONE. Steps $StartStep-$stopAt completed and verified." -ForegroundColor Green
      Write-Host "Resume with:  .\run.ps1 -StartStep $($stopAt + 1)" -ForegroundColor Cyan
    }
    break
  }

  if ($Pause) {
    Read-Host "Press ENTER to proceed to the next step (CTRL+C to stop)"
  }
}
