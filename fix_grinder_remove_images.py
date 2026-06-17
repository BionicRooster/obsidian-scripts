#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_grinder_remove_images.py
Phase 1.5: Remove image embeds and strip OCR page-number artifacts.

After fix_grinder_formatting.py placed image embeds on their own lines,
this script:
  1. Removes all ![[...]] image embed lines
  2. Strips bare page-number prefixes at the start of text lines
     (e.g. "6 both clarifies..." → "both clarifies...")
  3. Collapses runs of 3+ blank lines down to 2
"""

import re
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Target file
FILE = r"D:\Obsidian\Main\09 - Full eBooks\On Deletion Phenomena in English - Grinder 1976.md"

# Page number artifact pattern: line starts with 1-3 digits, a space, then a letter.
# This matches "6 both clarifies..." but not "(1) (a)..." or "1. Deletion..." or "---".
PAGE_NUM_RE = re.compile(r'^\d{1,3} (?=[A-Za-z])')

# Image embed pattern: entire line is an Obsidian image embed
IMAGE_RE = re.compile(r'^!\[\[.*\]\]\s*$')


def clean(content: str) -> str:
    """Remove images and page-number artifacts, then normalise blank lines."""
    lines = content.split('\n')
    out = []

    for line in lines:
        # Drop image embed lines entirely
        if IMAGE_RE.match(line):
            continue

        # Strip bare page-number prefix (OCR page header bleed)
        line = PAGE_NUM_RE.sub('', line)

        out.append(line)

    result = '\n'.join(out)

    # Collapse 3+ consecutive blank lines to a single blank line
    result = re.sub(r'\n{3,}', '\n\n', result)

    return result


def main():
    print(f"Reading: {FILE}")
    with open(FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Count images before removal
    image_count = len(IMAGE_RE.findall('\n'.join(content.split('\n'))))
    original_lines = content.count('\n')
    print(f"Original: {original_lines} lines, {image_count} image embeds")

    fixed = clean(content)

    new_lines = fixed.count('\n')
    remaining_images = len(re.findall(r'^!\[\[', fixed, re.MULTILINE))
    print(f"After:    {new_lines} lines | {remaining_images} image embeds remaining")

    print("Writing...")
    with open(FILE, 'w', encoding='utf-8') as f:
        f.write(fixed)
    print("Done.")


if __name__ == '__main__':
    main()
