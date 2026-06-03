# Blog Builder

A framework to build a complete, production-ready personal blog using Astro 4, Tailwind CSS, and MDX — generated entirely through sequenced LLM prompts via Claude Code.

## Concept: Iterative AI Generation

Instead of generating an entire codebase in one massive prompt (which causes context overflow, hallucinations, and broken code), this project uses a **sequenced prompt architecture**.

> **The Context Window Philosophy**: The build is split into 7 distinct sequential steps. Each prompt runs in a fresh Claude Code session, so the context window never fills up. The LLM only receives the project rules (`CLAUDE.md`) and the specific feature instructions, while reading the existing code on disk. This prevents the AI from forgetting previous instructions or hallucinating features.

Each step is independently verified (`npm run build` + unit tests) before the next one starts. If the build breaks, the pipeline stops immediately — it never builds on top of a broken state. After every successful step, a git commit is created automatically as a rollback point.

## Project Structure

```
blog-builder/
  CLAUDE.md                        The project rules — read by Claude at every step
  setup.sh / setup.ps1             Interactive setup: configure CLAUDE.md, create GitHub repo
  prompt_blog_00_foundation.txt    Step 0: layout, dark mode, MDX setup
  prompt_blog_01_testing.txt       Step 1: Vitest + Playwright test suite
  prompt_blog_02_seo.txt           Step 2: RSS, sitemap, robots.txt, JSON-LD
  prompt_blog_03_reading_ux.txt    Step 3: progress bar, TOC, back to top, share
  prompt_blog_04_search.txt        Step 4: Pagefind static search
  prompt_blog_05_series.txt        Step 5: article series grouping
  prompt_blog_06_related.txt       Step 6: related articles recommendation
  prompt_blog_07_keystatic.txt     Step 7: Keystatic CMS (browser editor, GitHub mode)
  prompt_blog_08_e2e_check.txt    Step 8: E2E integration check (fix any cross-feature failures)
  run.sh / run.ps1                 Pipeline script (Linux/macOS and Windows)
  SETUP.md                         Detailed setup and usage guide
```

## Token Usage and Cost

Running the full pipeline executes **8 separate Claude Code sessions**, each implementing a distinct feature. This is meaningful agentic work — expect hundreds of tool calls across all steps.

- **Claude Code subscribers (Max plan)**: the pipeline fits comfortably within typical monthly usage.
- **Claude Code subscribers (Pro plan)**: usage limits may be hit mid-pipeline. If that happens, wait for the limit to reset and resume with `./run.sh -s <step>` (or `.\run.ps1 -StartStep <step>` on Windows).
- **API users**: check [Anthropic pricing](https://www.anthropic.com/pricing) for your model tier. Sonnet is recommended over Opus for cost-efficiency — the prompts are explicit enough that the smaller model performs well.

The pipeline is designed to be resumable: every completed step is committed to git, so you never lose progress if you stop and restart.

## How to Use

Follow **[`SETUP.md`](SETUP.md)** for full instructions. Quick start:

1. Install prerequisites: Node.js LTS, Git, Claude Code.
2. Open a terminal in this folder and run the **interactive setup**:

   **Linux / macOS:**
   ```bash
   chmod +x setup.sh run.sh
   ./setup.sh
   ```

   **Windows (PowerShell):**
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\setup.ps1
   ```

   The setup script asks for your blog title, description, URL, author name, color palette (5 presets or custom), and font pairing (5 presets or custom). It writes your choices into `CLAUDE.md`. Optionally it creates a GitHub repository for you (requires [GitHub CLI](https://cli.github.com)).

3. Run the pipeline:

   **Linux / macOS:** `./run.sh`  
   **Windows:** `.\run.ps1`

4. Watch Claude Code iteratively build the blog, verify each step, commit a checkpoint, and move to the next. The final step (Step 8) runs the full E2E suite and fixes any integration failures.
5. If you set up a GitHub repo in step 2, push when done: `git push -u origin HEAD`

## Deployment

The output is a fast static Astro site. You can host it anywhere, but it's optimized for **Vercel** or **GitHub Pages**.

- **Vercel**: connect your GitHub repository to a new Vercel project. No framework adapter needed — Vercel detects the `build` script automatically.

See step 6 in [`SETUP.md`](SETUP.md) for the full pre-launch checklist.

## Keystatic CMS (Step 7 — Optional)

Step 7 adds a browser-based admin interface at `yourdomain.com/keystatic` so you can write and publish articles without touching `.mdx` files. Keystatic commits directly to GitHub; Vercel picks up the push and rebuilds automatically.

This step switches the Astro output mode from `static` to `hybrid` and adds the `@astrojs/vercel` adapter — required because the admin UI and its OAuth callback routes must run as serverless functions. All existing blog pages stay statically pre-rendered and are unaffected.

### Setup after running Step 7

Before the admin UI is usable in production, complete these manual steps:

1. **Replace the repo placeholders** in `keystatic.config.ts`:
   ```ts
   repo: { owner: 'your-github-username', name: 'your-repo-name' }
   ```

2. **Create a GitHub OAuth App** at <https://github.com/settings/developers> → *OAuth Apps* → *New OAuth App*:
   - Homepage URL: `https://your-deployed-site.com`
   - Authorization callback URL: `https://your-deployed-site.com/api/keystatic/github/oauth/callback`

3. **Set environment variables** in Vercel (Project → Settings → Environment Variables):
   | Variable | Value |
   |---|---|
   | `KEYSTATIC_GITHUB_CLIENT_ID` | Client ID from the OAuth app |
   | `KEYSTATIC_GITHUB_CLIENT_SECRET` | Client secret from the OAuth app |
   | `KEYSTATIC_SECRET` | Random 32-byte hex string — run `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"` |

4. Redeploy. Visit `yourdomain.com/keystatic`, authenticate with GitHub, and start writing.

> The admin is gated by GitHub authentication — only users with write access to the repository can log in.

---

## Why This Approach?

- **Zero Drift**: `npm run build` is verified after every step — the project is always in a working state.
- **Rollback Points**: a git commit is created after each verified step, so any step can be undone with `git reset --hard`.
- **Reproducible**: Astro 4 is pinned explicitly; the same prompts produce the same blog regardless of when you run them.
- **Maintainable**: rules live in `CLAUDE.md`, making it easy to add new prompts without breaking the architecture.
- **Educational**: reading the prompts teaches you how to instruct LLMs effectively for complex engineering tasks.

---

*This repository is a template. Customize `CLAUDE.md` and the prompts to generate your own AI-built projects.*
