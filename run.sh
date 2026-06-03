#!/bin/bash
#
# run.sh — Runs the blog prompts in sequence via Claude Code (headless mode),
# one step at a time, each in a NEW SESSION (so the context window never fills up),
# and after each step independently verifies that the build (and unit tests) pass.
# If something breaks, it STOPS: it never builds on top of a broken state.
#
# USAGE:
#   ./run.sh                        # runs all steps, stopping at the first error
#   ./run.sh -p                     # also pauses after each step to inspect output
#   ./run.sh -s 3                   # resumes from step 3 (after you fixed an error)
#   ./run.sh -s 3 -e 5              # runs only steps 3, 4, and 5
#   ./run.sh -d                     # preview which steps would run, without executing

set -e

START_STEP=0
END_STEP=-1
PAUSE=false
DRY_RUN=false

while getopts ":ps:e:d" opt; do
  case $opt in
    s) START_STEP="$OPTARG" ;;
    e) END_STEP="$OPTARG" ;;
    p) PAUSE=true ;;
    d) DRY_RUN=true ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
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
  "prompt_blog_08_e2e_check.txt"
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
  "E2E integration check"
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
  echo -e "\033[0;31mERROR: CLAUDE.md not found. Run this script from the folder that contains it.\033[0m"
  exit 1
fi

mkdir -p logs

# --- Verification gate (anti-drift mechanism) ---
test_project() {
  local install_needed="${1:-true}"

  if [ ! -f "package.json" ]; then
    echo -e "\033[1;30m  (package.json not present yet — skipping verification)\033[0m"
    return 0
  fi

  if [ "$install_needed" = "true" ]; then
    echo -e "\033[0;36m  -> npm install\033[0m"
    if ! npm install --no-audit --no-fund; then return 1; fi
  else
    echo -e "\033[1;30m  -> npm install (skipped — package.json unchanged)\033[0m"
  fi

  echo -e "\033[0;36m  -> npm run build\033[0m"
  if ! npm run build; then return 1; fi

  if grep -q '"test:unit":' package.json; then
    echo -e "\033[0;36m  -> npm run test:unit\033[0m"
    if ! npm run test:unit; then return 1; fi
  fi

  return 0
}

# --- Token usage parser (uses node, which is a required dependency) ---
get_step_usage() {
  local log_file="$1"
  [ -f "$log_file" ] || return
  node -e "
    const chunks = [];
    process.stdin.resume();
    process.stdin.on('data', d => chunks.push(d));
    process.stdin.on('end', () => {
      const lines = Buffer.concat(chunks).toString().split('\n');
      for (let i = lines.length - 1; i >= 0; i--) {
        try {
          const d = JSON.parse(lines[i]);
          if (d.type === 'result' && d.usage) {
            process.stdout.write((d.usage.input_tokens||0) + ' ' + (d.usage.output_tokens||0));
            break;
          }
        } catch(e) {}
      }
    });
  " < "$log_file" 2>/dev/null
}

