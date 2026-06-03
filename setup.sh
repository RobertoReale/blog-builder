#!/bin/bash
#
# setup.sh — Configures the blog before running the pipeline.
# Run this once, then run ./run.sh to generate the blog.
#
# USAGE:
#   chmod +x setup.sh
#   ./setup.sh

G='\033[0;32m'; C='\033[0;36m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[0;31m'; N='\033[0m'

echo ""
echo -e "${W}=================================================${N}"
echo -e "${W}         Blog Builder — Setup${N}"
echo -e "${W}=================================================${N}"
echo ""

# --- Prerequisites ---
if [ ! -f "CLAUDE.md" ]; then
  echo -e "${R}Error: CLAUDE.md not found. Run this script from the blog-builder folder.${N}"
  exit 1
fi
if ! command -v python3 &>/dev/null; then
  echo -e "${R}Error: python3 is required. Install it from https://python.org${N}"
  exit 1
fi

# --- 1. Site info ---
echo -e "${C}=== 1/3 — Site info ===${N}"
echo ""
read -p "Blog title: " BLOG_TITLE
read -p "Description (one sentence): " BLOG_DESC
echo ""
echo -e "  ${C}URL tip${N}: if you're deploying to Vercel and haven't deployed yet, Vercel"
echo    "  will assign an ugly auto-generated link (e.g. blog-6jcd.vercel.app)."
echo    "  You can rename it for free in Settings → Domains after the first deploy."
echo    "  → Enter a placeholder now (e.g. https://my-blog.vercel.app) and update"
echo -e "    ${W}src/config.ts${N} after you know your real URL. See README.md §5 for details."
echo ""
read -p "URL (e.g. https://yourdomain.vercel.app): " BLOG_URL
read -p "Author name: " BLOG_AUTHOR
echo ""

# --- 2. Color palette ---
echo -e "${C}=== 2/3 — Color palette ===${N}"
echo ""
echo "  1  Blue / Neutral  — clean, professional           (default)"
echo "  2  Forest          — warm greens, earthy tones"
echo "  3  Sunset          — warm oranges, amber"
echo "  4  Ink             — deep purples, editorial"
echo "  5  Mono            — pure black and white, minimal"
echo "  6  Custom          — enter your own hex values"
echo ""
read -p "Choice [1-6, default 1]: " c; c=${c:-1}

case "$c" in
  2) LBG="#FAFAF8" LTX="#1C2B1A" LMU="#6B7B6A" LAC="#2D6A4F" LBO="#D8E8D4" LSU="#F0F5EE"
     DBG="#161E15" DTX="#E8F0E6" DMU="#8FA98D" DAC="#52B788" DBO="#2D3F2B" DSU="#1E2B1C" ;;
  3) LBG="#FFFBF7" LTX="#1C1410" LMU="#7B6B60" LAC="#C2580A" LBO="#EDD9C8" LSU="#FAF1E8"
     DBG="#1A1108" DTX="#F5EDE4" DMU="#A89080" DAC="#E8844A" DBO="#3D2A1A" DSU="#261A0E" ;;
  4) LBG="#FDFCFF" LTX="#1A1625" LMU="#72687E" LAC="#6D28D9" LBO="#E4DFF0" LSU="#F5F2FC"
     DBG="#120E1C" DTX="#EDE9F5" DMU="#9A90A8" DAC="#A78BFA" DBO="#2D2640" DSU="#1C1730" ;;
  5) LBG="#FFFFFF" LTX="#0A0A0A" LMU="#737373" LAC="#0A0A0A" LBO="#E5E5E5" LSU="#FAFAFA"
     DBG="#0A0A0A" DTX="#FAFAFA" DMU="#A3A3A3" DAC="#FAFAFA" DBO="#262626" DSU="#171717" ;;
  6) echo ""
     echo "Light mode:"
     read -p "  Background:              " LBG
     read -p "  Text:                    " LTX
     read -p "  Muted (secondary text):  " LMU
     read -p "  Accent (links/buttons):  " LAC
     read -p "  Border:                  " LBO
     read -p "  Surface (card bg):       " LSU
     echo ""
     echo "Dark mode:"
     read -p "  Background:              " DBG
     read -p "  Text:                    " DTX
     read -p "  Muted:                   " DMU
     read -p "  Accent:                  " DAC
     read -p "  Border:                  " DBO
     read -p "  Surface:                 " DSU ;;
  *) LBG="#FFFFFF" LTX="#111827" LMU="#6B7280" LAC="#2563EB" LBO="#E5E7EB" LSU="#F9FAFB"
     DBG="#111827" DTX="#F3F4F6" DMU="#9CA3AF" DAC="#3B82F6" DBO="#374151" DSU="#1F2937" ;;
