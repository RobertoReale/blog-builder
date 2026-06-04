# Blog — Claude Code Context

This is a personal blog built with Astro 4 + Tailwind CSS + MDX + TypeScript.
Deploy target: Vercel (static). Open source on GitHub.

Read this file before doing anything. It contains rules and conventions
that must be respected in every session, regardless of what task you're doing.

---

## STACK

- Astro 4, output: 'static'
- @astrojs/tailwind
- @astrojs/mdx
- TypeScript (strict mode — no `any` types)
- Fonts: Lora (headings) + DM Sans (body/UI) — self-hosted via @fontsource/lora + @fontsource/dm-sans
- Deploy: Vercel static — NO @astrojs/vercel adapter needed

---

## SITE CONFIG

All site-level constants live in src/config.ts:
```ts
export const SITE = {
  title: string
  description: string
  url: string
  author: string
}
```
Import SITE wherever site-level data is needed. Never hardcode the site title,
URL, or author name anywhere else.

---

## DESIGN SYSTEM

Colors are CSS custom properties only. Never hardcode hex values in Tailwind
classes or inline styles. Always reference variables.

```css
/* Light mode (:root) */
--color-bg: #FFFFFF
--color-text: #111827
--color-muted: #6B7280
--color-accent: #2563EB
--color-border: #E5E7EB
--color-surface: #F9FAFB

/* Dark mode ([data-theme="dark"] on <html>) */
--color-bg: #111827
--color-text: #F3F4F6
--color-muted: #9CA3AF
--color-accent: #3B82F6
--color-border: #374151
--color-surface: #1F2937
```

Typography:
- Headings (h1–h3): Lora, serif
- Body + UI: DM Sans, sans-serif
- Base size: 18px, line-height: 1.75
- Max content width: 680px centered

Layout:
- Single centered column, no sidebars
- No decorative elements, no gradients, no shadows
- Tailwind used for spacing/layout only — not for colors

---

## DARK MODE

- Preference stored in localStorage key: "theme"
- Applied as data-theme="dark" on <html>
- Inline script in <head> prevents flash of wrong theme:
```html
<script is:inline>
  const theme = localStorage.getItem('theme') ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  document.documentElement.setAttribute('data-theme', theme);
</script>
```
- ThemeToggle.astro handles the toggle button (sun/moon SVG, aria-label="Toggle dark mode")

---

## ARTICLE FRONTMATTER SCHEMA

Defined in src/content/config.ts with Zod:

```ts
title: z.string()
date: z.date()
tags: z.array(z.string())
description: z.string()
origin: z.string().optional()
originPosition: z.enum(['top', 'bottom']).optional().default('bottom')
coverImage: z.string().optional()          // omit entirely if not set — never null
sources: z.array(z.object({
  label: z.string(),
  href: z.string(),
})).optional().default([])
status: z.enum(['draft', 'published'])
series: z.string().optional()
part: z.number().optional()
language: z.enum(['en', 'it']).optional().default('en')  // → BaseLayout sets <html lang>
```

IMPORTANT: `coverImage` must be omitted entirely from frontmatter when there
is no image. Writing `coverImage:` with no value parses as null in YAML,
which fails Zod validation (optional() accepts undefined, not null).

The `language` field is not decorative: article pages pass `entry.data.language`
to BaseLayout's `lang` prop, which renders `<html lang={lang}>`. Static pages
default to 'en'.

Only articles with status: 'published' appear in listings.

---

## CUSTOM MDX COMPONENTS

### Callout.astro
Props: type ('info' | 'warning'), title (string)
- Outer wrapper with a distinct background based on type (use surface color).
- Left border with accent color.
- Renders the title in bold, followed by the default slot content.

### ImageWithCaption.astro
Props: src, alt, caption, size ('full' | 'half', default 'full')
- Dark mode: white background + 12px padding on image

