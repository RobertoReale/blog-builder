<#
  run.ps1 - Runs the blog prompts in sequence via Claude Code (headless mode),
  one step at a time, each in a NEW SESSION (so the context window never fills up),
  and after each step independently verifies that the build (and unit tests) pass.
  If something breaks, it STOPS: it never builds on top of a broken state.

  USAGE:
    .\run.ps1                              # runs all steps, stopping at the first error
    .\run.ps1 -Pause                       # also pauses after each step to inspect output
    .\run.ps1 -StartStep 3                 # resumes from step 3 (after you fixed an error)
    .\run.ps1 -StartStep 3 -EndStep 5      # runs only steps 3, 4, and 5
    .\run.ps1 -DryRun                      # preview which steps would run, without executing
#>

param(
  [int]$StartStep = 0,
  [int]$EndStep = -1,
  [switch]$Pause,
  [switch]$DryRun
)

$ErrorActionPreference = "Continue"

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
  "prompt_blog_08_e2e_check.txt",   # 8  E2E integration check
  "prompt_blog_09_ui_review.txt",   # 9  UI, UX & design quality review
  "prompt_blog_10_security_audit.txt" # 10 Security & vulnerability audit
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
  "E2E integration check",
  "UI & design review",
  "Security & vulnerability audit"
)

# Conditionally append optional steps based on CLAUDE.md configuration
$claudeMd = if (Test-Path "CLAUDE.md") { Get-Content "CLAUDE.md" -Raw } else { "" }

# Analytics (step 11)
if ($claudeMd -match '(?m)## ANALYTICS\s*\n\s*\nProvider:\s+(umami|cloudflare|vercel)\b') {
  $prompts   += "prompt_blog_11_analytics.txt"
  $stepNames += "Analytics"
}
# Comments (step 12)
if ($claudeMd -match '(?m)## COMMENTS\s*\n\s*\nProvider:\s+(giscus|utterances)\b') {
  $prompts   += "prompt_blog_12_comments.txt"
  $stepNames += "Comments"
}
# Newsletter (step 13)
if ($claudeMd -match '(?m)## NEWSLETTER\s*\n\s*\nProvider:\s+(buttondown|substack|kit)\b') {
  $prompts   += "prompt_blog_13_newsletter.txt"
  $stepNames += "Newsletter"
}

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

if (-not (Test-Path "CHOSEN_TOOLS.md") -and $StartStep -eq 0) {
  Write-Host ""
  Write-Host "  Tip: CHOSEN_TOOLS.md not found - ecosystem discovery has not been run." -ForegroundColor DarkGray
  Write-Host "  Open Claude Code and send prompt_blog_pre_discovery.txt to enable optional" -ForegroundColor DarkGray
  Write-Host "  integrations (syntax highlighting, PWA, OG images, etc.)." -ForegroundColor DarkGray
  Write-Host "  Continuing without it is fine - all core features still work." -ForegroundColor DarkGray
}

New-Item -ItemType Directory -Force -Path "logs" | Out-Null

