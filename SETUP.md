# How to build the blog automatically

This package contains:
- `CLAUDE.md` — the project rules (read by Claude Code at each step)
- `prompts/` — the 7 prompts, already corrected, in order
- `run.sh` & `run.ps1` — the automation scripts for Linux/macOS and Windows
- `SETUP.md` — this guide

Core idea: **each prompt is executed in a separate Claude Code session**, so the context window never fills up. After each step, the script automatically verifies that `npm run build` (and unit tests) pass and **stops at the first issue**, preventing building on top of a broken state.

---

## 1. Prerequisites (one time only)

1. **Git** — required by Claude Code.
   - **Windows**: Download from [https://git-scm.com/download/win](https://git-scm.com/download/win)
   - **Linux**: `sudo apt install git`
   - **macOS**: `brew install git` or use the one bundled with Xcode.

2. **Node.js LTS** — needed to build the blog (Astro).
   Download it from [https://nodejs.org](https://nodejs.org) , then in a new terminal verify:

       node -v

   It must be 18 or higher.

3. **Claude Code** (requires a paid plan: Pro, Max, Team, or Enterprise — 
   the free plan does not include Claude Code):

       winget install Anthropic.ClaudeCode

   Alternatively, via npm:

       npm install -g @anthropic-ai/claude-code

   **Close and reopen PowerShell**, then verify:

       claude doctor

   If it says `claude` is not recognized, it's just a PATH issue: close and reopen 
   the terminal; if it persists, follow the PATH section of the official guide.

4. **Login** (also authenticates automated runs). Run once interactively:

       claude

   Complete the login in the browser, then exit by typing `/exit`.

> Cost note: from June 15, 2026, the use of `claude -p` on subscription plans draws from a 
> separate "Agent SDK" monthly credit, distinct from interactive use limits. Check your plan details.

---

## 2. Prepare the folder

1. Place this `blog-builder` folder wherever you prefer (e.g., `Documents/blog-builder`).
2. Open your terminal (or PowerShell on Windows) and `cd` to the folder.
3. **No need for `/init`**: you already have `CLAUDE.md`. (`/init` is only needed to *generate* a CLAUDE.md 
   from scratch and is an interactive command, not useful here.)
4. **On Linux/macOS**, make the script executable:
       chmod +x run.sh
   **On Windows**, allow script execution for this window:
       Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

---

## 3. Run

Normal execution (stops automatically at the first error):

    Linux/macOS:  ./run.sh
    Windows:      .\run.ps1

Maximum supervision (pauses after EVERY step to check carefully):

    Linux/macOS:  ./run.sh -p
    Windows:      .\run.ps1 -Pause

If the script stops at step N after you fix it, resume from there:

    Linux/macOS:  ./run.sh -s 3
    Windows:      .\run.ps1 -StartStep 3

The logs of each step end up in `logs\step_N.json` (they also include the call cost).

---

## 4. If a step fails (anti-drift)

The script **does not proceed** if the build breaks. When it stops:

1. Open the folder in **VS Code** (`code .`).
2. Launch Claude interactively: `claude`
3. Paste the build error (or describe what is wrong) and let it fix the issue.
4. Verify manually that it turns green:

       npm run build

5. Resume the pipeline from the stopped step:

       Linux/macOS:  ./run.sh -s N
       Windows:      .\run.ps1 -StartStep N

Terminal or VS Code extension? Same engine. The **pipeline must be launched from the terminal** (the `-p` mode is made for scripts). The **VS Code extension** is handy during 
the manual correction phases of step 4.

---

## 5. At the end

    npm run dev

Open http://localhost:4321 . For full E2E tests (optional, they launch a browser):

    npm run test:e2e

Test article: create `src/content/articles/test.mdx` with `status: published` following 
the schema in `CLAUDE.md`.

---

## 6. Before publishing to GitHub / Vercel

- Fill out `src/config.ts` (title, url, author) and update `yourdomain.com` in `public/robots.txt`.
- Add a `.gitignore` with at least: `node_modules/`, `dist/`, `.astro/`, `test-results/`, 
  `playwright-report/`, and the service files of this package if you don't want them in the repo 
  (`run.sh`, `run.ps1`, `prompts/`, `SETUP.md`, `logs/`).
- On Vercel: connect the repo, automatic build (the `build` script already includes Pagefind). 
  No Vercel adapter: the site is static.