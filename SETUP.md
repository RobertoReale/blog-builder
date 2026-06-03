# How to build the blog automatically

This folder contains everything needed to generate the blog:

- `CLAUDE.md` — the project rules, read by Claude Code at every step
- `prompt_blog_*.txt` — the 7 prompts, in order
- `run.sh` / `run.ps1` — the pipeline scripts (Linux/macOS and Windows)
- `SETUP.md` — this guide

Core idea: **each prompt runs in a separate Claude Code session**, so the context window never fills up. After each step, the script independently verifies that `npm run build` (and unit tests) pass, commits a git checkpoint, then **stops at the first failure** — it never builds on top of a broken state.

---

## 1. Prerequisites (one time only)

1. **Git** — required by Claude Code.
   - **Windows**: [https://git-scm.com/download/win](https://git-scm.com/download/win)
   - **Linux**: `sudo apt install git`
   - **macOS**: `brew install git` or use the one bundled with Xcode.

2. **Node.js LTS** — needed to build the blog (Astro).
   Download from [https://nodejs.org](https://nodejs.org), then verify in a new terminal:

       node -v

   Version 18 or higher required.

3. **Claude Code** (requires a paid plan: Pro, Max, Team, or Enterprise):

       winget install Anthropic.ClaudeCode

   Alternatively, via npm:

       npm install -g @anthropic-ai/claude-code

   Close and reopen the terminal, then verify:

       claude doctor

   If `claude` is not recognized, it's a PATH issue — close and reopen the terminal.

4. **Login** (authenticates automated runs too). Run once interactively:

       claude

   Complete the browser login, then exit with `/exit`.

> Cost note: the use of `claude -p` on subscription plans draws from a separate "Agent SDK"
> monthly credit, distinct from interactive use limits. Check your plan details before running.

---

## 2. Configure your blog

Run the interactive setup script — it fills in `CLAUDE.md` for you:

    Linux/macOS:  chmod +x setup.sh run.sh && ./setup.sh
    Windows:      .\setup.ps1

The script asks for:
- **Site info**: blog title, description, URL, author name.
- **Color palette**: 5 presets (Blue/Neutral, Forest, Sunset, Ink, Mono) or custom hex values.
- **Font pairing**: 5 Google Font presets or your own.
- **GitHub** (optional): creates a repo and sets it as the git remote. Requires [GitHub CLI](https://cli.github.com).

> If you prefer to configure manually, open `CLAUDE.md` and fill in the sections marked **USER ACTION REQUIRED**.

---

## 3. Run

Allow script execution (Windows only, once per terminal session):

    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Normal execution (stops automatically at the first error):

    Linux/macOS:  ./run.sh
    Windows:      .\run.ps1

Pause after every step to inspect the output before continuing:

    Linux/macOS:  ./run.sh -p
    Windows:      .\run.ps1 -Pause

Resume from step N after fixing an error:

    Linux/macOS:  ./run.sh -s 3
    Windows:      .\run.ps1 -StartStep 3

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

       Linux/macOS:  ./run.sh -s N
       Windows:      .\run.ps1 -StartStep N

**Terminal vs VS Code extension**: same engine. Launch the pipeline from the terminal; use the VS Code extension for the manual fix in step 2.

If you want to undo the partial work from a failed step entirely, roll back to the previous checkpoint:

    git reset --hard HEAD~1

---

## 5. At the end

Start the dev server:

    npm run dev

Open [http://localhost:4321](http://localhost:4321). For the full E2E test suite (optional, launches a browser):

    npm run test:e2e

To test with a real article: create `src/content/articles/test.mdx` with `status: published` following the schema in `CLAUDE.md`.

---

## 6. Before publishing to GitHub / Vercel

- Fill in `src/config.ts` (title, url, author) and replace `yourdomain.com` in `public/robots.txt`.
- Add a `.gitignore` with at least:

      node_modules/
      dist/
      .astro/
      test-results/
      playwright-report/
      logs/

  Optionally also exclude the builder infrastructure if you don't want it in the published repo:

      SETUP.md
      run.sh
      run.ps1
      prompt_blog_*.txt

- **Vercel**: connect the repo, select the project. If you ran Step 7 (Keystatic CMS), the `@astrojs/vercel` adapter is already installed and Vercel will detect it automatically. For blogs without Keystatic (Steps 0–6 only), no adapter is needed — the site is fully statically generated.
