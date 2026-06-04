<#
  setup.ps1 - Configures the blog before running the pipeline.
  Run this once, then run .\run.ps1 to generate the blog.

  USAGE:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    .\setup.ps1
#>

$ErrorActionPreference = "Continue" # Changed from Stop to prevent external commands from terminating the script

function Write-Header($text) {
  Write-Host ""
  Write-Host "=================================================" -ForegroundColor White
  Write-Host "  $text" -ForegroundColor White
  Write-Host "=================================================" -ForegroundColor White
  Write-Host ""
}

function Write-Section($text) {
  Write-Host ""
  Write-Host "=== $text ===" -ForegroundColor Cyan
  Write-Host ""
}

Write-Header "Blog Builder - Setup"

# --- Prerequisites ---
if (-not (Test-Path "CLAUDE.md")) {
  Write-Host "Error: CLAUDE.md not found. Run this script from the blog-builder folder." -ForegroundColor Red
  exit 1
}

# --- 1. Site info ---
Write-Section "1/6 - Site info"
$blogTitle = Read-Host "Blog title"
$blogDesc  = Read-Host "Description (one sentence)"
Write-Host ""
Write-Host "  URL tip: if you're deploying to Vercel and haven't deployed yet, Vercel" -ForegroundColor DarkGray
Write-Host "  will assign an ugly auto-generated link (e.g. blog-6jcd.vercel.app)." -ForegroundColor DarkGray
Write-Host "  You can rename it for free in Settings -> Domains after the first deploy." -ForegroundColor DarkGray
Write-Host "  -> Enter a placeholder now (e.g. https://my-blog.vercel.app) and update" -ForegroundColor DarkGray
Write-Host "     src/config.ts after you know your real URL. See README.md section 5." -ForegroundColor DarkGray
Write-Host ""
$blogUrl   = Read-Host "URL (e.g. https://yourdomain.vercel.app)"
$blogAuthor = Read-Host "Author name"

# --- 2. Color palette ---
Write-Section "2/6 - Color palette"
Write-Host "  1  Blue / Neutral  - clean, professional           (default)"
Write-Host "  2  Forest          - warm greens, earthy tones"
Write-Host "  3  Sunset          - warm oranges, amber"
Write-Host "  4  Ink             - deep purples, editorial"
Write-Host "  5  Mono            - pure black and white, minimal"
Write-Host "  6  Custom          - enter your own hex values"
Write-Host ""
$c = Read-Host "Choice [1-6, default 1]"
if (-not $c) { $c = "1" }

switch ($c) {
  "2" {
    $lBg="#FAFAF8"; $lTx="#1C2B1A"; $lMu="#6B7B6A"; $lAc="#2D6A4F"; $lBo="#D8E8D4"; $lSu="#F0F5EE"
    $dBg="#161E15"; $dTx="#E8F0E6"; $dMu="#8FA98D"; $dAc="#52B788"; $dBo="#2D3F2B"; $dSu="#1E2B1C"
  }
  "3" {
    $lBg="#FFFBF7"; $lTx="#1C1410"; $lMu="#7B6B60"; $lAc="#C2580A"; $lBo="#EDD9C8"; $lSu="#FAF1E8"
    $dBg="#1A1108"; $dTx="#F5EDE4"; $dMu="#A89080"; $dAc="#E8844A"; $dBo="#3D2A1A"; $dSu="#261A0E"
  }
  "4" {
    $lBg="#FDFCFF"; $lTx="#1A1625"; $lMu="#72687E"; $lAc="#6D28D9"; $lBo="#E4DFF0"; $lSu="#F5F2FC"
    $dBg="#120E1C"; $dTx="#EDE9F5"; $dMu="#9A90A8"; $dAc="#A78BFA"; $dBo="#2D2640"; $dSu="#1C1730"
  }
  "5" {
    $lBg="#FFFFFF"; $lTx="#0A0A0A"; $lMu="#737373"; $lAc="#0A0A0A"; $lBo="#E5E5E5"; $lSu="#FAFAFA"
    $dBg="#0A0A0A"; $dTx="#FAFAFA"; $dMu="#A3A3A3"; $dAc="#FAFAFA"; $dBo="#262626"; $dSu="#171717"
  }
  "6" {
    Write-Host ""
    Write-Host "Light mode:" -ForegroundColor Cyan
    $lBg = Read-Host "  Background"
    $lTx = Read-Host "  Text"
    $lMu = Read-Host "  Muted (secondary text)"
    $lAc = Read-Host "  Accent (links/buttons)"
    $lBo = Read-Host "  Border"
    $lSu = Read-Host "  Surface (card bg)"
    Write-Host ""
    Write-Host "Dark mode:" -ForegroundColor Cyan
    $dBg = Read-Host "  Background"
    $dTx = Read-Host "  Text"
    $dMu = Read-Host "  Muted"
    $dAc = Read-Host "  Accent"
    $dBo = Read-Host "  Border"
    $dSu = Read-Host "  Surface"
  }
  default {
    $lBg="#FFFFFF"; $lTx="#111827"; $lMu="#6B7280"; $lAc="#2563EB"; $lBo="#E5E7EB"; $lSu="#F9FAFB"
    $dBg="#111827"; $dTx="#F3F4F6"; $dMu="#9CA3AF"; $dAc="#3B82F6"; $dBo="#374151"; $dSu="#1F2937"
  }
}

