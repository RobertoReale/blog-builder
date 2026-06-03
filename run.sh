#!/bin/bash
#
# run.sh — Executes the blog prompts in sequence with Claude Code (headless mode),
# one step at a time, each in a NEW SESSION (so the context window never fills up),
# and after each step INDEPENDENTLY verifies that the build (and unit tests) pass.
# If something breaks, it STOPS: it never builds on top of a broken state.
#
# USAGE:
#   ./run.sh                 # executes all steps, stopping at the first error
#   ./run.sh -p              # additionally pauses after each step for you to check
#   ./run.sh -s 3            # resumes from step 3 (after you fixed an error)

set -e # Exit on any unhandled error

START_STEP=0
PAUSE=false

while getopts ":ps:" opt; do
  case $opt in
    s) START_STEP="$OPTARG"
    ;;
    p) PAUSE=true
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1
    ;;
  esac
done

PROMPTS=(
  "prompt_blog_00_foundation.txt"
  "prompt_blog_01_testing.txt"
  "prompt_blog_02_seo.txt"
  "prompt_blog_03_reading_ux.txt"
  "prompt_blog_04_search.txt"
  "prompt_blog_05_series.txt"
  "prompt_blog_06_related.txt"
  "prompt_blog_07_keystatic.txt"
)

STEP_NAMES=(
  "Foundation"
  "Testing setup"
  "SEO"
  "Reading UX"
  "Search"
  "Series"
  "Related articles"
  "Keystatic CMS"
)

# --- Preliminary checks ---
assert_command() {
  if ! command -v "$1" &> /dev/null; then
    echo -e "\033[0;31mERROR: '$1' not found. $2\033[0m"
    exit 1
  fi
}

assert_command "claude" "Install Claude Code (see SETUP.md) and reopen the terminal."
assert_command "node" "Install Node.js LTS from https://nodejs.org"
assert_command "npm" "Install Node.js LTS from https://nodejs.org"

if [ ! -f "CLAUDE.md" ]; then
  echo -e "\033[0;31mERROR: CLAUDE.md is not in this folder. Run the script from the folder containing it.\033[0m"
  exit 1
fi

mkdir -p logs

# --- Verification gate (anti-drift mechanism) ---
test_project() {
  if [ ! -f "package.json" ]; then
    echo -e "\033[1;30m  (package.json not present yet — skipping verification)\033[0m"
    return 0
  fi

  echo -e "\033[0;36m  -> npm install\033[0m"
  if ! npm install --no-audit --no-fund; then return 1; fi

  echo -e "\033[0;36m  -> npm run build\033[0m"
  if ! npm run build; then return 1; fi

  if grep -q '"test:unit":' package.json; then
    echo -e "\033[0;36m  -> npm run test:unit\033[0m"
    if ! npm run test:unit; then return 1; fi
  fi

  return 0
}

# --- Main loop ---
INSTRUCTION="Sei in una cartella di progetto che contiene CLAUDE.md: leggilo PRIMA di tutto e rispetta ogni sua regola. Sul tuo standard input ricevi le istruzioni del task corrente: eseguile ESATTAMENTE, senza aggiungere funzionalita non richieste. Quando hai finito, esegui 'npm run build' (e 'npm run test:unit' se lo script esiste) e correggi gli eventuali errori finche non passano. Non procedere oltre il task ricevuto."

for (( i=START_STEP; i<${#PROMPTS[@]}; i++ )); do
  FILE="${PROMPTS[$i]}"
  echo ""
  echo -e "\033[1;37m===================================================\033[0m"
  echo -e "\033[1;37m STEP $i  ->  $FILE\033[0m"
  echo -e "\033[1;37m===================================================\033[0m"

  if [ ! -f "$FILE" ]; then
    echo -e "\033[0;31mERROR: prompt file missing: $FILE\033[0m"
    break
  fi

  # New separate session: context is only CLAUDE.md + files on disk.
  set +e
  claude -p "$INSTRUCTION" \
    --permission-mode acceptEdits \
    --allowedTools "Bash,Read,Edit,Write,Glob,Grep" \
    --output-format json < "$FILE" 2>&1 | tee "logs/step_$i.json"
  CLAUDE_EXIT=${PIPESTATUS[0]}
  set -e

  if [ $CLAUDE_EXIT -ne 0 ]; then
    echo ""
    echo -e "\033[0;31mClaude terminated with an error at step $i. Stopping.\033[0m"
    echo -e "\033[1;33mCheck logs/step_$i.json, fix the issue, then resume with:  ./run.sh -s $i\033[0m"
    break
  fi

  echo ""
  echo -e "\033[0;36m  Independent verification of step $i...\033[0m"
  set +e
  test_project
  TEST_EXIT=$?
  set -e

  if [ $TEST_EXIT -ne 0 ]; then
    echo ""
    echo -e "\033[0;31mBUILD/TEST FAILED at step $i ($FILE).\033[0m"
    echo -e "\033[0;31mStopping here intentionally, to prevent building on a broken state.\033[0m"
    echo ""
    echo -e "\033[1;33mWHAT TO DO NOW:\033[0m"
    echo -e "\033[1;33m  1) Open this folder in VS Code.\033[0m"
    echo -e "\033[1;33m  2) Run 'claude' (interactive) and describe/paste the build error.\033[0m"
    echo -e "\033[1;33m  3) When 'npm run build' passes again, resume with:\033[0m"
    echo -e "\033[1;33m       ./run.sh -s $i\033[0m"
    break
  fi

  # Git checkpoint: commit generated code so each step is a rollback point
  git add -A 2>/dev/null
  git commit -m "Step $i: ${STEP_NAMES[$i]}" --quiet 2>/dev/null || true

  echo ""
  echo -e "\033[0;32m  STEP $i OK — build (and unit tests) passed.\033[0m"

  if [ $i -eq $((${#PROMPTS[@]} - 1)) ]; then
    echo ""
    echo -e "\033[0;32mDONE. All steps completed and verified.\033[0m"
    echo -e "\033[0;32mStart the blog with:  npm run dev   (then open http://localhost:4321)\033[0m"
    echo -e "\033[0;32mFull E2E tests (optional):  npm run test:e2e\033[0m"
    break
  fi

  if [ "$PAUSE" = true ]; then
    read -p "Press ENTER to proceed to the next step (CTRL+C to stop)"
  fi
done
