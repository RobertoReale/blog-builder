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
- Google Fonts: Lora (headings) + DM Sans (body/UI)
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
--color-text: #1A1A1A
--color-muted: #6B6B6B
--color-accent: #2D5016
--color-border: #E8E8E8
--color-origin-bg: #F7F7F5

/* Dark mode ([data-theme="dark"] on <html>) */
--color-bg: #0F0F0F
--color-text: #E8E8E8
--color-muted: #888888
--color-accent: #7AB648
--color-border: #2A2A2A
--color-origin-bg: #1A1A1A
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

### QA.astro
Props: question (string)
- Outer wrapper has: id="qa-{slugifiedQuestion}" and data-qa-question="{question}"
- question styled: Lora, accent color, border-left 3px solid accent
- Answer: DM Sans body text below question

### Origin.astro
Slot: default content
- Background: var(--color-origin-bg)
- Border-left: 3px solid var(--color-accent)
- Label "How I got here", italic text, lightbulb SVG icon

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
    mdx/          QA.astro, Origin.astro, ImageWithCaption.astro, Sources.astro
    ui/           ThemeToggle.astro, ArticleCard.astro, TagPill.astro,
                  TagFilter.astro, BackToTop.astro, SeriesNav.astro,
                  RelatedArticles.astro, TOC.astro
  layouts/        BaseLayout.astro, ArticleLayout.astro
  pages/          index.astro, articles.astro, article/[slug].astro,
                  tag/[tag].astro, about.astro, now.astro, search.astro,
                  series/[series].astro, 404.astro, rss.xml.ts
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
3. Origin block     (only if originPosition === 'top')
4. TOC              (if the article has 3+ QA blocks)
5. Article body (MDX)
6. Origin block     (only if originPosition === 'bottom')
7. Sources
8. ─── separator ───
9. Related articles (if any)
10. Footer

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

Update this section manually as features are completed.

- [x] Foundation (pages, MDX components, dark mode, example article)
- [ ] Testing setup (Vitest + Playwright)
- [ ] Feature 01 — SEO (RSS, sitemap, robots.txt, canonical, 404, JSON-LD)
- [ ] Feature 02 — Reading UX (progress bar, back to top, share, TOC)
- [ ] Feature 03 — Search (Pagefind)
- [ ] Feature 04 — Article series (SeriesNav, /series/[series])
- [ ] Feature 05 — Related articles
