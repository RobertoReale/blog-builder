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
echo -e "${C}=== 1/6 — Site info ===${N}"
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
echo -e "${C}=== 2/6 — Color palette ===${N}"
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
echo -e "${C}=== 3/6 — Typography ===${N}"
echo ""
echo "  1  Lora + DM Sans                  — classic serif + clean sans  (default)"
echo "  2  Playfair Display + Source Sans 3 — editorial, elegant"
echo "  3  DM Serif Display + DM Sans      — modern, cohesive"
echo "  4  Fraunces + Inter                — quirky serif + tech sans"
echo "  5  Inter + Inter                   — pure sans-serif, minimal"
echo "  6  Custom                          — enter your own fontsource.org font names"
echo ""
read -p "Choice [1-6, default 1]: " f; f=${f:-1}

case "$f" in
  2) HF="Playfair Display" HT="serif"     BF="Source Sans 3" ;;
  3) HF="DM Serif Display" HT="serif"     BF="DM Sans" ;;
  4) HF="Fraunces"         HT="serif"     BF="Inter" ;;
  5) HF="Inter"            HT="sans-serif" BF="Inter" ;;
  6) read -p "Heading font (exact name as on fontsource.org): " HF
     read -p "  serif or sans-serif? " HT
     read -p "Body/UI font (exact name as on fontsource.org): " BF ;;
  *) HF="Lora" HT="serif" BF="DM Sans" ;;
esac
echo ""

# --- 4. Analytics ---
echo -e "${C}=== 4/6 — Analytics (optional) ===${N}"
echo ""
echo "  0  None                         — no analytics, skip this step  (default)"
echo "  1  Umami Cloud                  — privacy-first, 100k events/month free  (recommended)"
echo "  2  Cloudflare Web Analytics     — unlimited free, requires DNS nameserver change"
echo "  3  Vercel Analytics             — 2,500 events/month free, minimal setup"
echo ""
read -p "Choice [0-3, default 0]: " an; an=${an:-0}

case "$an" in
  1) ANALYTICS_PROVIDER="umami" ;;
  2) ANALYTICS_PROVIDER="cloudflare" ;;
  3) ANALYTICS_PROVIDER="vercel" ;;
  *) ANALYTICS_PROVIDER="none" ;;
esac
echo ""

# --- 5. Comments ---
echo -e "${C}=== 5/6 — Comments (optional) ===${N}"
echo ""
echo "  0  None         — no comments section  (default)"
echo "  1  Giscus       — GitHub Discussions, privacy-first, free  (recommended)"
echo "  2  Utterances   — GitHub Issues, simpler, free"
echo ""
read -p "Choice [0-2, default 0]: " cm; cm=${cm:-0}

case "$cm" in
  1) COMMENTS_PROVIDER="giscus" ;;
  2) COMMENTS_PROVIDER="utterances" ;;
  *) COMMENTS_PROVIDER="none" ;;
esac
echo ""

# --- 6. Newsletter ---
echo -e "${C}=== 6/6 — Newsletter (optional) ===${N}"
echo ""
echo "  0  None          — no newsletter form  (default)"
echo "  1  Buttondown    — privacy-first, 100 subscribers free  (recommended)"
echo "  2  Substack      — popular, free for free newsletters"
echo "  3  Kit           — formerly ConvertKit, 10k subscribers free"
echo ""
read -p "Choice [0-3, default 0]: " nl; nl=${nl:-0}

case "$nl" in
  1) NEWSLETTER_PROVIDER="buttondown" ;;
  2) NEWSLETTER_PROVIDER="substack" ;;
  3) NEWSLETTER_PROVIDER="kit" ;;
  *) NEWSLETTER_PROVIDER="none" ;;
esac
echo ""

# --- 7. Update CLAUDE.md ---
echo -e "${C}Updating CLAUDE.md...${N}"

export BLOG_TITLE BLOG_DESC BLOG_URL BLOG_AUTHOR
export LBG LTX LMU LAC LBO LSU
export DBG DTX DMU DAC DBO DSU
export HF HT BF
export ANALYTICS_PROVIDER COMMENTS_PROVIDER NEWSLETTER_PROVIDER

python3 << 'PYEOF'
import os

t, d, u, a   = os.environ['BLOG_TITLE'], os.environ['BLOG_DESC'], os.environ['BLOG_URL'], os.environ['BLOG_AUTHOR']
lbg, ltx, lmu, lac, lbo, lsu = (os.environ[k] for k in ('LBG','LTX','LMU','LAC','LBO','LSU'))
dbg, dtx, dmu, dac, dbo, dsu = (os.environ[k] for k in ('DBG','DTX','DMU','DAC','DBO','DSU'))
hf, ht, bf   = os.environ['HF'], os.environ['HT'], os.environ['BF']