esac
echo ""

# --- 3. Typography ---
echo -e "${C}=== 3/3 — Typography ===${N}"
echo ""
echo "  1  Lora + DM Sans                  — classic serif + clean sans  (default)"
echo "  2  Playfair Display + Source Sans 3 — editorial, elegant"
echo "  3  DM Serif Display + DM Sans      — modern, cohesive"
echo "  4  Fraunces + Inter                — quirky serif + tech sans"
echo "  5  Inter + Inter                   — pure sans-serif, minimal"
echo "  6  Custom                          — enter your own Google Font names"
echo ""
read -p "Choice [1-6, default 1]: " f; f=${f:-1}

case "$f" in
  2) HF="Playfair Display" HT="serif"     BF="Source Sans 3" ;;
  3) HF="DM Serif Display" HT="serif"     BF="DM Sans" ;;
  4) HF="Fraunces"         HT="serif"     BF="Inter" ;;
  5) HF="Inter"            HT="sans-serif" BF="Inter" ;;
  6) read -p "Heading font (exact Google Fonts name): " HF
     read -p "  serif or sans-serif? " HT
     read -p "Body/UI font (exact Google Fonts name): " BF ;;
  *) HF="Lora" HT="serif" BF="DM Sans" ;;
esac
echo ""

# --- 4. Update CLAUDE.md ---
echo -e "${C}Updating CLAUDE.md...${N}"

export BLOG_TITLE BLOG_DESC BLOG_URL BLOG_AUTHOR
export LBG LTX LMU LAC LBO LSU
export DBG DTX DMU DAC DBO DSU
export HF HT BF

python3 << 'PYEOF'
import os

t, d, u, a   = os.environ['BLOG_TITLE'], os.environ['BLOG_DESC'], os.environ['BLOG_URL'], os.environ['BLOG_AUTHOR']
lbg, ltx, lmu, lac, lbo, lsu = (os.environ[k] for k in ('LBG','LTX','LMU','LAC','LBO','LSU'))
dbg, dtx, dmu, dac, dbo, dsu = (os.environ[k] for k in ('DBG','DTX','DMU','DAC','DBO','DSU'))
hf, ht, bf   = os.environ['HF'], os.environ['HT'], os.environ['BF']

with open('CLAUDE.md', 'r', encoding='utf-8') as fh:
    c = fh.read()

# 1. Insert site values before the "Import SITE" paragraph
marker = 'Import SITE wherever site-level data is needed.'
block  = (f'Site values (use these when creating src/config.ts):\n'
          f'- title: "{t}"\n'
          f'- description: "{d}"\n'
          f'- url: "{u}"\n'
          f'- author: "{a}"\n\n')
if marker in c and 'Site values' not in c:
    c = c.replace(marker, block + marker)

# 2. Replace color palette (USER ACTION REQUIRED block + default CSS)
old_col = ('> **USER ACTION REQUIRED**: Define your custom color palette here. \n'
           '> Replace these generic defaults with your own brand colors before running.\n'
           '\n'
           '```css\n'
           '/* Light mode (:root) */\n'
           '--color-bg: #FFFFFF\n'
           '--color-text: #111827\n'
           '--color-muted: #6B7280\n'
           '--color-accent: #2563EB\n'
           '--color-border: #E5E7EB\n'
           '--color-surface: #F9FAFB\n'
           '\n'
           '/* Dark mode ([data-theme="dark"] on <html>) */\n'
           '--color-bg: #111827\n'
           '--color-text: #F3F4F6\n'
           '--color-muted: #9CA3AF\n'
           '--color-accent: #3B82F6\n'
           '--color-border: #374151\n'
           '--color-surface: #1F2937\n'
           '```')