# --- 3. Typography ---
Write-Section "3/6 - Typography"
Write-Host "  1  Lora + DM Sans                  - classic serif + clean sans  (default)"
Write-Host "  2  Playfair Display + Source Sans 3 - editorial, elegant"
Write-Host "  3  DM Serif Display + DM Sans      - modern, cohesive"
Write-Host "  4  Fraunces + Inter                - quirky serif + tech sans"
Write-Host "  5  Inter + Inter                   - pure sans-serif, minimal"
Write-Host "  6  Custom                          - enter your own fontsource.org font names"
Write-Host ""
$f = Read-Host "Choice [1-6, default 1]"
if (-not $f) { $f = "1" }

switch ($f) {
  "2" { $headingFont = "Playfair Display"; $headingType = "serif";     $bodyFont = "Source Sans 3" }
  "3" { $headingFont = "DM Serif Display"; $headingType = "serif";     $bodyFont = "DM Sans" }
  "4" { $headingFont = "Fraunces";         $headingType = "serif";     $bodyFont = "Inter" }
  "5" { $headingFont = "Inter";            $headingType = "sans-serif"; $bodyFont = "Inter" }
  "6" {
    $headingFont = Read-Host "Heading font (exact name as on fontsource.org, e.g. Playfair Display)"
    $headingType = Read-Host "  serif or sans-serif"
    $bodyFont    = Read-Host "Body/UI font (exact name as on fontsource.org, e.g. Source Sans 3)"
  }
  default { $headingFont = "Lora"; $headingType = "serif"; $bodyFont = "DM Sans" }
}

# --- 4. Analytics ---
Write-Section "4/6 - Analytics (optional)"
Write-Host "  0  None                         - no analytics, skip this step   (default)"
Write-Host "  1  Umami Cloud                  - privacy-first, 100k events/month free   (recommended)"
Write-Host "  2  Cloudflare Web Analytics     - unlimited free, requires DNS nameserver change"
Write-Host "  3  Vercel Analytics             - 2,500 events/month free, minimal setup"
Write-Host ""
$a = Read-Host "Choice [0-3, default 0]"
if (-not $a) { $a = "0" }

switch ($a) {
  "1" { $analyticsProvider = "umami" }
  "2" { $analyticsProvider = "cloudflare" }
  "3" { $analyticsProvider = "vercel" }
  default { $analyticsProvider = "none" }
}

