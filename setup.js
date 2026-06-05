#!/usr/bin/env node
/**
 * setup.js — Cross-platform setup for blog-builder.
 * Replaces setup.ps1 (Windows) and setup.sh (Linux/macOS).
 * Requires only Node.js — no Python, no PowerShell.
 *
 * USAGE:
 *   node setup.js
 */

'use strict'

const fs  = require('fs')
const rl  = require('readline')
const { spawnSync } = require('child_process')

// --- ANSI helpers (Windows 10+ and all Unix) ---------------------------------
const c = {
  white:  s => `\x1b[1;37m${s}\x1b[0m`,
  yellow: s => `\x1b[1;33m${s}\x1b[0m`,
  green:  s => `\x1b[0;32m${s}\x1b[0m`,
  red:    s => `\x1b[0;31m${s}\x1b[0m`,
  cyan:   s => `\x1b[0;36m${s}\x1b[0m`,
  gray:   s => `\x1b[1;30m${s}\x1b[0m`,
}

const isWin = process.platform === 'win32'

const iface = rl.createInterface({ input: process.stdin, output: process.stdout })

function ask(prompt) {
  return new Promise(resolve => iface.question(prompt, answer => resolve(answer.trim())))
}

function header(text) {
  console.log('')
  console.log(c.white('================================================='))
  console.log(c.white(`  ${text}`))
  console.log(c.white('================================================='))
  console.log('')
}

function section(text) {
  console.log('')
  console.log(c.cyan(`=== ${text} ===`))
  console.log('')
}

function commandExists(name) {
  const res = spawnSync(isWin ? 'where' : 'which', [name], { stdio: 'ignore', shell: isWin })
  return !res.error && res.status === 0
}