with open('CLAUDE.md', 'r', encoding='utf-8') as fh:
    c = fh.read()

# 1. Insert or update site values before the "Import SITE" paragraph
import re
marker = 'Import SITE wherever site-level data is needed.'
block  = (f'Site values (use these when creating src/config.ts):\n'
          f'- title: "{t}"\n'
          f'- description: "{d}"\n'
          f'- url: "{u}"\n'
          f'- author: "{a}"\n\n')
if marker in c:
    c = re.sub(r'Site values \(use these when creating src/config\.ts\):\n.*?\n\n(?=' + re.escape(marker) + r')', '', c, flags=re.DOTALL)
    c = c.replace(marker, block + marker)

# 2. Replace color palette (using regex to match any existing CSS block)
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

c, count = re.subn(r'```css\n/\* Light mode \(:root\) \*/.*?```', new_col, c, flags=re.DOTALL)
if count == 0:
    print('  Note: color block not found - already configured?')

# 3. Replace typography lines (regex — matches any current value, including first run)
# 3. Replace typography lines (regex matches any current value)
old_typ = ('> **USER ACTION REQUIRED**: Define your preferred typography here.\n'
           '- Headings (h1–h3): [YOUR_HEADING_FONT], serif/sans-serif\n'
           '- Body + UI: [YOUR_BODY_FONT], sans-serif')
new_typ = f'- Headings (h1–h3): {hf}, {ht}\n- Body + UI: {bf}, sans-serif'
if old_typ in c:
    c = c.replace(old_typ, new_typ)
else:
    # Re-run: replace existing font values with regex (matches any font name)
    c = re.sub(r'- Headings \(h1–h3\): .+', f'- Headings (h1–h3): {hf}, {ht}', c)
    c = re.sub(r'- Body \+ UI: .+, sans-serif', f'- Body + UI: {bf}, sans-serif', c)

# 4. Update Fonts line in STACK section (regex — matches any current value)
c = re.sub(
    r'- Fonts: .+\(headings\) \+ .+\(body/UI\).*',
    f'- Fonts: {hf} (headings) + {bf} (body/UI) — self-hosted via @fontsource',
    c
)

# 5. Replace each provider value (section-aware)
def replace_provider(text, section_name, new_value):
    pattern = r'(## ' + re.escape(section_name) + r'\n\n)Provider:\s*\S+'
    return re.sub(pattern, r'\g<1>Provider: ' + new_value, text)

c = replace_provider(c, 'ANALYTICS',  os.environ.get('ANALYTICS_PROVIDER',  'none'))
c = replace_provider(c, 'COMMENTS',   os.environ.get('COMMENTS_PROVIDER',   'none'))
c = replace_provider(c, 'NEWSLETTER', os.environ.get('NEWSLETTER_PROVIDER', 'none'))

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
OPTIONAL_STEPS=()
[ "$ANALYTICS_PROVIDER"  != "none" ] && OPTIONAL_STEPS+=("analytics")
[ "$COMMENTS_PROVIDER"   != "none" ] && OPTIONAL_STEPS+=("comments")
[ "$NEWSLETTER_PROVIDER" != "none" ] && OPTIONAL_STEPS+=("newsletter")
BASE_STEPS=10
TOTAL_STEPS=$(( BASE_STEPS + ${#OPTIONAL_STEPS[@]} ))
LAST_STEP=$(( TOTAL_STEPS - 1 ))
if [ ${#OPTIONAL_STEPS[@]} -gt 0 ]; then
  OPT_LABEL=$(IFS=', '; echo "${OPTIONAL_STEPS[*]}")
  STEP_NOTE="runs all $TOTAL_STEPS steps, 0–$LAST_STEP — $OPT_LABEL included"
else
  STEP_NOTE="runs all $BASE_STEPS steps, 0–$(( BASE_STEPS - 1 ))"
fi
echo -e "  1. Run the ecosystem discovery (optional but recommended):"
echo -e "       Open Claude Code in this folder, then send the contents of:"
echo -e "       ${W}prompt_blog_pre_discovery.txt${N}"
echo -e "       Claude searches for the best current tools, shows them to you,"
echo -e "       and writes your choices to CHOSEN_TOOLS.md."
echo -e "       Every subsequent build step will pick them up automatically."
echo ""
echo -e "  2. Generate the blog:"
echo -e "       ${W}./run.sh${N}        ($STEP_NOTE)"
echo -e "       ${W}./run.sh -p${N}     (pauses after each step)"
echo ""
if [ -n "$GITHUB_REMOTE" ]; then
echo -e "  3. After the pipeline finishes, push to GitHub:"
echo -e "       ${W}git push -u origin HEAD${N}"
echo ""
fi
echo -e "  Once generated, preview with:  npm run dev"
echo -e "  Then open:  http://localhost:4321"
echo ""