# --- 5. Comments ---
Write-Section "5/6 - Comments (optional)"
Write-Host "  0  None         - no comments section   (default)"
Write-Host "  1  Giscus       - GitHub Discussions, privacy-first, free   (recommended)"
Write-Host "  2  Utterances   - GitHub Issues, simpler, free"
Write-Host ""
$cm = Read-Host "Choice [0-2, default 0]"
if (-not $cm) { $cm = "0" }

switch ($cm) {
  "1" { $commentsProvider = "giscus" }
  "2" { $commentsProvider = "utterances" }
  default { $commentsProvider = "none" }
}

# --- 6. Newsletter ---
Write-Section "6/6 - Newsletter (optional)"
Write-Host "  0  None          - no newsletter form   (default)"
Write-Host "  1  Buttondown    - privacy-first, 100 subscribers free   (recommended)"
Write-Host "  2  Substack      - popular, free for free newsletters"
Write-Host "  3  Kit           - formerly ConvertKit, 10k subscribers free"
Write-Host ""
$nl = Read-Host "Choice [0-3, default 0]"
if (-not $nl) { $nl = "0" }

switch ($nl) {
  "1" { $newsletterProvider = "buttondown" }
  "2" { $newsletterProvider = "substack" }
  "3" { $newsletterProvider = "kit" }
  default { $newsletterProvider = "none" }
}

# --- 7. Update CLAUDE.md ---
Write-Host ""
Write-Host "Updating CLAUDE.md..." -ForegroundColor Cyan

$content = (Get-Content 'CLAUDE.md' -Raw -Encoding UTF8) -replace "`r`n", "`n"
$fence = '```'

# 1. Insert or update site values before "Import SITE" paragraph
$siteMarker = 'Import SITE wherever site-level data is needed.'
$siteBlock  = "Site values (use these when creating src/config.ts):`n" +
              "- title: `"$blogTitle`"`n" +
              "- description: `"$blogDesc`"`n" +
              "- url: `"$blogUrl`"`n" +
              "- author: `"$blogAuthor`"`n`n"
$sitePattern = "(?s)Site values \(use these when creating src/config\.ts\):`n.*?author: `".*?`"`n`n"
if ($content -match $sitePattern) {
  $content = $content -replace $sitePattern, $siteBlock
} elseif ($content.Contains($siteMarker)) {
  $content = $content.Replace($siteMarker, $siteBlock + $siteMarker)
}

# 2. Replace color palette (using regex to match any existing CSS block)
$newColor = ("${fence}css`n" +
             "/* Light mode (:root) */`n" +
             "--color-bg: $lBg`n" +
             "--color-text: $lTx`n" +
             "--color-muted: $lMu`n" +
             "--color-accent: $lAc`n" +
             "--color-border: $lBo`n" +
             "--color-surface: $lSu`n" +
             "`n" +
             "/* Dark mode ([data-theme=`"dark`"] on <html>) */`n" +
             "--color-bg: $dBg`n" +
             "--color-text: $dTx`n" +
             "--color-muted: $dMu`n" +
             "--color-accent: $dAc`n" +
             "--color-border: $dBo`n" +
             "--color-surface: $dSu`n" +
             "${fence}")

$colorPattern = "(?s)${fence}css`n/\* Light mode \(:root\) \*/.*?${fence}"
if ($content -match $colorPattern) {
  $content = $content -replace $colorPattern, $newColor
} else {
  Write-Host "  Note: color block not found - already configured?" -ForegroundColor Yellow
}

# 3. Replace typography lines (regex - matches any current font value)
$content = $content -replace '- Headings \(h1.h3\): .+', "- Headings (h1`u{2013}h3): $headingFont, $headingType"
$content = $content -replace '- Body \+ UI: .+, sans-serif', "- Body + UI: $bodyFont, sans-serif"

# 4. Update font line in STACK section (regex - matches any current value)
$content = $content -replace '- Fonts: .+\(headings\) \+ .+\(body/UI\).*', "- Fonts: $headingFont (headings) + $bodyFont (body/UI) - self-hosted via @fontsource"

