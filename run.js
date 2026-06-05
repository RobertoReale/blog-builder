#!/usr/bin/env node
/**
 * run.js — Cross-platform pipeline orchestrator for blog-builder.
 * Single script for Windows, macOS, and Linux. Replaces run.ps1 / run.sh.
 *
 * USAGE:
 *   node run.js                               # run all steps
 *   node run.js --start-step 3               # resume from step 3
 *   node run.js --start-step 3 --end-step 5  # run only steps 3–5
 *   node run.js --pause                      # pause after each step
 *   node run.js --dry-run                    # preview steps without executing
 *   node run.js --max-retries 3              # self-healing retries on build failure (default: 2)
 *   node run.js --max-retries 0              # disable self-healing
 *   node run.js --help                       # show all options
 *
 * Short flags: -s, -e, -p, -d, -r, -h
 */

'use strict'

const { spawnSync, spawn } = require('child_process')
const fs   = require('fs')
const path = require('path')
const rl   = require('readline')

// --- ANSI color helpers (Windows 10+ and all Unix) --------------------------
const c = {
  white:  s => `\x1b[1;37m${s}\x1b[0m`,
  yellow: s => `\x1b[1;33m${s}\x1b[0m`,
  green:  s => `\x1b[0;32m${s}\x1b[0m`,
  red:    s => `\x1b[0;31m${s}\x1b[0m`,
  cyan:   s => `\x1b[0;36m${s}\x1b[0m`,
  gray:   s => `\x1b[1;30m${s}\x1b[0m`,
}

// --- Parse CLI args ----------------------------------------------------------
const argv = process.argv.slice(2)
let startStep  = 0
let endStep    = -1
let pause      = false
let dryRun     = false
let maxRetries = 2

for (let i = 0; i < argv.length; i++) {
  const a = argv[i]
  if (a === '--help' || a === '-h') {
    console.log(`
Blog Builder Pipeline — cross-platform orchestrator with self-healing.

Usage:  node run.js [options]

Options:
  -s, --start-step N    Resume from step N (default: 0)
  -e, --end-step N      Stop after step N
  -p, --pause           Pause after each step for inspection
  -d, --dry-run         Preview which steps would run, without executing
  -r, --max-retries N   Self-healing retries on build failure (default: 2, 0 to disable)
  -h, --help            Show this help message

Examples:
  node run.js                           Run all steps
  node run.js --start-step 3            Resume from step 3
  node run.js -s 3 -e 5                 Run only steps 3, 4, and 5
  node run.js --pause                   Pause after each step
  node run.js --dry-run                 Preview steps without executing
  node run.js --max-retries 0           Disable self-healing
`)
    process.exit(0)
  }
  if ((a === '--start-step'  || a === '-s') && argv[i + 1] !== undefined) startStep  = parseInt(argv[++i], 10)
  else if ((a === '--end-step'     || a === '-e') && argv[i + 1] !== undefined) endStep    = parseInt(argv[++i], 10)
  else if (a === '--pause'         || a === '-p') pause      = true
  else if (a === '--dry-run'       || a === '-d') dryRun     = true
  else if ((a === '--max-retries'  || a === '-r') && argv[i + 1] !== undefined) maxRetries = parseInt(argv[++i], 10)
}

// --- Step definitions -------------------------------------------------------
const prompts = [
  'prompt_blog_00_foundation.txt',
  'prompt_blog_01_testing.txt',
  'prompt_blog_02_seo.txt',
  'prompt_blog_03_reading_ux.txt',
  'prompt_blog_04_search.txt',
  'prompt_blog_05_series.txt',
  'prompt_blog_06_related.txt',
  'prompt_blog_07_keystatic.txt',
  'prompt_blog_08_e2e_check.txt',
  'prompt_blog_09_ui_review.txt',
]
const stepNames = [
  'Foundation',
  'Testing setup',
  'SEO',
  'Reading UX',
  'Search',
  'Series',
  'Related articles',
  'Keystatic CMS',
  'E2E integration check',
  'UI & design review',
]

// Conditionally append optional steps based on CLAUDE.md
const claudeMd = fs.existsSync('CLAUDE.md') ? fs.readFileSync('CLAUDE.md', 'utf8') : ''

if (/## ANALYTICS[\s\S]*?\nProvider:\s+(?:umami|cloudflare|vercel)\b/.test(claudeMd)) {
  prompts.push('prompt_blog_10_analytics.txt')
  stepNames.push('Analytics')
}
if (/## COMMENTS[\s\S]*?\nProvider:\s+(?:giscus|utterances)\b/.test(claudeMd)) {
  prompts.push('prompt_blog_11_comments.txt')
  stepNames.push('Comments')
}
if (/## NEWSLETTER[\s\S]*?\nProvider:\s+(?:buttondown|substack|kit)\b/.test(claudeMd)) {
  prompts.push('prompt_blog_12_newsletter.txt')
  stepNames.push('Newsletter')
}

