<#
  run.ps1 — Esegue i prompt del blog in sequenza con Claude Code (modalita headless),
  uno step alla volta, ognuno in una SESSIONE NUOVA (cosi la context window non si riempie),
  e dopo ogni step verifica in modo INDIPENDENTE che la build (e i test unit) passino.
  Se qualcosa si rompe, SI FERMA: non costruisce mai sopra uno stato rotto.

  USO:
    .\run.ps1                 # esegue tutti gli step, fermandosi al primo errore
    .\run.ps1 -Pause          # in piu, fa una pausa dopo ogni step per farti controllare
    .\run.ps1 -StartStep 3    # riprende dallo step 3 (dopo che hai sistemato un errore)
#>

param(
  [int]$StartStep = 0,
  [switch]$Pause
)

$ErrorActionPreference = "Continue" # Changed from Stop to prevent 2>&1 from crashing on external stderr

# Ordine degli step. Lo step 0 (foundation) crea il progetto; gli altri lo estendono.
$prompts = @(
  "prompt_blog_00_foundation.txt",  # 0  Foundation
  "prompt_blog_01_testing.txt",     # 1  Testing (Vitest + Playwright)
  "prompt_blog_02_seo.txt",         # 2  Feature 01 - SEO
  "prompt_blog_03_reading_ux.txt",  # 3  Feature 02 - Reading UX
  "prompt_blog_04_search.txt",      # 4  Feature 03 - Search (Pagefind)
  "prompt_blog_05_series.txt",      # 5  Feature 04 - Series
  "prompt_blog_06_related.txt"      # 6  Feature 05 - Related
)

$stepNames = @(
  "Foundation",
  "Testing setup",
  "SEO",
  "Reading UX",
  "Search",
  "Series",
  "Related articles"
)

# --- Controlli preliminari -------------------------------------------------
function Assert-Command($name, $hint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Host "ERRORE: '$name' non trovato. $hint" -ForegroundColor Red
    exit 1
  }
}
Assert-Command "claude" "Installa Claude Code (vedi SETUP.md) e riapri il terminale."
Assert-Command "node"   "Installa Node.js LTS da https://nodejs.org"
Assert-Command "npm"    "Installa Node.js LTS da https://nodejs.org"

if (-not (Test-Path "CLAUDE.md")) {
  Write-Host "ERRORE: CLAUDE.md non e in questa cartella. Esegui lo script dalla cartella che lo contiene." -ForegroundColor Red
  exit 1
}

New-Item -ItemType Directory -Force -Path "logs" | Out-Null

# --- Cancello di verifica (il meccanismo anti-deriva) ----------------------
function Test-Project {
  if (-not (Test-Path "package.json")) {
    Write-Host "  (package.json non ancora presente — salto la verifica)" -ForegroundColor DarkGray
    return $true
  }

  Write-Host "  -> npm install" -ForegroundColor Cyan
  npm install --no-audit --no-fund 2>&1 | Out-Host
  if ($LASTEXITCODE -ne 0) { return $false }

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

# --- Loop principale -------------------------------------------------------
$instruction = @"
Sei in una cartella di progetto che contiene CLAUDE.md: leggilo PRIMA di tutto e rispetta ogni sua regola.
Sul tuo standard input ricevi le istruzioni del task corrente: eseguile ESATTAMENTE, senza aggiungere
funzionalita non richieste. Quando hai finito, esegui 'npm run build' (e 'npm run test:unit' se lo script
esiste) e correggi gli eventuali errori finche non passano. Non procedere oltre il task ricevuto.
"@

for ($i = $StartStep; $i -lt $prompts.Count; $i++) {
  $file = $prompts[$i]
  Write-Host ""
  Write-Host "===================================================" -ForegroundColor White
  Write-Host " STEP $i  ->  $file" -ForegroundColor White
  Write-Host "===================================================" -ForegroundColor White

  if (-not (Test-Path $file)) {
    Write-Host "ERRORE: file prompt mancante: $file" -ForegroundColor Red
    break
  }

  # Sessione NUOVA e separata: il contesto e solo CLAUDE.md + i file gia su disco.
  # Il prompt vero passa via stdin (niente problemi di quoting con testi lunghi).
  Get-Content $file -Raw | claude -p $instruction `
    --permission-mode acceptEdits `
    --allowedTools "Bash,Read,Edit,Write,Glob,Grep" `
    --output-format json 2>&1 | Tee-Object -FilePath "logs\step_$i.json"
  $claudeExit = $LASTEXITCODE

  if ($claudeExit -ne 0) {
    Write-Host ""
    Write-Host "Claude ha terminato con errore allo step $i. Mi fermo." -ForegroundColor Red
    Write-Host "Guarda logs\step_$i.json, sistema, poi riprendi con:  .\run.ps1 -StartStep $i" -ForegroundColor Yellow
    break
  }

  Write-Host ""
  Write-Host "  Verifica indipendente dello step $i..." -ForegroundColor Cyan
  if (-not (Test-Project)) {
    Write-Host ""
    Write-Host "BUILD/TEST FALLITI allo step $i ($file)." -ForegroundColor Red
    Write-Host "Mi fermo qui apposta, per non costruire sopra uno stato rotto." -ForegroundColor Red
    Write-Host ""
    Write-Host "COSA FARE ORA:" -ForegroundColor Yellow
    Write-Host "  1) Apri questa cartella in VS Code." -ForegroundColor Yellow
    Write-Host "  2) Lancia 'claude' (interattivo) e descrivi/incolla l'errore di build." -ForegroundColor Yellow
    Write-Host "  3) Quando 'npm run build' passa di nuovo, riprendi con:" -ForegroundColor Yellow
    Write-Host "       .\run.ps1 -StartStep $i" -ForegroundColor Yellow
    break
  }

  # Git checkpoint: commit generated code so each step is a rollback point
  git add -A
  git commit -m "Step ${i}: $($stepNames[$i])" --quiet
  $LASTEXITCODE = 0 # Ignore commit failures (e.g., if nothing changed)

  Write-Host ""
  Write-Host "  STEP $i OK — build (e test unit) passati." -ForegroundColor Green

  if ($i -eq $prompts.Count - 1) {
    Write-Host ""
    Write-Host "FATTO. Tutti gli step completati e verificati." -ForegroundColor Green
    Write-Host "Avvia il blog con:  npm run dev   (poi apri http://localhost:4321)" -ForegroundColor Green
    Write-Host "Test E2E completi (facoltativo):  npm run test:e2e" -ForegroundColor Green
    break
  }

  if ($Pause) {
    Read-Host "Premi INVIO per passare allo step successivo (CTRL+C per fermarti)"
  }
}
