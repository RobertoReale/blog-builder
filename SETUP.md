# How to build the blog automatically

This folder contains everything needed to generate the blog:

- `CLAUDE.md` — the project rules, read by Claude Code at every step
- `prompt_blog_*.txt` — the build prompts (steps 0–9 core, 10–12 optional, 13 manual)
- `run.js` — the pipeline script (cross-platform, recommended)
- `run.sh` / `run.ps1` — platform-specific alternatives (Linux/macOS and Windows)
- `SETUP.md` — this guide

Core idea: **each prompt runs in a separate Claude Code session**, so the context window never fills up. After each step, the script independently verifies that `npm run build` (and unit tests) pass, commits a git checkpoint, then **stops at the first failure** — it never builds on top of a broken state.

> **Future-proofing tip**: Web technologies evolve rapidly. Before proceeding, we recommend asking your preferred LLM (like Gemini, Claude, or ChatGPT) to review this repository: *"Are these scripts and prompts up-to-date with current best practices? Please update them if necessary."* This ensures the builder remains functional for years to come.

---

## 1. Prerequisites (one time only)

1. **Git** — required by Claude Code.
   - **Windows**: [https://git-scm.com/download/win](https://git-scm.com/download/win)
   - **Linux**: `sudo apt install git`
   - **macOS**: `brew install git` or use the one bundled with Xcode.

2. **Node.js LTS** — needed to build the blog (Astro).
   Download from [https://nodejs.org](https://nodejs.org), then verify in a new terminal:

       node -v

   Use the current active LTS version (download from nodejs.org — the LTS badge
   shows which version to use). Avoid end-of-life releases.

3. **Claude Code** (requires a paid plan: Pro, Max, Team, or Enterprise):

       winget install Anthropic.ClaudeCode

   Alternatively, via npm:

       npm install -g @anthropic-ai/claude-code

   Close and reopen the terminal, then verify:

       claude doctor

   If `claude` is not recognized, it's a PATH issue — close and reopen the terminal.

5. **Login** (authenticates automated runs too). Run once interactively:

       claude

   Complete the browser login, then exit with `/exit`.

> Cost note: the use of `claude -p` on subscription plans draws from a separate "Agent SDK"
> monthly credit, distinct from interactive use limits. Check your plan details before running.

---

## 2. Configure your blog

Run the interactive setup script — it fills in `CLAUDE.md` for you:

    Cross-platform:  node setup.js                              (recommended — Node.js only, no Python)
    Linux/macOS:     chmod +x setup.sh run.sh && ./setup.sh    (alternative)
    Windows:         .\setup.ps1                               (alternative)

The script asks for:
- **Site info**: blog title, description, URL, author name.
- **Color palette**: 5 presets (Blue/Neutral, Forest, Sunset, Ink, Mono) or custom hex values.
- **Font pairing**: 5 font presets (self-hosted via @fontsource) or your own.
- **GitHub** (optional): creates a repo and sets it as the git remote. Requires [GitHub CLI](https://cli.github.com).

> If you prefer to configure manually, open `CLAUDE.md` and fill in the sections marked **USER ACTION REQUIRED**.

---

## 3. Run

Allow script execution (Windows only, once per terminal session):

    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Preview which steps would run without executing anything:

    Cross-platform:  node run.js --dry-run
    Linux/macOS:     ./run.sh -d
    Windows:         .\run.ps1 -DryRun

Normal execution (stops automatically at the first error):

    Cross-platform:  node run.js
    Linux/macOS:     ./run.sh
    Windows:         .\run.ps1

Pause after every step to inspect the output before continuing:

    Cross-platform:  node run.js --pause
    Linux/macOS:     ./run.sh -p
    Windows:         .\run.ps1 -Pause

Resume from step N after fixing an error:

    Cross-platform:  node run.js --start-step 3
    Linux/macOS:     ./run.sh -s 3
    Windows:         .\run.ps1 -StartStep 3

Run only a subset of steps (useful for testing a single feature in isolation):

    Cross-platform:  node run.js --start-step 3 --end-step 5
    Linux/macOS:     ./run.sh -s 3 -e 5
    Windows:         .\run.ps1 -StartStep 3 -EndStep 5

Logs for each step are saved to `logs/step_N.json` (output + call cost).

After every successful step, the script commits a git checkpoint (`Step N: <name>`), so any step can be rolled back with `git reset --hard HEAD~1` if needed.

---

## 4. If a step fails (anti-drift)

The script **does not proceed** if the build breaks. When it stops:

1. Open this folder in **VS Code** (`code .`).
2. Run `claude` (interactive) and paste the build error or describe what is wrong.
3. Verify manually that the build is green:

       npm run build

4. Resume the pipeline from the failed step:

       Cross-platform:  node run.js --start-step N
       Linux/macOS:     ./run.sh -s N
       Windows:         .\run.ps1 -StartStep N

> **Note**: `run.js` includes automatic self-healing — when a build fails, it
> asks Claude to fix the errors and retries up to 2 times before stopping.

**Terminal vs VS Code extension**: same engine. Launch the pipeline from the terminal; use the VS Code extension for the manual fix in step 2.

If you want to undo the partial work from a failed step entirely, roll back to the previous checkpoint:

    git reset --hard HEAD~1

---

## 5. After the build completes

### Start the blog

**Without Keystatic (steps 0–6):**
```bash
npm run dev
# open http://localhost:4321
```

**With Keystatic (step 7 included) — try in order:**
```bash
# Option A: standard dev server
npm run dev
# open http://localhost:4321

# Option B: build-based preview (always works; search is also indexed)
npm run dev:build
# open http://localhost:4321
```

If `npm run dev` shows blank pages or 500 errors after Step 7, use `npm run dev:build`.
See the [Troubleshooting section in README.md](README.md#11-troubleshooting) for the cause and fix.

### What you get

| Feature | How to use |
|---|---|
| **Homepage** | Lists all published articles, filterable by tag |
| **Articles page** | `/articles` — same list, no hero |
| **Article page** | `/article/[slug]` — TOC, reading time, tags, series nav, related |
| **Search** | `/search` — type to search (or press `/` anywhere on the site) |
| **About / Now** | `/about` and `/now` — edit the placeholder content |
| **Dark mode** | Toggle in the top-right corner; preference saved in localStorage |
| **RSS feed** | `/rss.xml` — auto-generated from published articles |
| **Sitemap** | `/sitemap-index.xml` |
| **Keystatic CMS** | `yourdomain.com/keystatic` — browser editor (Step 7 only) |

### Next steps

👉 **[README.md](README.md)** — the complete guide covering:
- Writing and publishing articles (frontmatter, MDX components)
- Customizing colors, fonts, navigation
- Deploying to Vercel
- Setting up the Keystatic CMS
- Troubleshooting common issues

---

## 6. Before publishing to GitHub / Vercel

- Fill in `src/config.ts` (title, url, author) — the robots.txt is generated dynamically from that file, so no separate edit is needed.
- Add a `.gitignore` with at least:

      node_modules/
      dist/
      .astro/
      .vercel/
      test-results/
      playwright-report/
      logs/

  Optionally also exclude the builder infrastructure if you don't want it in the published repo:

      SETUP.md
      run.js
      run.sh
      run.ps1
      prompt_blog_*.txt

- **Vercel**: connect the repo, select the project. If you ran Step 7 (Keystatic CMS), the `@astrojs/vercel` adapter is already installed and Vercel will detect it automatically. For blogs without Keystatic (Steps 0–6 only), no adapter is needed — the site is fully statically generated.
