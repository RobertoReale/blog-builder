# Blog Builder

A framework to build a complete, production-ready personal blog using Astro 4, Tailwind CSS, and MDX — generated entirely through sequenced LLM prompts via Claude Code.

---

## Table of Contents

1. [How to Build the Blog](#1-how-to-build-the-blog)
2. [Running the Blog Locally](#2-running-the-blog-locally)
3. [Writing Articles](#3-writing-articles)
4. [Customizing Your Blog](#4-customizing-your-blog)
5. [Deploying to Vercel](#5-deploying-to-vercel)
6. [Using the Keystatic CMS](#6-using-the-keystatic-cms-step-7-only)
7. [Search](#7-search)
8. [Troubleshooting](#8-troubleshooting)
9. [How the Pipeline Works](#9-how-the-pipeline-works)
10. [What Could This Blog Do Better?](#10-what-could-this-blog-do-better-optional)

---

## 1. How to Build the Blog

Follow **[SETUP.md](SETUP.md)** for the full build instructions. Quick overview:

1. Install **Node.js 22 LTS** (or newer), **Git**, and **Claude Code**.
2. Run the interactive setup (configures colors, fonts, site title):
   - Windows: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` then `.\setup.ps1`
   - Linux/macOS: `chmod +x setup.sh run.sh && ./setup.sh`
3. Run the pipeline:
   - Windows: `.\run.ps1`
   - Linux/macOS: `./run.sh`
4. Follow the instructions printed at the end.

---

## 2. Running the Blog Locally

### Without Keystatic (Steps 0–6)

```bash
npm run dev
```
Open **http://localhost:4321**. Hot-reload is active — edits to pages, components, and articles reflect instantly.

### With Keystatic (Step 7 included)

After Step 7 installs the Vercel adapter, the dev server may have issues on
**Node.js 22+**. Try in order:

**Option A — standard dev server (try first):**
```bash
npm run dev
# open http://localhost:4321
```

**Option B — build-based preview (always works, search included):**
```bash
npm run dev:build
# open http://localhost:4321
# takes ~20s to build, then serves the full production output
```

> **Note on search**: the search page shows "Search is available in the built
> site" when using `npm run dev`. Run `npm run dev:build` (or `npm run build`)
> to get a fully working search.

---

## 3. Writing Articles

Articles are MDX files in `src/content/articles/`. Create one file per article.

### Filename

The filename becomes the URL slug:
- `src/content/articles/my-first-post.mdx` → `/article/my-first-post`

### Frontmatter reference

```yaml
---
title: "Your Article Title"
date: 2025-06-03          # YYYY-MM-DD, no quotes needed
description: "A short summary shown in article lists and search results."
tags: ["thinking", "writing"]     # pick from the predefined list in keystatic.config.ts
status: published          # or: draft (drafts are hidden from lists)
language: en               # or: it — sets the HTML lang attribute
series: "My Series Name"   # optional — groups articles into a series
part: 1                    # optional — order within the series
sources:                   # optional — shown as a numbered reference list
  - label: "Book Title by Author"
    href: "https://example.com"
  - label: "Wikipedia — Topic"
    href: "https://en.wikipedia.org/wiki/Topic"
# coverImage: "public/images/my-image.jpg"  # optional, omit if not used
---
```

> **Important**: If you don't have a cover image, **omit the `coverImage` line entirely**.
> Writing `coverImage:` with no value causes a Zod validation error.

### Article body

Write in MDX (Markdown with JSX). All standard Markdown works plus these custom components:

#### `<Callout>`

Highlighted box for important notes or warnings:

```mdx
<Callout type="info" title="Did you know?">
  This is an informational callout. Use it for tips and context.
</Callout>

<Callout type="warning" title="Watch out">
  Use this for warnings or things that could go wrong.
</Callout>
```

#### `<ImageWithCaption>`

```mdx
<ImageWithCaption
  src="/images/my-photo.jpg"
  alt="A descriptive alt text"
  caption="This caption appears below the image."
  size="full"   <!-- or: "half" for 50% width -->
/>
```

Place images in `public/images/` and reference them with `/images/filename.jpg`.

#### `<Sources>`

Sources listed in the frontmatter are **automatically rendered** at the bottom of every article page — you don't need to add anything to the MDX body.

If you want to place the source list at a specific position *inside* the article body instead, you can call it explicitly:

```mdx
<Sources sources={frontmatter.sources} />
```

If `sources` is empty, nothing is rendered either way.

### Publishing an article

Set `status: published` in the frontmatter. Only published articles appear in
lists and search results. Drafts are accessible via direct URL only.

### Editing existing articles

Edit the `.mdx` file directly — the dev server hot-reloads automatically.

---

## 4. Customizing Your Blog

### Site title, description, author, URL

Edit **`src/config.ts`**:

```ts
export const SITE = {
  title: "Your Blog Title",
  description: "A one-line description of your blog.",
  url: "https://yourdomain.com",   // no trailing slash
  author: "Your Name",
};
```

This is the single source of truth for all site-level data: nav, footer, meta tags, RSS feed, sitemap.

### Colors

Open **`src/styles/global.css`**. You'll find CSS custom properties for both light and dark mode:

```css
:root {
  --color-bg:      #FFFFFF;   /* page background */
  --color-text:    #111827;   /* primary text */
  --color-muted:   #6B7280;   /* secondary text, dates, metadata */
  --color-accent:  #2563EB;   /* links, active tags, progress bar */
  --color-border:  #E5E7EB;   /* dividers, card outlines */
  --color-surface: #F9FAFB;   /* callout backgrounds, code blocks */
}

[data-theme="dark"] {
  --color-bg:      #111827;
  --color-text:    #F3F4F6;
  --color-muted:   #9CA3AF;
  --color-accent:  #3B82F6;
  --color-border:  #374151;
  --color-surface: #1F2937;
}
```

Change any value — the whole design updates automatically. Never hardcode hex colors elsewhere.

### Fonts

Fonts are self-hosted via [@fontsource](https://fontsource.org) — no Google CDN dependency, no external requests at page load. The default setup uses `@fontsource/lora` (headings) and `@fontsource/dm-sans` (body).

To change fonts:

1. Find your font on [fontsource.org](https://fontsource.org) and note the package name.
2. Install it: `npm install @fontsource/your-font`
3. Replace the `@import` lines at the top of `src/styles/global.css`.
4. Update the `font-family` references in the same file.

### Navigation links

The nav is in `src/layouts/BaseLayout.astro`. It contains links to `/articles`, `/series`, `/about`, `/search`. The current page is automatically highlighted. Add, remove, or rename links there.

### About and Now pages

Edit `src/pages/about.astro` and `src/pages/now.astro` — they contain placeholder content with `// TODO` comments.

---

## 5. Deploying to Vercel

### Without Keystatic (Steps 0–6: fully static)

1. Push your repository to GitHub.
2. Go to [vercel.com](https://vercel.com) → **Add New Project** → import your repo.
3. Vercel auto-detects Astro. Leave all settings at default.
4. Go to **Settings** → **General** → **Node.js Version** and set it to **22.x**. Click **Save**.
5. Click **Deploy** (or **Redeploy** if the first deploy already ran).

Your blog is live. Every `git push` triggers an automatic redeploy.

> Before going live: update `src/config.ts` with your real URL — the robots.txt is generated dynamically from that file.

### With Keystatic (Step 7: hybrid)

Same deployment steps, plus the Keystatic CMS setup in section 6 below.

### Choosing your Vercel URL

When Vercel first deploys your project it assigns an auto-generated URL like `blog-6jcd.vercel.app`. You can rename it for free in 30 seconds:

1. Go to your Vercel project → **Settings** → **Domains**
2. Click **Edit** next to the auto-generated URL
3. Choose something readable, e.g. `your-name.vercel.app` or `my-blog.vercel.app`

> **After renaming**: update `src/config.ts` with the new URL, then commit and push. If you've set up Keystatic, also update the **Homepage URL** and **Callback URL** in your GitHub App (`github.com/settings/developers`).

**Custom domain** (e.g. `www.yourname.com`): on the same Domains page, click **Add**. Vercel handles SSL automatically.

> **Pro tip — know your URL before running the pipeline**: import the repo into Vercel first (Vercel deploys even an empty/broken project and shows the assigned URL immediately), rename the domain in Settings, then enter that URL in `setup.ps1` / `setup.sh`. That way `src/config.ts` is correct from step 0.

---

## 6. Using the Keystatic CMS (Step 7 only)

Keystatic gives you a browser-based editor at `/keystatic`.

### Two modes — automatic based on environment

The `keystatic.config.ts` generated by Step 7 uses **two modes automatically**:

| Mode | When | How it works |
|---|---|---|
| **Local** (`kind: 'local'`) | `npm run dev` | Writes `.mdx` files directly to disk. No GitHub, no OAuth. |
| **GitHub** (`kind: 'github'`) | Deployed on Vercel | Commits via GitHub OAuth. Vercel rebuilds automatically. |

This means you can write articles from the browser **right now**, locally:

```bash
npm run dev
# open http://localhost:4321/keystatic
```

No login needed. Click **Articles** → **Create** → write → **Save**.
The `.mdx` file appears in `src/content/articles/` on your disk instantly.

> **Tip**: local mode is perfect for drafting. When you're ready to publish,
> push to GitHub and deploy — from then on, the GitHub mode kicks in
> and you can write from the live site.

### Setting up GitHub mode (for the deployed site)

Complete these steps after deploying to Vercel:

**Step A — Update the repo placeholders** in `keystatic.config.ts`:

```ts
owner: 'your-github-username',   // ← replace
name: 'your-repo-name',          // ← replace
```

Commit and push.

**Step B — Create a GitHub App**

Go to [github.com/settings/developers](https://github.com/settings/developers) → **GitHub Apps** → **New GitHub App**:
- **GitHub App name**: `Blog Admin`
- **Homepage URL**: `https://yourdomain.com`
- **Callback URL**: `https://yourdomain.com/api/keystatic/github/oauth/callback`
- **Webhook**: Uncheck "Active" (Keystatic does not use webhooks)
- **Permissions**: Under `Repository permissions`, set `Contents` to **Read and write**
- **User authorization**: Check "Request user authorization (OAuth) during installation"

After saving, copy the **Client ID** and generate a new **Client Secret**. Finally, click **Install App** in the left sidebar to install it on your blog repository.

**Step C — Add environment variables in Vercel**

Go to your Vercel project → **Settings** → **Environment Variables**:

| Variable | Value |
|---|---|
| `KEYSTATIC_GITHUB_CLIENT_ID` | Client ID from Step B |
| `KEYSTATIC_GITHUB_CLIENT_SECRET` | Client Secret from Step B |
| `KEYSTATIC_SECRET` | Random 64-char hex — generate with:<br>`node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"` |

**Step D — Redeploy** and visit `https://yourdomain.com/keystatic`.

Log in with GitHub and start writing from anywhere in the world.

> **Access control**: only GitHub accounts with **write access** to the repository
> can log into the admin. Add collaborators in your GitHub repo settings.

### Writing articles with Keystatic (both modes)

1. Go to `/keystatic` (locally: `http://localhost:4321/keystatic`)
2. Click **Articles** → **Create**
3. Fill in: title, description, tags, status, body (rich MDX editor)
4. Click **Save** (local: writes to disk) or **Create** (GitHub: commits to repo)
5. Vercel rebuilds (takes ~30s), then the article is live

---

## 7. Search

The search index is built as part of `npm run build` (Pagefind runs automatically after the Astro build).

- **In development** (`npm run dev`): the search page shows a message saying search is only available in the built site.
- **With `npm run dev:build`**: full search works, including search index.
- **In production**: search works out of the box after every Vercel deploy.

To use keyboard shortcut: press **`/`** anywhere on the blog (not while typing in a field) to jump to the search page.

---

## 8. Troubleshooting

### `npm run dev` shows a blank page or 500 error

**Cause**: Node.js 22–24 + `@astrojs/vercel` adapter compatibility issue.
The adapter bundles its own esbuild version that can fail to parse certain
Astro template patterns (including inline `<script>` tags with TypeScript
generics like `querySelectorAll<HTMLElement>`) when running in hybrid mode.
The production build is not affected.

**Fix A** — Check that `astro.config.mjs` has this Vite setting (added by Step 7):
```js
vite: {
  esbuild: {
    target: 'es2022',
  },
},
```
If missing, add it and restart the dev server.

**Fix B** — Use the build-based preview instead:
```bash
npm run dev:build
# open http://localhost:4321
```

**Fix C** (advanced) — Move complex TypeScript out of inline `<script>` tags
into separate `.ts` files. This bypasses the esbuild parsing pipeline entirely.
See [GitHub issue discussion](https://github.com/withastro/astro/issues) for details.

### Search returns no results

**Cause**: The Pagefind index hasn't been built.

**Fix**: Run `npm run build` (not just `npm run build:astro`). The full build script runs Pagefind after the Astro build.

### Vercel build warns about Node.js version or deploy fails with runtime error

**Cause**: Vercel defaults to Node 20, but `@astrojs/react` (used by Keystatic) requires Node ≥22.

**Fix**:
1. In your Vercel project → **Settings** → **General** → **Node.js Version**, select **22.x** and click **Save**.
2. Trigger a redeploy (**Deployments** → `...` → **Redeploy**).

> The pipeline sets `"engines": { "node": ">=22" }` in `package.json` automatically (Step 0), but Vercel's dashboard setting takes precedence and must be updated manually.

### Port 4321 is already in use

Another process is using that port. Either kill it or use a different port:
```bash
npm run dev -- --port 4322
```

### Article not showing up in lists

Check:
1. `status: published` is set in the frontmatter (not `draft`).
2. The file is in `src/content/articles/` with a `.mdx` extension.
3. Run `npm run build` to catch any Zod schema validation errors (they're shown clearly in the build output).

### Build fails with "coverImage" error

`coverImage:` is written in the frontmatter but has no value (YAML parses this as `null`). Either:
- Add a real value: `coverImage: "public/images/my-image.jpg"`
- Or remove the line entirely. Never write `coverImage:` with nothing after it.

### Keystatic: "Not authenticated" or OAuth error

1. Verify the `KEYSTATIC_GITHUB_CLIENT_ID` and `KEYSTATIC_GITHUB_CLIENT_SECRET` are set correctly in Vercel.
2. Verify the callback URL in the GitHub App is exactly `https://yourdomain.com/api/keystatic/github/oauth/callback`.
3. Ensure `KEYSTATIC_SECRET` is set and is at least 32 bytes of random hex.
4. Trigger a fresh Vercel deploy after adding/changing env variables.

### Keystatic: Red error "Unhandled type mdxjsEsm" when opening example articles

**Cause**: The AI-generated example articles contain explicit component imports (`import QA from ...`) at the top. Keystatic's visual editor currently does not support parsing explicit ESM imports for Astro components, so it crashes when trying to open these specific files.
**Fix**: Because they crash on load, you cannot delete them directly from the Keystatic UI. Instead, delete the `.mdx` files directly from `src/content/articles/` via VS Code and commit/push the deletion. When you create *new* articles via Keystatic, they won't contain these explicit imports and the editor will work perfectly.

### Long-term compatibility

The blog is designed to be stable over time. Once deployed, the static HTML output runs forever — only the build tooling ages. Here is the current status of each dependency (updated June 2026):

| Dependency | Risk | Notes |
|---|---|---|
| **Astro 4** | Medium | Astro 4 is now legacy — the current version is Astro 6. The blog works with Astro 4 and pinned dependencies. If you need to upgrade, see the migration note below. |
| **Vercel static hosting** | Very low | Static files have no runtime — no serverless functions to break unless you use Keystatic. |
| **Fonts (@fontsource)** | Very low | Self-hosted in your `node_modules` — no external CDN. Fonts load even if fontsource.org goes down. |
| **Tailwind CSS / @astrojs/tailwind** | Medium | `@astrojs/tailwind` is deprecated in Astro 5+. With pinned Astro 4 it works fine. Future migration to Astro 5+ requires switching to `@tailwindcss/vite` plugin. |
| **Keystatic CMS** | High | Maintenance has slowed significantly in 2026. Works with Astro 5 but NOT with Astro 6. If Keystatic causes problems, the blog works perfectly without it — articles can always be written as `.mdx` files directly. |
| **Pagefind (search)** | Very low | Build-time only, actively maintained (v1.5.2 as of April 2026). No runtime dependency. |
| **Node.js** | Low | The pipeline uses `"engines": { "node": ">=20" }`. Node 22 LTS (EOL April 2027) is recommended. Node 20 reached EOL on April 30, 2026. |

**If a future `npm run build` fails** after a dependency update, the fastest fix is to pin the previously working versions in `package.json` and re-run the build. The pipeline prompts instruct Claude to search for current best practices at execution time, so re-running a prompt step will always produce code compatible with the then-current package versions.

**Future migration to Astro 5+**: When you're ready to upgrade, the key changes are: (1) Content Collections must use the Content Layer API with `glob()` loader, (2) `src/content/config.ts` moves to `src/content.config.ts`, (3) `entry.slug` becomes `entry.id` and `entry.render()` becomes `render(entry)`, (4) `@astrojs/tailwind` is replaced by `@tailwindcss/vite` plugin, (5) `output: 'hybrid'` is replaced by `output: 'static'` with `export const prerender = false` on server-rendered routes. Run `npx @astrojs/upgrade` for guided migration.

### A pipeline step fails

The script stops and tells you which step failed. To fix:
1. Open the folder in VS Code: `code .`
2. Run `claude` (interactive mode) and describe the error.
3. Once `npm run build` passes manually, resume: `.\run.ps1 -StartStep N`

To roll back to the previous working state:
```bash
git log --oneline   # find the last good commit
git reset --hard HEAD~1
```

---

## 9. How the Pipeline Works

Instead of generating an entire codebase in one massive prompt (which causes
context overflow and hallucinations), this project uses a **sequenced prompt
architecture**:

> Each prompt runs in a fresh Claude Code session with a clean context window.
> Claude reads `CLAUDE.md` (the project rules) + the feature instructions,
> then reads the existing code on disk. Every prompt instructs Claude to use its
> **web search tools** to verify the latest best practices and breaking changes
> for the technologies involved in that step — and to search online if it hits
> a bug it cannot resolve from the code alone. After each step, the script runs
> `npm run build` and `npm run test:unit` to verify correctness. If the build
> breaks, the pipeline stops immediately.

### Design principles

**Context isolation per feature.** Each feature runs in a completely separate Claude Code session. This isn't just about fitting within the context window — it also prevents the reasoning from earlier steps from biasing later ones. Every session sees exactly two things: the project rules (`CLAUDE.md`) and the current code on disk. Nothing else leaks through.

**`CLAUDE.md` as cross-session memory.** Claude Code has no memory between sessions. Rather than repeating architectural decisions in every prompt, a single file encodes all of them: color variables, TypeScript constraints, component interfaces, page render order. The setup script writes the user's actual values into it once; every subsequent session inherits them automatically without any extra configuration.

**Build-gated commits.** The pipeline only creates a git commit after `npm run build` succeeds. This borrows a principle from CI/CD: AI-generated code must never compound on a broken state. Each commit is a verified snapshot. Rolling back to a known-good state is always one `git reset --hard HEAD~1` away.

**Prompts as versioned specifications.** The prompt files are not ad-hoc questions — they are precise, reproducible specifications with explicit constraints and a checklist at the end. The same prompts on the same codebase produce the same result. They can be re-run, modified, and versioned like any other source file.

**Web search baked into every prompt.** Each prompt instructs Claude to search the web for current documentation and known issues *before* writing any code — and to search again if it hits a bug it can't solve from the code alone. Package APIs change, adapters add breaking releases, community patterns evolve. A prompt that relies only on Claude's training data has a shelf life; a prompt that fetches current docs doesn't.

**Two final quality gates.** After all features are built, Step 8 runs the full Playwright E2E suite and fixes any cross-feature regressions. Step 9 then performs a dedicated UI/UX audit: it verifies that no raw hex colors leaked outside the design system, that every interactive element is accessible (ARIA labels, focus styles, semantic HTML), that dark mode is complete, and that the example article has enough structure for all reading-UX features to render correctly. It also cross-checks `src/config.ts`, the fontsource imports, and the CSS color variables against the values the user entered at setup time — catching the common case where Step 0 generated placeholder defaults instead of the real values. These two steps catch the classes of bugs that unit tests miss: visual regressions, accessibility gaps, configuration drift, and design inconsistencies.

---

| Step | Prompt | What it builds |
|---|---|---|
| 0 | `prompt_blog_00_foundation.txt` | Layout, dark mode, MDX, example article |
| 1 | `prompt_blog_01_testing.txt` | Vitest + Playwright test suite |
| 2 | `prompt_blog_02_seo.txt` | RSS, sitemap, robots.txt, JSON-LD, 404 |
| 3 | `prompt_blog_03_reading_ux.txt` | Progress bar, TOC, back-to-top, share button |
| 4 | `prompt_blog_04_search.txt` | Pagefind full-text search |
| 5 | `prompt_blog_05_series.txt` | Article series grouping |
| 6 | `prompt_blog_06_related.txt` | Related articles recommendation |
| 7 | `prompt_blog_07_keystatic.txt` | Keystatic CMS (browser editor, GitHub mode) |
| 8 | `prompt_blog_08_e2e_check.txt` | E2E integration check, fix any cross-feature failures |
| 9 | `prompt_blog_09_ui_review.txt` | UI/UX & design audit — accessibility, consistency, polish, configuration completeness |
| — | `prompt_blog_10_future_features.txt` | **Optional** — web-researched report of missing features and future improvements (no code changes) |

After every successful step, a git commit is created as a rollback point.

### Token usage

The pipeline prints a running token counter after each step:
```
Tokens this step: 52,410 in / 4,830 out   |   Total so far: 148,200 in / 13,500 out
```

- **Claude Max plan**: fits comfortably within typical monthly usage.
- **Claude Pro plan**: limits may be hit mid-pipeline. Press CTRL+C, wait for the limit to reset, then resume: `.\run.ps1 -StartStep N`

### Project structure (CLAUDE.md rules)

All architectural decisions are documented in `CLAUDE.md`. Claude Code reads this file at the start of every session. It defines:
- Color variables (no hardcoded hex anywhere)
- TypeScript strict mode (no `any`)
- Article frontmatter schema
- Component interfaces
- Page render order

Edit `CLAUDE.md` if you want to add new architectural rules or change defaults before running additional prompts.

---

---

## 10. What Could This Blog Do Better? (Optional)

Once the pipeline is complete and your blog is live, you can run one final
optional prompt to get an honest, web-researched assessment of what your blog
might be missing compared to the best personal blogs on the web today.

**When to use it:**

> "My blog is built and deployed. What features should I consider adding in the future?"

**How to run it:**

Open a new Claude Code session in your blog folder and paste the contents of
`prompt_blog_10_future_features.txt`.

Claude will:
1. Search the web for what makes a great personal blog in the current year
2. Compare the results against everything already built (read from `CLAUDE.md`)
3. Produce a structured report organized into three tiers: quick wins, larger
   investments, and things worth knowing about but probably not for this blog

This prompt produces a report only — it makes no changes to your code.
Use the findings as a backlog: pick one item, write a focused prompt for it
(in the style of the existing pipeline prompts), and run it as a new step.

---

*This repository is a template. The prompts are designed to be re-run, extended, and customized. Read `CLAUDE.md` before modifying any prompt.*