# 5. Replace each provider value (section-aware, so ANALYTICS/COMMENTS/NEWSLETTER stay independent)
$providers = @(
  @{ section = "## ANALYTICS";  value = $analyticsProvider  },
  @{ section = "## COMMENTS";   value = $commentsProvider   },
  @{ section = "## NEWSLETTER"; value = $newsletterProvider }
)
foreach ($p in $providers) {
  $escaped = [regex]::Escape($p.section)
  $content = $content -replace "(?ms)($escaped\r?\n\r?\n)Provider:\s*\S+", "`${1}Provider: $($p.value)"
}

# Write back (UTF-8 without BOM, LF line endings)
[System.IO.File]::WriteAllText(
  (Resolve-Path 'CLAUDE.md').Path,
  $content,
  [System.Text.UTF8Encoding]::new($false)
)
Write-Host "CLAUDE.md configured." -ForegroundColor Green

# --- 5. GitHub (optional) ---
Write-Section "GitHub (optional)"
Write-Host "Create a GitHub repository for your blog?"
Write-Host "  Requires: GitHub CLI (gh) - https://cli.github.com" -ForegroundColor White
Write-Host ""
$ghAns = Read-Host "Set up GitHub? [y/N]"

$githubRemote = ""
if ($ghAns -match '^[Yy]$') {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "Warning: GitHub CLI (gh) not found." -ForegroundColor Yellow
    Write-Host "Install it from https://cli.github.com then rerun: .\setup.ps1" -ForegroundColor Yellow
  } else {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Host "Logging in to GitHub..."
      gh auth login
    }

    Write-Host ""
    $repoName = Read-Host "Repository name (e.g. my-blog)"
    Write-Host ""
    Write-Host "  1  Public"
    Write-Host "  2  Private"
    $vis = Read-Host "Visibility [1-2, default 1]"
    $visFlag = if ($vis -eq "2") { "--private" } else { "--public" }

    # Ensure git repo exists
    if (-not (Test-Path ".git")) {
      git init | Out-Null
      git add -A
      git commit -m "Initial setup: blog configuration" --quiet
    }

    # Remove blog-builder origin (if any), create new repo
    git remote remove origin 2>&1 | Out-Null

    Write-Host ""
    gh repo create $repoName $visFlag --description "$blogDesc"
    $githubUser = gh api user --jq .login
    $githubRemote = "https://github.com/$githubUser/$repoName.git"
    git remote add origin $githubRemote
    Write-Host "Repository created: https://github.com/$githubUser/$repoName" -ForegroundColor Green
  }
}

# --- Done ---
Write-Host ""
Write-Host "=================================================" -ForegroundColor White
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host ""
$optionalSteps = @()
if ($analyticsProvider -ne "none") { $optionalSteps += "analytics" }
if ($commentsProvider  -ne "none") { $optionalSteps += "comments" }
if ($newsletterProvider -ne "none") { $optionalSteps += "newsletter" }
$baseSteps = 10
$totalSteps = $baseSteps + $optionalSteps.Count
$lastStep   = $totalSteps - 1
$stepNote = if ($optionalSteps.Count -gt 0) {
  "runs all $totalSteps steps, 0-$lastStep - $($optionalSteps -join ', ') included"
} else {
  "runs all $baseSteps steps, 0-$($baseSteps-1)"
}
Write-Host "  1. Generate the blog:"
Write-Host "       .\run.ps1        ($stepNote)" -ForegroundColor White
Write-Host "       .\run.ps1 -Pause (pauses after each step)" -ForegroundColor White
Write-Host ""
if ($githubRemote) {
  Write-Host "  2. After the pipeline finishes, push to GitHub:"
  Write-Host "       git push -u origin HEAD" -ForegroundColor White
  Write-Host ""
}
Write-Host "  Once generated, open README.md for usage instructions."
Write-Host "  Quick preview:  npm run dev  (then open http://localhost:4321)"
Write-Host "  If pages are blank after Step 7 (Keystatic), use:  npm run dev:build"
Write-Host ""