// --- Preliminary checks -----------------------------------------------------
const isWin = process.platform === 'win32'

function commandExists(name) {
  const res = spawnSync(
    isWin ? 'where' : 'which',
    [name],
    { stdio: 'ignore', shell: isWin }
  )
  return !res.error && res.status === 0
}

function assertCommand(name, hint) {
  if (!commandExists(name)) {
    console.error(c.red(`ERROR: '${name}' not found. ${hint}`))
    process.exit(1)
  }
}

assertCommand('claude', 'Install Claude Code (see SETUP.md) and reopen the terminal.')
assertCommand('node',   'Install Node.js LTS from https://nodejs.org')
assertCommand('npm',    'Install Node.js LTS from https://nodejs.org')

if (!fs.existsSync('CLAUDE.md')) {
  console.error(c.red('ERROR: CLAUDE.md not found. Run this script from the folder that contains it.'))
  process.exit(1)
}

if (!fs.existsSync('CHOSEN_TOOLS.md') && startStep === 0) {
  console.log('')
  console.log(c.gray('  Tip: CHOSEN_TOOLS.md not found — ecosystem discovery has not been run.'))
  console.log(c.gray('  Open Claude Code and send prompt_blog_pre_discovery.txt to enable optional'))
  console.log(c.gray('  integrations (syntax highlighting, PWA, OG images, etc.).'))
  console.log(c.gray('  Continuing without it is fine — all core features still work.'))
}