# --- Verification gate (anti-drift mechanism) ------------------------------
function Test-Project([bool]$InstallNeeded = $true) {
  if (-not (Test-Path "package.json")) {
    Write-Host "  (package.json not present yet - skipping verification)" -ForegroundColor DarkGray
    return $true
  }

  if ($InstallNeeded) {
    Write-Host "  -> npm install" -ForegroundColor Cyan
    npm install --no-audit --no-fund 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) { return $false }
  } else {
    Write-Host "  -> npm install (skipped - package.json unchanged)" -ForegroundColor DarkGray
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

# --- Token usage parser (reads the stream-json log written by this run) ----
function Get-StepUsage($logFile) {
  try {
    $resultLine = Get-Content $logFile -ErrorAction Stop |
      Where-Object { $_ -match '"type"\s*:\s*"result"' } |
      Select-Object -Last 1
    if ($resultLine) {
      $r = $resultLine | ConvertFrom-Json
      if ($r.usage) {
        return @{
          Input  = [int]($r.usage.input_tokens  -as [int])
          Output = [int]($r.usage.output_tokens -as [int])
        }
      }
    }
  } catch {}
  return $null
}

# --- Git init (if needed) -------------------------------------------------
if (-not (Test-Path ".git")) {
  git init | Out-Null
  git add -A | Out-Null
  $null = git commit -m "Initial commit (pre-pipeline)" --quiet 2>&1
}

# --- Compute range ---------------------------------------------------------
$instruction = @"
You are working in a project folder that contains CLAUDE.md: read it FIRST and follow every rule in it.
Your standard input contains the instructions for the current task: execute them EXACTLY, without adding
unrequested features. When done, run 'npm run build' (and 'npm run test:unit' if that script exists) and
fix any errors until they pass. Do not go beyond the task you received.
"@

$stopAt = if ($EndStep -ge 0 -and $EndStep -lt $prompts.Count) { $EndStep } else { $prompts.Count - 1 }

# --- Dry run ---------------------------------------------------------------
if ($DryRun) {
  Write-Host ""
  Write-Host "DRY RUN - steps that would be executed:" -ForegroundColor Cyan
  Write-Host ""
  for ($j = $StartStep; $j -le $stopAt; $j++) {
    Write-Host ("  Step {0,-2}  {1,-20}  ({2})" -f $j, $stepNames[$j], $prompts[$j]) -ForegroundColor White
  }
  Write-Host ""
  Write-Host ("  Total: {0} step(s)" -f ($stopAt - $StartStep + 1)) -ForegroundColor Cyan
  Write-Host ""
  exit 0
}

# --- Startup banner --------------------------------------------------------
$stepCount = $stopAt - $StartStep + 1
Write-Host ""
Write-Host "Blog Builder Pipeline - steps $StartStep-$stopAt  ($stepCount step$(if ($stepCount -ne 1) {'s'}))" -ForegroundColor White
Write-Host "To pause: CTRL+C   |   To resume: .\run.ps1 -StartStep N" -ForegroundColor Yellow
Write-Host ""

$totalInput  = 0
$totalOutput = 0

# --- Main loop -------------------------------------------------------------
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
  Write-Host "  STEP $i OK - build (and unit tests) passed." -ForegroundColor Green

  # Token usage counter
  $usage = Get-StepUsage "logs\step_$i.json"
  if ($usage) {
    $totalInput  += $usage.Input
    $totalOutput += $usage.Output
    $si = "{0:N0}" -f $usage.Input
    $so = "{0:N0}" -f $usage.Output
    $ti = "{0:N0}" -f $totalInput
    $to = "{0:N0}" -f $totalOutput
    Write-Host "  Tokens this step: $si in / $so out   |   Total so far: $ti in / $to out" -ForegroundColor DarkGray
  }

  if ($i -eq $stopAt) {
    Write-Host ""
    if ($stopAt -eq $prompts.Count - 1) {
      Write-Host "DONE. All steps completed and verified." -ForegroundColor Green
      # Detect whether Keystatic (step 7) was part of this run
      $keystatic = (Test-Path "keystatic.config.ts")
      if ($keystatic) {
        Write-Host ""
        Write-Host "Local preview options:" -ForegroundColor White
        Write-Host "  Option A (recommended): npm run dev" -ForegroundColor White
        Write-Host "    If pages are blank or show 500, try Option B." -ForegroundColor DarkGray
        Write-Host "  Option B (always works): npm run dev:build" -ForegroundColor White
        Write-Host "    Builds the full site and serves it at http://localhost:4321" -ForegroundColor DarkGray
        Write-Host "    (search works here too)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Full E2E tests (optional):  npm run test:e2e" -ForegroundColor White
        Write-Host ""
        Write-Host "Before going live - open README.md for:" -ForegroundColor Cyan
        Write-Host "  - How to write and publish articles" -ForegroundColor White
        Write-Host "  - How to set up the Keystatic CMS on Vercel" -ForegroundColor White
        Write-Host "  - How to customize colors, fonts, and content" -ForegroundColor White
      } else {
        Write-Host "Start the blog with:  npm run dev   (then open http://localhost:4321)" -ForegroundColor Green
        Write-Host "Full E2E tests (optional):  npm run test:e2e" -ForegroundColor Green
        Write-Host ""
        Write-Host "Before going live - open README.md for:" -ForegroundColor Cyan
        Write-Host "  - How to write and publish articles" -ForegroundColor White
        Write-Host "  - How to customize and deploy the blog" -ForegroundColor White
      }
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
