"""
Fix and relocate the Kintsugi note:
1. Remove soft-hyphen word-break artifacts (e.g. "Japan-ese" → "Japanese")
2. Fix YAML (tags, nav)
3. Remove clutter (social sharing buttons, Open Culture donation block)
4. Add nav breadcrumb
5. Move from 01/NLP to 01/Japan
"""

import re, glob, os

# Find the file (smart apostrophe in name)
matches = glob.glob('D:/Obsidian/Main/01/NLP/*Kintsugi*')
if not matches:
    print("File not found!")
    exit(1)

src = matches[0]
print(f"Source: {src}")

with open(src, 'r', encoding='utf-8') as f:
    content = f.read()

# ── 1. Split YAML from body ────────────────────────────────────────────────
m = re.match(r'^(---.*?---\n)(.*)', content, re.DOTALL)
yaml_block = m.group(1)
body = m.group(2)

# ── 2. Fix YAML ────────────────────────────────────────────────────────────
yaml_block = """---
title: "Trevor Noah Explains How Kintsugi Helped Him Overcome Life's Tragedies"
source: "https://www.openculture.com/2026/01/trevor-noah-explains-how-kintsugi-helped-him-overcome-lifes-tragedies.html"
author:
  - "[[Colin Marshall]]"
published: 2026-01-09
created: 2026-01-09
description: "Trevor Noah discusses kintsugi — the Japanese art of repairing broken pottery with gold — as a metaphor for resilience and finding beauty in one's own cracks, drawing on his own experiences of trauma."
tags:
  - Kintsugi
  - Japan
  - JapaneseCulture
  - TrevorNoah
  - Resilience
  - Clippings
nav: "[[01/Japan]] | [[MOC - Japan & Japanese Culture]]"
---
"""

# ── 3. Remove clutter from body ────────────────────────────────────────────
# Remove the "in | January 9th, 2026 [Leave a Comment](...)" line
body = re.sub(r'^in \|.*?\n', '', body, flags=re.MULTILINE)

# Remove social sharing lines (lines with [Bluesky][Facebook]...)
body = re.sub(r'^\[Bluesky\].*\n', '', body, flags=re.MULTILINE)

# Remove the "Support Open Culture" donation block (from **Sup...** to end of that section)
body = re.sub(r'\*\*Sup-?p?o?r?t? Open Cul-?ture\*\*.*', '', body, flags=re.DOTALL)

# Remove empty image donation button lines
body = re.sub(r'!\[\[[^\]]+MD5[^\]]+\]\]\([^)]+\)\s*\n', '', body)

# ── 4. Fix soft-hyphen word breaks in body ─────────────────────────────────
# The article has syllabic hyphenation on EVERY word (web clipper artifact).
# Strategy: remove hyphens between lowercase letters that appear to be
# syllable breaks (not real compound hyphens).
# Heuristic: if removing the hyphen produces a common English word,
# remove it. Since we can't do dictionary lookup easily, we use a
# pattern-based approach:
# - "X-Y" where len(Y) <= 3 and Y is a common suffix fragment → join
# - Multi-hyphenated words (X-Y-Z) → join all

# First: join multi-hyphenated sequences (clearly artifacts)
# e.g. "pop-cul-tur-al" → "popcultural" then we fix below
# e.g. "half-mil-len-ni-um" → "halfmillennium"
# Step: repeatedly join consecutive hyphenated lower-lower pairs
prev = None
while prev != body:
    prev = body
    # Remove hyphen between lowercase letters where the right side is 1-3 chars
    # (syllable fragment, not a whole word)
    body = re.sub(r'([a-z])-([a-z]{1,3})(?=[a-z])', r'\1\2', body)

# Now join remaining single hyphens between lowercase letters
# but preserve known real compounds: long-form, pop-cultural, half-millennium, etc.
# Since most real compounds will have been reassembled by now with full words,
# we can safely join remaining lowercase-hyphen-lowercase
# Exception: preserve hyphens in "long-form", "self-X", "non-X", "open-X"
body = re.sub(r'([a-z])-([a-z])', r'\1\2', body)

# Manual fixes for over-joined real compounds in this text:
body = body.replace('longform', 'long-form')
body = body.replace('popcultural', 'pop-cultural')
body = body.replace('halfmillennium', 'half-millennium')
body = body.replace('twoanda', 'two-and-a')  # if it appears

# ── 5. Fix "Related Con-tent" heading ─────────────────────────────────────
body = body.replace('Relatd Content:', 'Related Content:')
body = body.replace('Relat-ed Con-tent:', 'Related Content:')
body = re.sub(r'\*\*Relat[^\*]+\*\*:', '**Related Content:**', body)

# ── 6. Add nav breadcrumb ──────────────────────────────────────────────────
body = '[[01/Japan]] | [[MOC - Japan & Japanese Culture]]\n\n' + body.lstrip()

# ── 7. Fix Related Notes section ──────────────────────────────────────────
# Remove [[Time Line Therapy]] and [[MOC - NLP & Psychology]] from Related Notes
body = re.sub(r'^- \[\[Time Line Therapy\]\]\n', '', body, flags=re.MULTILINE)
body = re.sub(r'^- \[\[MOC - NLP & Psychology\]\]\n', '', body, flags=re.MULTILINE)

# ── 8. Clean up multiple blank lines ──────────────────────────────────────
body = re.sub(r'\n{3,}', '\n\n', body)

# ── 9. Write to new location ───────────────────────────────────────────────
dst_dir = 'D:/Obsidian/Main/01/Japan'
os.makedirs(dst_dir, exist_ok=True)
# Get the filename, converting smart apostrophe to standard apostrophe per vault conventions
filename = os.path.basename(src).replace('\u2019', "'")
dst = os.path.join(dst_dir, filename)

final = yaml_block + body
with open(dst, 'w', encoding='utf-8') as f:
    f.write(final)

# ── 10. Remove source file ─────────────────────────────────────────────────
os.remove(src)

print(f"Done. Written to: {dst}")
print(f"Lines: {len(final.splitlines())}")