;(async () => {
  header('Blog Builder — Setup')

  // --- Prerequisites ----------------------------------------------------------
  if (!fs.existsSync('CLAUDE.md')) {
    console.error(c.red('Error: CLAUDE.md not found. Run this script from the blog-builder folder.'))
    iface.close()
    process.exit(1)
  }

  // --- 1. Site info -----------------------------------------------------------
  section('1/6 — Site info')
  const blogTitle  = await ask('Blog title: ')
  const blogDesc   = await ask('Description (one sentence): ')
  console.log('')
  console.log(c.gray('  URL tip: if deploying to Vercel and you haven\'t deployed yet, Vercel'))
  console.log(c.gray('  will assign an auto-generated link (e.g. blog-6jcd.vercel.app).'))
  console.log(c.gray('  You can rename it for free in Settings → Domains after the first deploy.'))
  console.log(c.gray('  → Enter a placeholder now and update src/config.ts after. See README.md §5.'))
  console.log('')
  const blogUrl    = await ask('URL (e.g. https://yourdomain.vercel.app): ')
  const blogAuthor = await ask('Author name: ')

  // --- 2. Color palette -------------------------------------------------------
  section('2/6 — Color palette')
  console.log('  1  Blue / Neutral  — clean, professional           (default)')
  console.log('  2  Forest          — warm greens, earthy tones')
  console.log('  3  Sunset          — warm oranges, amber')
  console.log('  4  Ink             — deep purples, editorial')
  console.log('  5  Mono            — pure black and white, minimal')
  console.log('  6  Custom          — enter your own hex values')
  console.log('')
  const colorChoice = (await ask('Choice [1-6, default 1]: ')) || '1'

  let lBg, lTx, lMu, lAc, lBo, lSu
  let dBg, dTx, dMu, dAc, dBo, dSu

  if (colorChoice === '2') {
    lBg='#FAFAF8'; lTx='#1C2B1A'; lMu='#6B7B6A'; lAc='#2D6A4F'; lBo='#D8E8D4'; lSu='#F0F5EE'
    dBg='#161E15'; dTx='#E8F0E6'; dMu='#8FA98D'; dAc='#52B788'; dBo='#2D3F2B'; dSu='#1E2B1C'
  } else if (colorChoice === '3') {
    lBg='#FFFBF7'; lTx='#1C1410'; lMu='#7B6B60'; lAc='#C2580A'; lBo='#EDD9C8'; lSu='#FAF1E8'
    dBg='#1A1108'; dTx='#F5EDE4'; dMu='#A89080'; dAc='#E8844A'; dBo='#3D2A1A'; dSu='#261A0E'
  } else if (colorChoice === '4') {
    lBg='#FDFCFF'; lTx='#1A1625'; lMu='#72687E'; lAc='#6D28D9'; lBo='#E4DFF0'; lSu='#F5F2FC'
    dBg='#120E1C'; dTx='#EDE9F5'; dMu='#9A90A8'; dAc='#A78BFA'; dBo='#2D2640'; dSu='#1C1730'
  } else if (colorChoice === '5') {
    lBg='#FFFFFF'; lTx='#0A0A0A'; lMu='#737373'; lAc='#0A0A0A'; lBo='#E5E5E5'; lSu='#FAFAFA'
    dBg='#0A0A0A'; dTx='#FAFAFA'; dMu='#A3A3A3'; dAc='#FAFAFA'; dBo='#262626'; dSu='#171717'
  } else if (colorChoice === '6') {
    console.log('')
    console.log(c.cyan('Light mode:'))
    lBg = await ask('  Background:             ')
    lTx = await ask('  Text:                   ')
    lMu = await ask('  Muted (secondary text): ')
    lAc = await ask('  Accent (links/buttons): ')
    lBo = await ask('  Border:                 ')
    lSu = await ask('  Surface (card bg):      ')
    console.log('')
    console.log(c.cyan('Dark mode:'))
    dBg = await ask('  Background: ')
    dTx = await ask('  Text:       ')
    dMu = await ask('  Muted:      ')
    dAc = await ask('  Accent:     ')
    dBo = await ask('  Border:     ')
    dSu = await ask('  Surface:    ')
  } else {
    lBg='#FFFFFF'; lTx='#111827'; lMu='#6B7280'; lAc='#2563EB'; lBo='#E5E7EB'; lSu='#F9FAFB'
    dBg='#111827'; dTx='#F3F4F6'; dMu='#9CA3AF'; dAc='#3B82F6'; dBo='#374151'; dSu='#1F2937'
  }

  // --- 3. Typography ----------------------------------------------------------
  section('3/6 — Typography')
  console.log('  1  Lora + DM Sans                  — classic serif + clean sans  (default)')
  console.log('  2  Playfair Display + Source Sans 3 — editorial, elegant')
  console.log('  3  DM Serif Display + DM Sans      — modern, cohesive')
  console.log('  4  Fraunces + Inter                — quirky serif + tech sans')
  console.log('  5  Inter + Inter                   — pure sans-serif, minimal')
  console.log('  6  Custom                          — enter your own fontsource.org font names')
  console.log('')
  const fontChoice = (await ask('Choice [1-6, default 1]: ')) || '1'

  let headingFont, headingType, bodyFont
  if (fontChoice === '2')      { headingFont = 'Playfair Display'; headingType = 'serif';      bodyFont = 'Source Sans 3' }
  else if (fontChoice === '3') { headingFont = 'DM Serif Display'; headingType = 'serif';      bodyFont = 'DM Sans' }
  else if (fontChoice === '4') { headingFont = 'Fraunces';         headingType = 'serif';      bodyFont = 'Inter' }
  else if (fontChoice === '5') { headingFont = 'Inter';            headingType = 'sans-serif'; bodyFont = 'Inter' }
  else if (fontChoice === '6') {
    headingFont = await ask('Heading font (exact name as on fontsource.org, e.g. Playfair Display): ')
    headingType = await ask('  serif or sans-serif? ')
    bodyFont    = await ask('Body/UI font (exact name as on fontsource.org, e.g. Source Sans 3): ')
  } else {
    headingFont = 'Lora'; headingType = 'serif'; bodyFont = 'DM Sans'
  }

  // --- 4. Analytics -----------------------------------------------------------
  section('4/6 — Analytics (optional)')
  console.log('  0  None                         — no analytics, skip this step  (default)')
  console.log('  1  Umami Cloud                  — privacy-first, 100k events/month free  (recommended)')
  console.log('  2  Cloudflare Web Analytics     — unlimited free, requires DNS nameserver change')
  console.log('  3  Vercel Analytics             — 2,500 events/month free, minimal setup')
  console.log('')
  const analyticsChoice = (await ask('Choice [0-3, default 0]: ')) || '0'
  const analyticsProvider = ({ '1': 'umami', '2': 'cloudflare', '3': 'vercel' })[analyticsChoice] || 'none'

  // --- 5. Comments ------------------------------------------------------------
  section('5/6 — Comments (optional)')
  console.log('  0  None         — no comments section  (default)')
  console.log('  1  Giscus       — GitHub Discussions, privacy-first, free  (recommended)')
  console.log('  2  Utterances   — GitHub Issues, simpler, free')
  console.log('')
  const commentsChoice = (await ask('Choice [0-2, default 0]: ')) || '0'
  const commentsProvider = ({ '1': 'giscus', '2': 'utterances' })[commentsChoice] || 'none'

  // --- 6. Newsletter ----------------------------------------------------------
  section('6/6 — Newsletter (optional)')
  console.log('  0  None          — no newsletter form  (default)')
  console.log('  1  Buttondown    — privacy-first, 100 subscribers free  (recommended)')
  console.log('  2  Substack      — popular, free for free newsletters')
  console.log('  3  Kit           — formerly ConvertKit, 10k subscribers free')
  console.log('')
  const newsletterChoice = (await ask('Choice [0-3, default 0]: ')) || '0'
  const newsletterProvider = ({ '1': 'buttondown', '2': 'substack', '3': 'kit' })[newsletterChoice] || 'none'

  // --- GitHub (optional) ------------------------------------------------------
  section('GitHub (optional)')
  console.log('Create a GitHub repository for your blog?')
  console.log(`  Requires: ${c.white('GitHub CLI (gh)')} — https://cli.github.com`)
  console.log('')
  const ghAns = await ask('Set up GitHub? [y/N]: ')

  let repoName    = ''
  let visChoice   = '1'

  if (/^[Yy]$/.test(ghAns)) {
    repoName  = await ask('Repository name (e.g. my-blog): ')
    console.log('')
    console.log('  1  Public')
    console.log('  2  Private')
    visChoice = (await ask('Visibility [1-2, default 1]: ')) || '1'
  }

  // Done collecting input — close readline before running external processes
  iface.close()

  // --- Update CLAUDE.md -------------------------------------------------------
  console.log('')
  process.stdout.write(c.cyan('Updating CLAUDE.md... '))

  let content = fs.readFileSync('CLAUDE.md', 'utf8').replace(/\r\n/g, '\n')

  // 1. Insert or update site values before the "Import SITE" paragraph
  const siteMarker = 'Import SITE wherever site-level data is needed.'
  const siteBlock  = (
    `Site values (use these when creating src/config.ts):\n` +
    `- title: "${blogTitle}"\n` +
    `- description: "${blogDesc}"\n` +
    `- url: "${blogUrl}"\n` +
    `- author: "${blogAuthor}"\n\n`
  )
  // Remove any pre-existing site values block (re-run scenario)
  content = content.replace(
    /Site values \(use these when creating src\/config\.ts\):\n[\s\S]*?- author: ".*?"\n\n(?=Import SITE)/,
    ''
  )
  if (content.includes(siteMarker)) {
    content = content.replace(siteMarker, siteBlock + siteMarker)
  }

  // 2. Replace color palette CSS block
  const newColorBlock = [
    '```css',
    '/* Light mode (:root) */',
    `--color-bg: ${lBg}`,
    `--color-text: ${lTx}`,
    `--color-muted: ${lMu}`,
    `--color-accent: ${lAc}`,
    `--color-border: ${lBo}`,
    `--color-surface: ${lSu}`,
    '',
    '/* Dark mode ([data-theme="dark"] on <html>) */',
    `--color-bg: ${dBg}`,
    `--color-text: ${dTx}`,
    `--color-muted: ${dMu}`,
    `--color-accent: ${dAc}`,
    `--color-border: ${dBo}`,
    `--color-surface: ${dSu}`,
    '```',
  ].join('\n')

  const colorBlockRe = /```css\n\/\* Light mode \(:root\) \*\/[\s\S]*?```/
  if (colorBlockRe.test(content)) {
    content = content.replace(colorBlockRe, newColorBlock)
  } else {
    console.log(c.yellow('\n  Note: color block not found — already configured?'))
  }

  // 3. Replace typography lines
  content = content.replace(/- Headings \(h1[–-]h3\): .+/, `- Headings (h1–h3): ${headingFont}, ${headingType}`)
  content = content.replace(/- Body \+ UI: .+, sans-serif/, `- Body + UI: ${bodyFont}, sans-serif`)

  // 4. Update Fonts line in STACK section
  content = content.replace(
    /- Fonts: .+\(headings\) \+ .+\(body\/UI\).*/,
    `- Fonts: ${headingFont} (headings) + ${bodyFont} (body/UI) — self-hosted via @fontsource`
  )

  // 5. Replace provider values (section-aware)
  function replaceProvider(text, sectionName, newValue) {
    return text.replace(
      new RegExp(`(## ${sectionName}\n\n)Provider:\\s*\\S+`),
      `$1Provider: ${newValue}`
    )
  }
  content = replaceProvider(content, 'ANALYTICS',  analyticsProvider)
  content = replaceProvider(content, 'COMMENTS',   commentsProvider)
  content = replaceProvider(content, 'NEWSLETTER', newsletterProvider)

  fs.writeFileSync('CLAUDE.md', content, 'utf8')
  console.log(c.green('Done.'))
  console.log(c.green('CLAUDE.md configured.'))

  // --- GitHub -----------------------------------------------------------------
  let githubRemote = ''
  if (/^[Yy]$/.test(ghAns)) {
    if (!commandExists('gh')) {
      console.log('')
      console.log(c.yellow('Warning: GitHub CLI (gh) not found.'))
      console.log(c.yellow('Install it from https://cli.github.com then rerun: node setup.js'))
    } else {
      const authCheck = spawnSync('gh', ['auth', 'status'], { stdio: 'ignore', shell: isWin })
      if (authCheck.status !== 0) {
        console.log('Logging in to GitHub...')
        spawnSync('gh', ['auth', 'login'], { stdio: 'inherit', shell: isWin })
      }

      const visFlag = visChoice === '2' ? '--private' : '--public'

      if (!fs.existsSync('.git')) {
        spawnSync('git', ['init'],                                                         { stdio: 'ignore' })
        spawnSync('git', ['add', '-A'],                                                    { stdio: 'ignore' })
        spawnSync('git', ['commit', '-m', 'Initial setup: blog configuration', '--quiet'], { stdio: 'ignore' })
      }

      spawnSync('git', ['remote', 'remove', 'origin'], { stdio: 'ignore', shell: isWin })
      console.log('')
      spawnSync('gh', ['repo', 'create', repoName, visFlag, '--description', blogDesc], { stdio: 'inherit', shell: isWin })

      const ghUser = spawnSync('gh', ['api', 'user', '--jq', '.login'], { encoding: 'utf8', shell: isWin })
      const githubUser = (ghUser.stdout || '').trim()
      githubRemote = `https://github.com/${githubUser}/${repoName}.git`
      spawnSync('git', ['remote', 'add', 'origin', githubRemote], { stdio: 'ignore', shell: isWin })
      console.log(c.green(`Repository created: https://github.com/${githubUser}/${repoName}`))
    }
  }

  // --- Done -------------------------------------------------------------------
  const optionalSteps = []
  if (analyticsProvider  !== 'none') optionalSteps.push('analytics')
  if (commentsProvider   !== 'none') optionalSteps.push('comments')
  if (newsletterProvider !== 'none') optionalSteps.push('newsletter')

  const baseSteps  = 10
  const totalSteps = baseSteps + optionalSteps.length
  const lastStep   = totalSteps - 1
  const stepNote   = optionalSteps.length > 0
    ? `runs all ${totalSteps} steps, 0–${lastStep} — ${optionalSteps.join(', ')} included`
    : `runs all ${baseSteps} steps, 0–${baseSteps - 1}`

  console.log('')
  console.log(c.white('================================================='))
  console.log(c.green('  Setup complete!'))
  console.log(c.white('================================================='))
  console.log('')
  console.log(c.white('Next steps:'))
  console.log('')
  console.log('  1. Run the ecosystem discovery (optional but recommended):')
  console.log('       Open Claude Code in this folder, then send the contents of:')
  console.log(c.white('       prompt_blog_pre_discovery.txt'))
  console.log(c.gray('       Claude searches for the best current tools, shows them to you,'))
  console.log(c.gray('       and writes your choices to CHOSEN_TOOLS.md.'))
  console.log(c.gray('       Every subsequent build step will pick them up automatically.'))
  console.log('')
  console.log('  2. Generate the blog:')
  console.log(`       ${c.white('node run.js')}      (cross-platform, recommended — ${stepNote})`)
  console.log(`       ${c.white('./run.sh')}         (Linux/macOS alternative)`)
  console.log(`       ${c.white('.\\run.ps1')}       (Windows alternative)`)
  console.log('')
  if (githubRemote) {
    console.log('  3. After the pipeline finishes, push to GitHub:')
    console.log(`       ${c.white('git push -u origin HEAD')}`)
    console.log('')
  }
  console.log('  Once generated, preview with:  npm run dev')
  console.log('  Then open:  http://localhost:4321')
  console.log('')
})()