### Sources.astro
Props: sources (Array<{ label: string; href: string }>)
- ALWAYS called with explicit prop: <Sources sources={frontmatter.sources} />
- In MDX files, frontmatter is automatically in scope — use it directly
- Never use a "no props" pattern — always pass sources explicitly
- Renders nothing if sources array is empty

---

## PROJECT STRUCTURE

```
src/
  components/
    mdx/          Callout.astro, ImageWithCaption.astro, Sources.astro
    ui/           ThemeToggle.astro, ArticleCard.astro, TagPill.astro,
                  TagFilter.astro, BackToTop.astro, SeriesNav.astro,
                  RelatedArticles.astro, TOC.astro
  layouts/        BaseLayout.astro, ArticleLayout.astro
  pages/          index.astro, articles.astro, article/[slug].astro,
                  tag/[tag].astro, about.astro, now.astro, search.astro,
                  series/index.astro, series/[series].astro, 404.astro, rss.xml.ts
  content/
    config.ts
    articles/
  utils/          readingTime.ts, formatDate.ts, slugify.ts
  styles/         global.css
  config.ts
tests/
  unit/           utils.test.ts
  e2e/            blog.spec.ts
```

Note: not all files may exist yet depending on which features have been
implemented. See FEATURES STATUS below.

---

## ARTICLE PAGE ELEMENT ORDER (single source of truth)

src/pages/article/[slug].astro has exactly ONE getStaticPaths. Multiple
features (Series, Related) contribute data to it — extend the same per-entry
map and return all props in one object; never overwrite another feature's props.

Render order on an article page:
1. Header (title, date, reading time, tags, share button)
2. SeriesNav        (if the article is in a series)
3. TOC              (if the article has headings)
4. Article body (MDX)
5. Sources
6. ─── separator ───
7. Related articles (if any)
8. Footer

The reading progress bar (Feature 02) is fixed at the top of the viewport and
sits outside this flow.

## UTILITIES

```ts
// readingTime.ts
getReadingTime(content: string): string  // Math.ceil(words / 200) + " min read"

// formatDate.ts
formatDate(date: Date): string  // "June 3, 2025" format — uses timeZone: 'UTC'
// (frontmatter dates parse as UTC midnight; UTC formatting keeps the displayed
//  day identical to the frontmatter day in every timezone)

// slugify.ts
slugify(str: string): string
// lowercase, trim, remove special chars, spaces+underscores→hyphens, collapse hyphens
```

---

## TESTING

```bash
npm run test:unit     # Vitest — utils only, runs in milliseconds
npm run test:e2e      # Playwright — smoke tests against dev server
npm run test          # both
npm run build         # always run after any change
```

After every task: run `npm run build` at minimum.
If you touched a utility function: also run `npm run test:unit`.
If you touched a page or component: also run `npm run test:e2e`.

---

## FIXED RULES — always apply, every session

1. No `any` types — TypeScript strict mode
2. No hardcoded colors — always CSS variables
3. No @astrojs/vercel adapter — static output, not needed
4. Sources always passed as explicit prop: <Sources sources={frontmatter.sources} />
5. coverImage omitted from frontmatter when empty — never written as null
6. No new features beyond what is requested in the current task
7. No comments system, no newsletter, no analytics, no auth — ever
8. `npm run build` must succeed before the task is considered done

---

## FEATURES STATUS

This section reflects the template state BEFORE the pipeline runs.
Each step automatically implements its feature. After a full pipeline run
(steps 0–9), all features below will be complete.

- [x] Foundation (pages, MDX components, dark mode, example article)
- [ ] Testing setup (Vitest + Playwright)
- [ ] Feature 01 — SEO (RSS, sitemap, robots.txt, canonical, 404, JSON-LD)
- [ ] Feature 02 — Reading UX (progress bar, back to top, share, TOC)
- [ ] Feature 03 — Search (Pagefind)
- [ ] Feature 04 — Article series (SeriesNav, /series/[series])
- [ ] Feature 05 — Related articles
- [ ] Feature 06 — Keystatic CMS (browser editor, GitHub mode, hybrid output)
