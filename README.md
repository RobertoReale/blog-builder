# Blog Builder

A framework to build a complete, production-ready personal blog using Astro, Tailwind CSS, and MDX — generated entirely through sequenced LLM prompts via Claude Code.

## Live example

This pipeline generated [RobertoReale/blog](https://github.com/RobertoReale/blog) — 
browse the source or visit the [live site](https://blog-roberto-reale.vercel.app).

---

## Table of Contents

1. [How to Build the Blog](#1-how-to-build-the-blog)
2. [Running the Blog Locally](#2-running-the-blog-locally)
3. [Writing Articles](#3-writing-articles)
4. [Customizing Your Blog](#4-customizing-your-blog)
5. [Deploying to Vercel](#5-deploying-to-vercel)
6. [Using the Keystatic CMS](#6-using-the-keystatic-cms-step-7-only)
7. [Search](#7-search)
8. [Analytics (Optional)](#8-analytics-optional)
9. [Comments (Optional)](#9-comments-optional)
10. [Newsletter (Optional)](#10-newsletter-optional)
11. [Troubleshooting](#11-troubleshooting)
12. [How the Pipeline Works](#12-how-the-pipeline-works)
13. [What Could This Blog Do Better?](#13-what-could-this-blog-do-better-optional)

---

## 1. How to Build the Blog

> **Future-proofing tip**: Web technologies evolve rapidly. Before running the pipeline, we highly recommend downloading this repository and asking your preferred LLM (like Gemini, Claude, or ChatGPT) to review it: *"Are these setup scripts and prompts still up-to-date with current Astro versions and best practices? Please update them if necessary."* This ensures the blog builder will continue to work perfectly even years from now.

Follow **[SETUP.md](SETUP.md)** for the full build instructions. Quick overview:

1. Install the current **Node.js LTS** release (or newer), **Git**, and **Claude Code**.
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
some Node.js versions. Try in order:

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
date: YYYY-MM-DD           # ISO date format, no quotes needed
description: "A short summary shown in article lists and search results."
tags: ["thinking", "writing"]     # free-form — add any tags you want
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
  size="full"
/>
```

Use `size="half"` for a 50% wide image (centered). Use `size="full"` (default) for full content width.

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

### Favicon / Logo

By default, the blog uses a generic emoji (📝) as a favicon so it looks good out of the box. 
To use your own logo:
1. Create a `favicon.svg`, `favicon.ico`, or `favicon.png` file with your logo.
2. Place it in the `public/` directory (replacing any existing favicon if present).
3. Update `src/layouts/BaseLayout.astro` to point `<link rel="icon" ...>` to your new file (e.g. `href="/favicon.svg"`).

### Navigation links

The nav is in `src/layouts/BaseLayout.astro`. It contains links to `/articles`, `/series`, `/about`, `/search`. The current page is automatically highlighted. Add, remove, or rename links there.

### About and Now pages

Edit `src/pages/about.astro` and `src/pages/now.astro` — they contain placeholder content with `// TODO` comments.

---

## 5. Deploying to Vercel

### Without Keystatic (Steps 0–6: fully static)

> **Accounts needed**: a free [GitHub](https://github.com) account and a free [Vercel](https://vercel.com) account.

**If your blog is not on GitHub yet** (you skipped the GitHub step during setup):
1. Create a new repository at [github.com/new](https://github.com/new) — leave it empty (no README, no .gitignore).
2. In your project folder, run:
   ```bash
   git remote add origin https://github.com/your-username/your-repo.git
   git push -u origin master
   ```
   Replace `your-username` and `your-repo` with your actual GitHub username and repository name.

**Then deploy:**

1. Push your repository to GitHub (done above if not already).
2. Go to [vercel.com](https://vercel.com) → **Add New Project** → import your repo.
3. Vercel auto-detects Astro. Leave all settings at default.
4. Go to **Settings** → **General** → **Node.js Version**. Open `package.json` in your project folder, find the `"engines"` field (e.g. `"node": ">=22"`), and select the matching version in Vercel (e.g. **22.x**). Click **Save**.
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

## 8. Analytics (Optional)

Analytics is configured during setup (`setup.ps1` / `setup.sh`). If you chose a
provider, the pipeline automatically runs Step 10 to add the tracking script.
If you chose "None" during setup, skip this section.

> **Changing your choice after setup**: Edit `CLAUDE.md`, find the `ANALYTICS` section,
> and change the `Provider:` line to `umami`, `cloudflare`, `vercel`, or `none`.
> Then run: `.\run.ps1 -StartStep 10` (Windows) or `./run.sh -s 10` (Linux/macOS).

### Choosing a provider

| Provider | Free tier | Privacy | Setup effort |
|---|---|---|---|
| **Umami Cloud** *(recommended)* | 100k events/month, 3 sites | Cookie-free, GDPR-compliant | ~10 min — account + copy website ID |
| **Cloudflare Web Analytics** | Unlimited events | Cookie-free, GDPR-compliant | ~10 min — account + copy token |
| **Vercel Analytics** | 2,500 events/month | Privacy-focused | ~2 min — enable in Vercel dashboard |

All three are cookie-free and GDPR-compliant by default. Umami is the best choice for
long-term flexibility: it's open-source, can be self-hosted, and has the most detailed
metrics (time on page, bounce rate, UTM tracking, custom events).

### Umami Cloud — connecting your account

After the pipeline adds the tracking script, replace the placeholder with your real website ID:

1. Create a free account at [cloud.umami.is](https://cloud.umami.is)
2. Add your site: **Settings** → **Websites** → **Add Website** → enter your blog URL
3. Copy the **Website ID** shown after adding the site
4. Open `src/layouts/BaseLayout.astro` and find:
   ```html
   data-website-id="REPLACE_WITH_YOUR_UMAMI_WEBSITE_ID"
   ```
5. Replace `REPLACE_WITH_YOUR_UMAMI_WEBSITE_ID` with your real Website ID
6. Commit and push — Vercel redeploys automatically

Dashboard: [cloud.umami.is](https://cloud.umami.is) → **Websites** → your blog

### Cloudflare Web Analytics — connecting your account

After the pipeline adds the tracking script, replace the placeholder with your real beacon token:

1. Create a free Cloudflare account at [cloudflare.com](https://cloudflare.com)
2. Go to **Analytics & Logs** → **Web Analytics** → **Add a Site**
3. Enter your blog domain — Cloudflare shows a script snippet with your token
4. Copy the token value from `data-cf-beacon='{"token": "..."}'`
5. Open `src/layouts/BaseLayout.astro` and find:
   ```html
   data-cf-beacon='{"token": "REPLACE_WITH_YOUR_CF_BEACON_TOKEN"}'
   ```
6. Replace `REPLACE_WITH_YOUR_CF_BEACON_TOKEN` with your real token
7. Commit and push

> **Note**: you do NOT need to change your DNS nameservers for Web Analytics to work.
> The DNS change is only needed for Cloudflare's full CDN/proxy suite, which is optional.

Dashboard: Cloudflare → **Analytics & Logs** → **Web Analytics** → your site

### Vercel Analytics — enabling the dashboard

After the pipeline installs `@vercel/analytics` and adds `<Analytics />` to the layout:

1. In your Vercel project dashboard, go to the **Analytics** tab in the top nav
2. Click **Enable** — that's all. No further configuration needed.
3. Vercel starts collecting data from the next deploy onward.

Dashboard: Vercel project → **Analytics** tab

> **Free tier**: 2,500 events/month, where each page view is one event.
> A typical personal blog stays well within this limit.

---

## 9. Comments (Optional)

A comments section lets readers respond directly to your articles using their GitHub account.
Configured during setup (`setup.ps1` / `setup.sh`). If you chose "None", skip this section.

> **Changing your choice after setup**: Edit `CLAUDE.md`, find the `COMMENTS` section,
> and change the `Provider:` line to `giscus`, `utterances`, or `none`.
> Then run: `.\run.ps1 -StartStep 11` (Windows) or `./run.sh -s 11` (Linux/macOS).
> Note: if analytics was not configured, comments will be step 10, not 11 — check `.\run.ps1 -DryRun`.

### Choosing a provider

| Provider | Backend | Privacy | Features |
|---|---|---|---|
| **Giscus** *(recommended)* | GitHub Discussions | No tracking, no ads | Reactions, edit comments, nested replies |
| **Utterances** | GitHub Issues | No tracking, no ads | Simpler, fewer features |

Both require visitors to have a GitHub account to leave a comment.

### Giscus — connecting your account

After the pipeline adds the widget, replace the placeholders with your real repository details:

1. Enable GitHub Discussions on your blog repository: **Settings** → **Features** → check **Discussions**
2. Go to [giscus.app](https://giscus.app), enter your repository, configure the options
3. Giscus generates a `<script>` snippet — copy the attribute values from it
4. Open `src/components/ui/GiscusComments.astro` and replace:
   - `REPLACE_WITH_OWNER/REPO` → your GitHub `username/repo`
   - `REPLACE_WITH_REPO_ID` → from the generated snippet
   - `REPLACE_WITH_CATEGORY_NAME` → e.g., `General` or `Comments`
   - `REPLACE_WITH_CATEGORY_ID` → from the generated snippet
5. Commit and push

> **Access**: readers must have a GitHub account. The discussion threads live in your
> repository's Discussions tab — you can moderate from there.

### Utterances — connecting your account

After the pipeline adds the widget, replace the placeholder:

1. Install the [Utterances app](https://github.com/apps/utterances) on your repository
2. Open `src/components/ui/UtterancesComments.astro` and replace `REPLACE_WITH_OWNER/REPO`
   with your GitHub `username/repo`
3. Commit and push

---

## 10. Newsletter (Optional)

A newsletter form lets readers subscribe to receive new articles by email.
Configured during setup. If you chose "None", skip this section.

> **Changing your choice after setup**: Edit `CLAUDE.md`, find the `NEWSLETTER` section,
> and change the `Provider:` line to `buttondown`, `substack`, `kit`, or `none`.
> Then run the appropriate step number (check `.\run.ps1 -DryRun` to confirm).

### Choosing a provider

| Provider | Free tier | Privacy | Notes |
|---|---|---|---|
| **Buttondown** *(recommended)* | 100 subscribers | Privacy-first, no tracking | Simple, clean, developer-friendly |
| **Substack** | Unlimited free | Minimal tracking | Popular; takes a cut on paid plans |
| **Kit** (formerly ConvertKit) | 10,000 subscribers | Some tracking | Feature-rich; strong automation tools |

### Buttondown — connecting your account

After the pipeline adds the signup form, replace the placeholder:

1. Create a free account at [buttondown.email](https://buttondown.email)
2. Your username is the part after `buttondown.email/` on your public newsletter page
3. Open `src/components/ui/NewsletterForm.astro` and replace `REPLACE_WITH_YOUR_USERNAME`
   with your Buttondown username
4. Commit and push

### Substack — connecting your account

1. Create a Substack publication at [substack.com](https://substack.com)
2. Your Substack subdomain is `yourname.substack.com`
3. Open `src/components/ui/NewsletterForm.astro` and replace `REPLACE_WITH_YOUR_SUBSTACK`
   with your Substack subdomain (just the name, not `.substack.com`)
4. Commit and push

### Kit — connecting your account

1. Create a free account at [kit.com](https://kit.com)
2. Create a **Form** in Kit (**Grow** → **Landing Pages & Forms**)
3. In the form settings, find the Form ID (visible in the embed code URL)
4. Open `src/components/ui/NewsletterForm.astro` and replace `REPLACE_WITH_YOUR_FORM_ID`
5. Commit and push

---

## 11. Troubleshooting

### `npm run dev` shows a blank page, 500 error, or "Expected } but found :"

**Cause**: Most likely an `@astrojs/react` version mismatch. Major versions of
`@astrojs/react` must match the Astro major version. npm v7+ auto-installs the
latest release unless explicitly pinned, so a fresh `npm install` can pull in
a mismatched version without any warning.

**Fix A** — Check the installed versions and re-pin if they diverge:
```bash
npm list @astrojs/react   # note the major version
npm list astro             # verify the Astro major version matches
# if the majors differ, re-pin to match (replace N with the Astro major):
npm install @astrojs/react@^N
```
Restart the dev server after re-pinning.

**Fix B** — Use the build-based preview (always works, search included):
```bash
npm run dev:build
# open http://localhost:4321
# takes ~20s to build, then serves the full production output
```

### Search returns no results

**Cause**: The Pagefind index hasn't been built.

**Fix**: Run `npm run build` (not just `npm run build:astro`). The full build script runs Pagefind after the Astro build.

### Vercel build warns about Node.js version or deploy fails with runtime error

**Cause**: Vercel may use an older Node.js version by default than what the installed packages require.

**Fix**:
1. Check the `"engines"` field in `package.json` to see the minimum Node.js version required (set by the pipeline at Step 0).
2. In your Vercel project → **Settings** → **General** → **Node.js Version**, select a version that meets the `engines` requirement and click **Save**.
3. Trigger a redeploy (**Deployments** → `...` → **Redeploy**).

> The `"engines"` field is set automatically by the pipeline (Step 0) based on the active LTS at build time, but Vercel's dashboard setting takes precedence and must be updated manually.

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

### Keystatic: Red error "Unhandled type mdxjsEsm" when opening an article

**Cause**: The `.mdx` file contains an explicit ESM import at the top (e.g. `import SomeComponent from '../../components/...'`). Keystatic's visual editor does not support parsing explicit component imports inside `.mdx` files and crashes when trying to open them.
**Fix**: Because the file crashes on load, you cannot delete it from the Keystatic UI. Instead, delete the `.mdx` file directly from `src/content/articles/` via VS Code and commit/push the deletion. Articles created through Keystatic will not have explicit imports and the editor will work correctly.

### Long-term compatibility

The blog is designed to be stable over time. Once deployed, the static HTML output runs forever — only the build tooling ages.

| Dependency | Risk | Notes |
|---|---|---|
| **Astro** | Medium | Astro introduces breaking changes between major versions. The pipeline detects the current major at build time and adapts. To upgrade to a newer major, run `npx @astrojs/upgrade` and follow the official migration guide. |
| **Vercel static hosting** | Very low | Static files have no runtime — no serverless functions to break unless you use Keystatic. |
| **Fonts (@fontsource)** | Very low | Self-hosted in your `node_modules` — no external CDN. Fonts load even if fontsource.org goes down. |
| **Tailwind CSS** | Low | The Tailwind integration method may change between Astro major versions (e.g. integration plugin vs. Vite plugin). Check the Astro docs for the recommended approach when upgrading. |
| **Keystatic CMS** | Medium | Keystatic maintains its own compatibility with Astro. Before upgrading Astro, check the Keystatic changelog. If Keystatic causes problems, the blog works perfectly without it — articles can always be written as `.mdx` files directly. |
| **Pagefind (search)** | Very low | Build-time only, actively maintained. No runtime dependency. |
| **Node.js** | Low | The pipeline detects the current active LTS at build time and sets `"engines"` in `package.json` accordingly. Always use the active LTS — avoid end-of-life versions as they no longer receive security patches. |

**If a future `npm run build` fails** after a dependency update, the fastest fix is to pin the previously working versions in `package.json` and re-run the build. The pipeline prompts instruct Claude to search for current best practices at execution time, so re-running a prompt step will always produce code compatible with the then-current package versions.

**Migrating to a new Astro major version**: Run `npx @astrojs/upgrade` for automated, guided migration. Check the [Astro upgrade guides](https://docs.astro.build/en/guides/upgrade-to/) for version-specific manual steps. Common changes between majors include updates to the Content Collections API, the Tailwind integration method, and hybrid/static output configuration.

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

## 12. How the Pipeline Works

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

**Two final quality gates.** After all features are built, Step 8 runs the full Playwright E2E suite and fixes any cross-feature regressions. Step 9 then performs a dedicated UI/UX audit: it verifies that no raw hex colors leaked outside the design system, that every interactive element is accessible (ARIA labels, focus styles, semantic HTML), that the blog is fully usable on mobile phones (touch targets, responsive nav, overflow handling, Web Share API, iOS zoom prevention), that dark mode is complete, and that the example article has enough structure for all reading-UX features to render correctly. It also cross-checks `src/config.ts`, the fontsource imports, and the CSS color variables against the values the user entered at setup time — catching the common case where Step 0 generated placeholder defaults instead of the real values. These two steps catch the classes of bugs that unit tests miss: visual regressions, accessibility gaps, mobile UX failures, configuration drift, and design inconsistencies.

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
| 9 | `prompt_blog_09_ui_review.txt` | UI/UX & design audit — accessibility, mobile responsiveness, consistency, polish, configuration completeness |
| 10 | `prompt_blog_10_analytics.txt` | **Optional** — analytics tracking; only runs if configured during setup |
| 11 | `prompt_blog_11_comments.txt` | **Optional** — comments section (Giscus or Utterances); only runs if configured during setup |
| 12 | `prompt_blog_12_newsletter.txt` | **Optional** — newsletter signup form; only runs if configured during setup |
| — | `prompt_blog_13_future_features.txt` | **Optional** — web-researched report of missing features and future improvements (no code changes) |

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

## 13. What Could This Blog Do Better? (Optional)

Once the pipeline is complete and your blog is live, you can run one final
optional prompt to get an honest, web-researched assessment of what your blog
might be missing compared to the best personal blogs on the web today.

**When to use it:**

> "My blog is built and deployed. What features should I consider adding in the future?"

**How to run it:**

Open a new Claude Code session in your blog folder and paste the contents of
`prompt_blog_13_future_features.txt`.

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