new_col = (f'```css\n'
           f'/* Light mode (:root) */\n'
           f'--color-bg: {lbg}\n'
           f'--color-text: {ltx}\n'
           f'--color-muted: {lmu}\n'
           f'--color-accent: {lac}\n'
           f'--color-border: {lbo}\n'
           f'--color-surface: {lsu}\n'
           f'\n'
           f'/* Dark mode ([data-theme="dark"] on <html>) */\n'
           f'--color-bg: {dbg}\n'
           f'--color-text: {dtx}\n'
           f'--color-muted: {dmu}\n'
           f'--color-accent: {dac}\n'
           f'--color-border: {dbo}\n'
           f'--color-surface: {dsu}\n'
           f'```')
if old_col in c:
    c = c.replace(old_col, new_col)
else:
    print('  Note: color block not found — already configured?')

# 3. Replace typography USER ACTION REQUIRED
old_typ = ('> **USER ACTION REQUIRED**: Define your preferred typography here.\n'
           '- Headings (h1–h3): [YOUR_HEADING_FONT], serif/sans-serif\n'
           '- Body + UI: [YOUR_BODY_FONT], sans-serif')
new_typ = f'- Headings (h1–h3): {hf}, {ht}\n- Body + UI: {bf}, sans-serif'
if old_typ in c:
    c = c.replace(old_typ, new_typ)
else:
    print('  Note: typography block not found — already configured?')

# 4. Update Google Fonts line in STACK section
c = c.replace(
    '- Google Fonts: Lora (headings) + DM Sans (body/UI)',
    f'- Google Fonts: {hf} (headings) + {bf} (body/UI)'
)

with open('CLAUDE.md', 'w', encoding='utf-8') as fh:
    fh.write(c)

print('  Done.')
PYEOF

if [ $? -ne 0 ]; then
  echo -e "${R}Failed to update CLAUDE.md. Check the error above.${N}"
  exit 1
fi
echo -e "${G}CLAUDE.md configured.${N}"
echo ""

# --- 5. GitHub (optional) ---
echo -e "${C}=== GitHub (optional) ===${N}"
echo ""
echo "Create a GitHub repository for your blog?"
echo -e "  Requires: ${W}GitHub CLI (gh)${N} — https://cli.github.com"
echo ""
read -p "Set up GitHub? [y/N]: " gh_ans; gh_ans=${gh_ans:-N}

GITHUB_REMOTE=""
if [[ "$gh_ans" =~ ^[Yy]$ ]]; then
  if ! command -v gh &>/dev/null; then
    echo -e "${Y}Warning: GitHub CLI (gh) not found.${N}"
    echo -e "${Y}Install it from https://cli.github.com then rerun: ./setup.sh${N}"
  else
    if ! gh auth status &>/dev/null 2>&1; then
      echo "Logging in to GitHub..."
      gh auth login
    fi
    echo ""
    read -p "Repository name (e.g. my-blog): " REPO_NAME
    echo ""
    echo "  1  Public"
    echo "  2  Private"
    read -p "Visibility [1-2, default 1]: " vis; vis=${vis:-1}
    [ "$vis" = "2" ] && VIS_FLAG="--private" || VIS_FLAG="--public"

    # Ensure git repo exists
    if [ ! -d ".git" ]; then
      git init
      git add -A
      git commit -m "Initial setup: blog configuration" --quiet || true
    fi

    # Remove blog-builder origin (if any), create new repo
    git remote remove origin 2>/dev/null || true
    echo ""
    gh repo create "$REPO_NAME" "$VIS_FLAG" --description "$BLOG_DESC"
    GITHUB_USER=$(gh api user --jq .login)
    GITHUB_REMOTE="https://github.com/$GITHUB_USER/$REPO_NAME.git"
    git remote add origin "$GITHUB_REMOTE"
    echo -e "${G}Repository created: https://github.com/$GITHUB_USER/$REPO_NAME${N}"
  fi
fi

# --- Done ---
echo ""
echo -e "${W}=================================================${N}"
echo -e "${G}  Setup complete!${N}"
echo -e "${W}=================================================${N}"
echo ""
echo -e "Next steps:"
echo ""
echo -e "  1. Generate the blog:"
echo -e "       ${W}./run.sh${N}        (runs all 9 steps, 0–8)"
echo -e "       ${W}./run.sh -p${N}     (pauses after each step)"
echo ""
if [ -n "$GITHUB_REMOTE" ]; then
echo -e "  2. After the pipeline finishes, push to GitHub:"
echo -e "       ${W}git push -u origin HEAD${N}"
echo ""
fi
echo -e "  Once generated, preview with:  npm run dev"
echo -e "  Then open:  http://localhost:4321"
echo ""
