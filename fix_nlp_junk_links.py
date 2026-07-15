#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_nlp_junk_links.py
Remove junk links from ALL NLP notes (including NLP Forum files this time):
- [[SCORM - SCORM Explai]] lines
- [[MOC - NLP & Psychology]] bare link lines (not part of a nav property)
- [[MOC - Xxx]] bare link lines in Related Notes sections
- [[Master MOC Index]] junk links
"""

import os
import re
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# Process ALL .md files in the NLP folder, not just the target subset
NLP_DIR = r"C:\Users\awt\Sync\Obsidian\01\NLP"

# Patterns of junk link lines to remove (applied to Related Notes sections AND globally in list context)
JUNK_LINK_PATTERNS = [
    r'^\s*-\s*\[\[SCORM\s*-\s*SCORM[^\]]*\]\]\s*$',           # [[SCORM - SCORM Explai]]
    r'^\s*-\s*\[\[MOC\s*-\s*NLP\s*&\s*Psychology\]\]\s*$',     # [[MOC - NLP & Psychology]]
    r'^\s*-\s*\[\[MOC\s*-\s*[^\]]+\]\]\s*$',                   # any bare [[MOC - Xxx]] line
    r'^\s*-\s*\[\[Master MOC Index\]\]\s*$',                   # [[Master MOC Index]]
    r'^\s*-\s*\[\[Orphan File Connection Report\]\]\s*$',      # junk report link
]

def read_file(path):
    """Read UTF-8 file."""
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write_file(path, content):
    """Write UTF-8 file."""
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def is_junk_line(line):
    """Return True if the line is a junk link that should be removed."""
    return any(re.match(p, line) for p in JUNK_LINK_PATTERNS)

def process_file(filepath):
    """Process one file: remove junk link lines."""
    content = read_file(filepath)
    lines = content.split('\n')
    new_lines = []
    removed = 0

    # We process line-by-line but ONLY remove junk lines that are inside list contexts
    # (i.e., lines that start with "- [[...]]")
    for line in lines:
        if is_junk_line(line):
            removed += 1
            # Skip this line (remove it)
            continue
        new_lines.append(line)

    if removed > 0:
        # Remove trailing empty lines at end of Related Notes sections
        # (if we removed the last items, there may be extra blank lines)
        new_content = '\n'.join(new_lines)
        # Clean up multiple consecutive blank lines
        new_content = re.sub(r'\n{3,}', '\n\n', new_content)
        write_file(filepath, new_content)
        return removed
    return 0

def main():
    """Process all .md files in the NLP folder."""
    all_files = [
        fname for fname in sorted(os.listdir(NLP_DIR))
        if fname.endswith('.md') and os.path.isfile(os.path.join(NLP_DIR, fname))
    ]

    total_removed = 0
    files_updated = 0

    for fname in all_files:
        fpath = os.path.join(NLP_DIR, fname)
        removed = process_file(fpath)
        if removed > 0:
            files_updated += 1
            total_removed += removed
            print(f'  UPDATED ({removed} junk lines removed): {fname}')

    print(f'\nDone. Updated {files_updated}/{len(all_files)} files, removed {total_removed} junk lines.')

if __name__ == '__main__':
    main()
