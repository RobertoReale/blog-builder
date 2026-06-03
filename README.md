# AI Blog Builder

A powerful, iterative framework to build a complete, production-ready personal blog using Astro 4, Tailwind CSS, and MDX, entirely generated through sequenced LLM prompts via Claude Code.

## Concept: Iterative AI Generation

Instead of generating an entire codebase in one massive prompt (which often leads to context overflow, hallucinations, and broken code), this project uses a **sequenced prompt architecture**.

The build is broken down into small, verifiable steps. A PowerShell script (`run.ps1`) executes these steps sequentially using **Claude Code**. After each prompt, the script runs a build check (`npm run build`) and automated tests. If the build breaks, the pipeline stops, preventing the AI from building on top of a broken state.

## Project Structure

- **`CLAUDE.md`**: The core rules of the project. It acts as the system prompt and is read by Claude at every step. It defines the stack, the design system, frontmatter schemas, and strictly forbids unwanted features.
- **`prompt_blog_*.txt`**: The sequenced prompts.
  - `00_foundation`: Basic layout, dark mode, typography, MDX setup.
  - `01_testing`: Unit and E2E test setup (Vitest + Playwright).
  - `02_seo`: RSS, Sitemap, JSON-LD, Robots.txt.
  - `03_reading_ux`: Progress bar, Back to top, Table of Contents.
  - `04_search`: Pagefind static search integration.
  - `05_series`: Article series grouping.
  - `06_related`: Related articles recommendation.
- **`run.ps1`**: The automation pipeline. It runs Claude Code for each prompt and enforces the build tests.
- **`SETUP.md`**: Detailed instructions on prerequisites and how to launch the build.

## How to use

1. Follow the instructions in **[`SETUP.md`](SETUP.md)** to install the prerequisites (Node.js LTS, Git, and Claude Code).
2. Open PowerShell in this folder.
3. Run the pipeline:
   ```powershell
   .\run.ps1
   ```
4. Watch as Claude Code iteratively builds your blog, checks the code, and passes to the next step!

## Why this approach?

- **Zero Drift**: By verifying the compilation (`npm run build`) after each step, we ensure the project is always in a working state.
- **Maintainable**: The rules are clearly defined in `CLAUDE.md`, making it easy to add new prompts without breaking the architecture.
- **Educational**: By reading the prompts, you learn how to instruct LLMs effectively for complex software engineering tasks.

---

*This repository is a template. You can customize `CLAUDE.md` and the prompts to build your own custom AI-generated projects!*