// Warn if setup was not run (CLAUDE.md still has placeholder values)
if (startStep === 0 && !/Site values \(use these when creating/.test(claudeMd)) {
  console.log('')
  console.log(c.yellow('  Warning: CLAUDE.md does not contain "Site values" — setup may not have been run.'))
  console.log(c.yellow('  Run setup first:  node setup.js  (cross-platform)  or  .\\setup.ps1 / ./setup.sh'))
  console.log(c.yellow('  Without setup, the blog will be generated with generic placeholder values.'))
}

fs.mkdirSync('logs', { recursive: true })

// --- System instruction (same as run.ps1 / run.sh) --------------------------
const INSTRUCTION = [
  'You are working in a project folder that contains CLAUDE.md: read it FIRST',
  'and follow every rule in it. Your standard input contains the instructions',
  'for the current task: execute them EXACTLY, without adding unrequested features.',
  "When done, run 'npm run build' (and 'npm run test:unit' if that script exists)",
  'and fix any errors until they pass. Do not go beyond the task you received.',
].join(' ')

// --- Step range -------------------------------------------------------------
const stopAt = (endStep >= 0 && endStep < prompts.length) ? endStep : prompts.length - 1

// --- Dry run ----------------------------------------------------------------
if (dryRun) {
  console.log('')
  console.log(c.cyan('DRY RUN — steps that would be executed:'))
  console.log('')
  for (let j = startStep; j <= stopAt; j++) {
    console.log(`  Step ${String(j).padEnd(2)}  ${stepNames[j].padEnd(20)}  (${prompts[j]})`)
  }
  console.log('')
  console.log(c.cyan(`  Total: ${stopAt - startStep + 1} step(s)`))
  console.log('')
  process.exit(0)
}

// --- Git init if needed -----------------------------------------------------
if (!fs.existsSync('.git')) {
  spawnSync('git', ['init'],                                                    { stdio: 'ignore' })
  spawnSync('git', ['add', '-A'],                                               { stdio: 'ignore' })
  spawnSync('git', ['commit', '-m', 'Initial commit (pre-pipeline)', '--quiet'], { stdio: 'ignore' })
}

// --- Run npm (synchronous, captures + displays output) ----------------------
function runNpm(npmArgs) {
  const result = spawnSync('npm', npmArgs, {
    stdio: 'pipe',
    encoding: 'utf8',
    shell: isWin,
  })
  if (result.stdout) process.stdout.write(result.stdout)
  if (result.stderr) process.stderr.write(result.stderr)
  return {
    exitCode: result.status ?? 1,
    output: (result.stdout || '') + (result.stderr || ''),
  }
}

// --- Run Claude (async, streaming, writes to log file) ----------------------
function runClaude(instruction, promptContent, logFile) {
  return new Promise(resolve => {
    const proc = spawn('claude', [
      '-p', instruction,
      '--permission-mode', 'acceptEdits',
      '--allowedTools', 'Bash,Read,Edit,Write,Glob,Grep,MultiEdit',
      '--output-format', 'stream-json',
    ], {
      stdio: ['pipe', 'pipe', 'pipe'],
      shell: isWin,
    })

    if (promptContent) proc.stdin.write(promptContent)
    proc.stdin.end()

    const log = fs.createWriteStream(logFile)
    proc.stdout.on('data', chunk => { process.stdout.write(chunk); log.write(chunk) })
    proc.stderr.on('data', chunk => { process.stderr.write(chunk); log.write(chunk) })
    proc.on('close', code  => { log.end(); resolve(code ?? 1) })
    proc.on('error', ()    => { log.end(); resolve(1) })
  })
}

// --- Verify: install + build + unit tests -----------------------------------
async function verifyProject(installNeeded) {
  if (!fs.existsSync('package.json')) {
    console.log(c.gray('  (package.json not present yet — skipping verification)'))
    return { ok: true, buildOutput: '' }
  }

  if (installNeeded) {
    console.log(c.cyan('  -> npm install'))
    const r = runNpm(['install', '--no-audit', '--no-fund'])
    if (r.exitCode !== 0) return { ok: false, buildOutput: r.output }
  } else {
    console.log(c.gray('  -> npm install (skipped — package.json unchanged)'))
  }

  console.log(c.cyan('  -> npm run build'))
  const build = runNpm(['run', 'build'])
  if (build.exitCode !== 0) return { ok: false, buildOutput: build.output }

  const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'))
  if (pkg.scripts?.['test:unit']) {
    console.log(c.cyan('  -> npm run test:unit'))
    const test = runNpm(['run', 'test:unit'])
    if (test.exitCode !== 0) return { ok: false, buildOutput: test.output }
  }
  return { ok: true, buildOutput: '' }
}

// --- Token usage: parse last "result" line in the stream-json log -----------
function getStepUsage(logFile) {
  if (!fs.existsSync(logFile)) return null
  try {
    const lines = fs.readFileSync(logFile, 'utf8').split('\n')
    for (let i = lines.length - 1; i >= 0; i--) {
      try {
        const d = JSON.parse(lines[i])
        if (d.type === 'result' && d.usage) {
          return { input: d.usage.input_tokens || 0, output: d.usage.output_tokens || 0 }
        }
      } catch { /* skip malformed lines */ }
    }
  } catch { /* file read error */ }
  return null
}

// --- Pause between steps ----------------------------------------------------
function waitForEnter() {
  return new Promise(resolve => {
    const iface = rl.createInterface({ input: process.stdin, output: process.stdout })
    iface.question('Press ENTER to proceed to the next step (CTRL+C to stop): ', () => {
      iface.close()
      resolve()
    })
  })
}

// --- Startup banner ---------------------------------------------------------
const stepCount = stopAt - startStep + 1
console.log('')
console.log(c.white(`Blog Builder Pipeline — steps ${startStep}–${stopAt}  (${stepCount} step${stepCount !== 1 ? 's' : ''})`))
console.log(c.yellow('To pause: CTRL+C   |   To resume: node run.js --start-step N'))
if (maxRetries > 0) {
  console.log(c.gray(`  Self-healing: up to ${maxRetries} auto-fix attempt(s) per step on build failure`))
}
console.log('')

// --- Main pipeline loop -----------------------------------------------------
;(async () => {
  let totalInput  = 0
  let totalOutput = 0

  for (let i = startStep; i <= stopAt; i++) {
    const file = prompts[i]
    console.log('')
    console.log(c.white('==================================================='))
    console.log(c.white(` STEP ${i}  ->  ${file}`))
    console.log(c.white('==================================================='))

    if (!fs.existsSync(file)) {
      console.error(c.red(`ERROR: prompt file missing: ${file}`))
      break
    }

    const promptContent = fs.readFileSync(file, 'utf8')
    const pkgBefore     = fs.existsSync('package.json') ? fs.readFileSync('package.json', 'utf8') : null
    const stepStartTime = Date.now()
    const logFile       = path.join('logs', `step_${i}.json`)

    // Run Claude for this step
    const claudeExit = await runClaude(INSTRUCTION, promptContent, logFile)
    if (claudeExit !== 0) {
      console.log('')
      console.error(c.red(`Claude terminated with an error at step ${i}. Stopping.`))
      console.log(c.yellow(`Check logs/step_${i}.json, fix the issue, then resume with:  node run.js --start-step ${i}`))
      break
    }

    // Detect if package.json changed so we know whether to run npm install
    let pkgSnapshot     = fs.existsSync('package.json') ? fs.readFileSync('package.json', 'utf8') : null
    const installNeeded = !fs.existsSync('node_modules') || pkgBefore !== pkgSnapshot

    console.log('')
    console.log(c.cyan(`  Independent verification of step ${i}...`))
    let verification = await verifyProject(installNeeded)

    // Self-healing loop: on build failure, ask Claude to fix the errors
    let retries = 0
    while (!verification.ok && retries < maxRetries) {
      retries++
      console.log('')
      console.log(c.yellow(`  Build failed. Self-healing attempt ${retries}/${maxRetries}...`))

      const healPrompt = [
        'The blog pipeline step just ran, but the independent build verification failed.',
        'Read the build errors below, identify the root cause in the generated code, and fix it.',
        'Do NOT add new features — only fix what is broken.',
        "After fixing, run 'npm run build' to confirm it passes.",
        '',
        'BUILD ERRORS:',
        verification.buildOutput,
      ].join('\n')

      const healLog  = path.join('logs', `step_${i}_heal_${retries}.json`)
      const healExit = await runClaude(INSTRUCTION, healPrompt, healLog)

      if (healExit !== 0) {
        console.log(c.red('  Self-healing: Claude exited with an error.'))
        break
      }

      // Detect if healing changed package.json
      const pkgAfterHeal    = fs.existsSync('package.json') ? fs.readFileSync('package.json', 'utf8') : null
      const healNeedsInstall = !fs.existsSync('node_modules') || pkgAfterHeal !== pkgSnapshot
      pkgSnapshot = pkgAfterHeal

      console.log('')
      console.log(c.cyan('  Re-verifying after self-healing...'))
      verification = await verifyProject(healNeedsInstall)
    }

    if (!verification.ok) {
      console.log('')
      console.log(c.red(`BUILD/TEST FAILED at step ${i} (${file}).`))
      console.log(c.red('Stopping here intentionally, to prevent building on a broken state.'))
      console.log('')
      console.log(c.yellow('WHAT TO DO NOW:'))
      console.log(c.yellow('  1) Open this folder in VS Code.'))
      console.log(c.yellow("  2) Run 'claude' (interactive) and describe/paste the build error."))
      console.log(c.yellow("  3) When 'npm run build' passes again, resume with:"))
      console.log(c.yellow(`       node run.js --start-step ${i}`))
      break
    }

    // Git checkpoint: commit so each step is a rollback point
    spawnSync('git', ['add', '-A'],                                                 { stdio: 'ignore' })
    spawnSync('git', ['commit', '-m', `Step ${i}: ${stepNames[i]}`, '--quiet'],    { stdio: 'ignore' })

    console.log('')
    console.log(c.green(`  STEP ${i} OK — build (and unit tests) passed.`))

    // Token counter + elapsed time
    const elapsedMs = Date.now() - stepStartTime
    const elapsedMin = Math.floor(elapsedMs / 60000)
    const elapsedSec = Math.floor((elapsedMs % 60000) / 1000)
    const elapsedStr = elapsedMin > 0 ? `${elapsedMin}m ${elapsedSec}s` : `${elapsedSec}s`
    const usage = getStepUsage(logFile)
    if (usage) {
      totalInput  += usage.input
      totalOutput += usage.output
      const fmt = n => n.toLocaleString('en-US')
      console.log(c.gray(
        `  Tokens this step: ${fmt(usage.input)} in / ${fmt(usage.output)} out` +
        `   |   Total so far: ${fmt(totalInput)} in / ${fmt(totalOutput)} out` +
        `   |   Time: ${elapsedStr}`
      ))
    } else {
      console.log(c.gray(`  Time: ${elapsedStr}`))
    }

    // Final step: print completion message
    if (i === stopAt) {
      console.log('')
      if (stopAt === prompts.length - 1) {
        console.log(c.green('DONE. All steps completed and verified.'))
        if (fs.existsSync('keystatic.config.ts')) {
          console.log('')
          console.log(c.white('Local preview options:'))
          console.log('  Option A (recommended): npm run dev')
          console.log(c.gray('    If pages are blank or show 500, try Option B.'))
          console.log('  Option B (always works): npm run dev:build')
          console.log(c.gray('    Builds the full site and serves it at http://localhost:4321'))
          console.log(c.gray('    (search works here too)'))
          console.log('')
          console.log('Full E2E tests (optional):  npm run test:e2e')
          console.log('')
          console.log(c.cyan('Before going live — open README.md for:'))
          console.log('  - How to write and publish articles')
          console.log('  - How to set up the Keystatic CMS on Vercel')
          console.log('  - How to customize colors, fonts, and content')
        } else {
          console.log(c.green('Start the blog with:  npm run dev   (then open http://localhost:4321)'))
          console.log(c.green('Full E2E tests (optional):  npm run test:e2e'))
          console.log('')
          console.log(c.cyan('Before going live — open README.md for:'))
          console.log('  - How to write and publish articles')
          console.log('  - How to customize and deploy the blog')
        }
      } else {
        console.log(c.green(`DONE. Steps ${startStep}–${stopAt} completed and verified.`))
        console.log(c.cyan(`Resume with:  node run.js --start-step ${stopAt + 1}`))
      }
      break
    }

    if (pause) {
      await waitForEnter()
    }
  }
})()