fmt_num() {
  printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# --- Compute range ---
INSTRUCTION="You are working in a project folder that contains CLAUDE.md: read it FIRST and follow every rule in it. Your standard input contains the instructions for the current task: execute them EXACTLY, without adding unrequested features. When done, run 'npm run build' (and 'npm run test:unit' if that script exists) and fix any errors until they pass. Do not go beyond the task you received."

LAST_STEP=$(( ${#PROMPTS[@]} - 1 ))
if [ "$END_STEP" -ge 0 ] 2>/dev/null && [ "$END_STEP" -lt "${#PROMPTS[@]}" ]; then
  STOP_AT="$END_STEP"
else
  STOP_AT="$LAST_STEP"
fi

# --- Dry run ---------------------------------------------------------------
if [ "$DRY_RUN" = true ]; then
  echo ""
  echo -e "\033[0;36mDRY RUN — steps that would be executed:\033[0m"
  echo ""
  for (( j=START_STEP; j<=STOP_AT; j++ )); do
    printf "  Step %-2d  %-20s  (%s)\n" "$j" "${STEP_NAMES[$j]}" "${PROMPTS[$j]}"
  done
  echo ""
  echo -e "\033[0;36m  Total: $(( STOP_AT - START_STEP + 1 )) step(s)\033[0m"
  echo ""
  exit 0
fi

# --- Startup banner --------------------------------------------------------
STEP_COUNT=$(( STOP_AT - START_STEP + 1 ))
echo ""
echo -e "\033[1;37mBlog Builder Pipeline — steps $START_STEP-$STOP_AT  ($STEP_COUNT step(s))\033[0m"
echo -e "\033[1;33mTo pause: CTRL+C   |   To resume: ./run.sh -s N\033[0m"
echo ""

TOTAL_INPUT=0
TOTAL_OUTPUT=0

# --- Main loop -------------------------------------------------------------
for (( i=START_STEP; i<=STOP_AT; i++ )); do
  FILE="${PROMPTS[$i]}"
  echo ""
  echo -e "\033[1;37m===================================================\033[0m"
  echo -e "\033[1;37m STEP $i  ->  $FILE\033[0m"
  echo -e "\033[1;37m===================================================\033[0m"

  if [ ! -f "$FILE" ]; then
    echo -e "\033[0;31mERROR: prompt file missing: $FILE\033[0m"
    break
  fi

  # Capture package.json state before Claude runs to detect dependency changes
  PKG_BEFORE=""
  if [ -f "package.json" ]; then
    PKG_BEFORE=$(cat package.json)
  fi

  # New separate session: context is only CLAUDE.md + files on disk.
  set +e
  claude -p "$INSTRUCTION" \
    --permission-mode acceptEdits \
    --allowedTools "Bash,Read,Edit,Write,Glob,Grep,MultiEdit" \
    --output-format stream-json < "$FILE" 2>&1 | tee "logs/step_$i.json"
  CLAUDE_EXIT=${PIPESTATUS[0]}
  set -e

  if [ $CLAUDE_EXIT -ne 0 ]; then
    echo ""
    echo -e "\033[0;31mClaude terminated with an error at step $i. Stopping.\033[0m"
    echo -e "\033[1;33mCheck logs/step_$i.json, fix the issue, then resume with:  ./run.sh -s $i\033[0m"
    break
  fi

  # Skip npm install if package.json is unchanged and node_modules already exists
  PKG_AFTER=""
  if [ -f "package.json" ]; then
    PKG_AFTER=$(cat package.json)
  fi
  INSTALL_NEEDED="false"
  [ ! -d "node_modules" ] && INSTALL_NEEDED="true"
  [ "$PKG_BEFORE" != "$PKG_AFTER" ] && INSTALL_NEEDED="true"

  echo ""
  echo -e "\033[0;36m  Independent verification of step $i...\033[0m"
  set +e
  test_project "$INSTALL_NEEDED"
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

  # Token usage counter
  usage=$(get_step_usage "logs/step_$i.json")
  if [ -n "$usage" ]; then
    step_in=$(echo "$usage" | cut -d' ' -f1)
    step_out=$(echo "$usage" | cut -d' ' -f2)
    TOTAL_INPUT=$(( TOTAL_INPUT + step_in ))
    TOTAL_OUTPUT=$(( TOTAL_OUTPUT + step_out ))
    si=$(fmt_num $step_in)
    so=$(fmt_num $step_out)
    ti=$(fmt_num $TOTAL_INPUT)
    to=$(fmt_num $TOTAL_OUTPUT)
    echo -e "\033[1;30m  Tokens this step: ${si} in / ${so} out   |   Total so far: ${ti} in / ${to} out\033[0m"
  fi

  if [ $i -eq $STOP_AT ]; then
    echo ""
    if [ $STOP_AT -eq $LAST_STEP ]; then
      echo -e "\033[0;32mDONE. All steps completed and verified.\033[0m"
      if [ -f "keystatic.config.ts" ]; then
        echo ""
        echo -e "\033[1;37mLocal preview options:\033[0m"
        echo -e "  Option A (recommended): npm run dev"
        echo -e "\033[1;30m    If pages are blank or show 500, try Option B.\033[0m"
        echo -e "  Option B (always works): npm run dev:build"
        echo -e "\033[1;30m    Builds the full site and serves it at http://localhost:4321\033[0m"
        echo -e "\033[1;30m    (search works here too)\033[0m"
        echo ""
        echo -e "Full E2E tests (optional):  npm run test:e2e"
        echo ""
        echo -e "\033[0;36mBefore going live — open README.md for:\033[0m"
        echo -e "  - How to write and publish articles"
        echo -e "  - How to set up the Keystatic CMS on Vercel"
        echo -e "  - How to customize colors, fonts, and content"
      else
        echo -e "\033[0;32mStart the blog with:  npm run dev   (then open http://localhost:4321)\033[0m"
        echo -e "\033[0;32mFull E2E tests (optional):  npm run test:e2e\033[0m"
        echo ""
        echo -e "\033[0;36mBefore going live — open README.md for:\033[0m"
        echo -e "  - How to write and publish articles"
        echo -e "  - How to customize and deploy the blog"
      fi
    else
      echo -e "\033[0;32mDONE. Steps $START_STEP-$STOP_AT completed and verified.\033[0m"
      echo -e "\033[0;36mResume with:  ./run.sh -s $(( STOP_AT + 1 ))\033[0m"
    fi
    break
  fi

  if [ "$PAUSE" = true ]; then
    read -p "Press ENTER to proceed to the next step (CTRL+C to stop)"
  fi
done
