#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_grinder_formatting.py
Fixes structural formatting issues in the Grinder dissertation markdown file.

The OCR pipeline collapsed page content into single lines. This script restores:
 - Proper YAML frontmatter tag list
 - Image embeds (![[image]]) on their own lines (page boundaries)
 - --- HR separators on their own lines
 - Inline heading markers (## / ###) split to new lines
 - Excessive blank lines collapsed to max 2
"""

import re
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# File to fix
FILE = r"D:\Obsidian\Main\09 - Full eBooks\On Deletion Phenomena in English - Grinder 1976.md"

def fix_structural(content):
    """Restore structural elements that got collapsed onto single lines."""

    # ── Fix 1: Frontmatter tags ────────────────────────────────────────────────
    # Was collapsed to: tags: - pdf-import - NLP - Linguistics - MetaModel ...
    old_tags = 'tags: - pdf-import - NLP - Linguistics - MetaModel - Deletion - GenerativeGrammar'
    new_tags = 'tags:\n  - pdf-import\n  - NLP\n  - Linguistics\n  - MetaModel\n  - Deletion\n  - GenerativeGrammar'
    content = content.replace(old_tags, new_tags)

    # ── Fix 2: Frontmatter close --- merged with first content heading ─────────
    # Pattern: line starting with --- immediately followed by space and # heading
    content = re.sub(r'^(---) (#)', r'\1\n\n\2', content, flags=re.MULTILINE)

    # ── Fix 3: Image embeds embedded in prose - add newline BEFORE ![[─────────
    # Matches ![[00 - Images/ when preceded by non-newline content
    content = re.sub(
        r'(?<!\n)(!\[\[00 - Images/)',
        r'\n\n\1',
        content
    )

    # ── Fix 4: Image embeds embedded in prose - add newline AFTER ]] ──────────
    # Matches ]] at end of image embed when followed by non-newline content
    content = re.sub(
        r'(!\[\[00 - Images/[^\]]+\]\])(?!\n)',
        r'\1\n\n',
        content
    )

    # ── Fix 5: Inline --- separators embedded in prose ─────────────────────────
    # Pattern: non-whitespace, then space-dash-dash-dash-space, then non-whitespace
    # Avoids splitting frontmatter delimiters (those are already on their own lines)
    content = re.sub(r'(?<=\S) --- (?=\S)', '\n\n---\n\n', content)

    # ── Fix 6: Inline heading markers (## and ###) embedded in prose ───────────
    # Pattern: word content, then space ## or ### space, then capital letter
    # This restores chapter headings that got merged into preceding text
    content = re.sub(r'(?<=\S) (#{2,4}) (?=[A-Z*])', r'\n\n\1 ', content)

    # ── Fix 7: Collapse runs of 3+ blank lines to exactly 2 ───────────────────
    content = re.sub(r'\n{3,}', '\n\n', content)

    return content


def report_long_lines(content, threshold=500):
    """Print a summary of remaining long lines."""
    lines = content.split('\n')
    long_lines = [(i + 1, len(l), l[:100]) for i, l in enumerate(lines) if len(l) > threshold]
    print(f"\nLines over {threshold} chars after fixes: {len(long_lines)}")
    for lineno, length, preview in long_lines[:20]:
        print(f"  Line {lineno:5d} ({length:5d} chars): {preview}...")
    if len(long_lines) > 20:
        print(f"  ... and {len(long_lines) - 20} more")
    return long_lines


def main():
    print(f"Reading: {FILE}")
    with open(FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Count original lines and long-line stats
    original_lines = content.count('\n')
    original_long = sum(1 for l in content.split('\n') if len(l) > 500)
    print(f"Original: {original_lines} lines, {original_long} over 500 chars")

    # Apply fixes
    print("Applying structural fixes...")
    fixed = fix_structural(content)

    new_lines = fixed.count('\n')
    print(f"After fixes: {new_lines} lines (+{new_lines - original_lines} new lines added)")

    # Report remaining long lines
    report_long_lines(fixed, threshold=500)

    # Write result
    print(f"\nWriting fixed file...")
    with open(FILE, 'w', encoding='utf-8') as f:
        f.write(fixed)
    print("Done.")


if __name__ == '__main__':
    main()
