#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fix_nlp_related_links.py
Second-pass cleanup of NLP related notes that got converted from
  "Title|Title - Description" format into [[Title - Description]]
  but should be [[Title]] — Description

Also fixes bare "- Title - Description" lines that were wrapped as
  [[Title - Description]] where the " - Description" is not part of the title.

Known NLP note titles in the folder (to help split correctly):
"""

import os
import re
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

NLP_DIR = r"D:\Obsidian\Main\01\NLP"

# Known file titles in the NLP folder (filename without .md)
# We'll build this dynamically from the filesystem
def get_known_titles():
    """Return a set of known note titles (filenames without .md extension)."""
    titles = set()
    for fname in os.listdir(NLP_DIR):
        if fname.endswith('.md'):
            titles.add(fname[:-3])
    return titles

KNOWN_TITLES = get_known_titles()

def read_file(path):
    """Read a file with UTF-8 encoding."""
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write_file(path, content):
    """Write a file with UTF-8 encoding."""
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def fix_related_link_line(line):
    """
    Given a single line from a Related Notes section, fix:
    1. [[Title - Description text]] -> [[Title]] — Description text
       (when "Title" is a known note and " - Description" is extra)
    2. [[Title - Description]] where entire string is NOT a known title
       but "Title" portion IS known
    Returns the corrected line.
    """
    # Match [[anything]] pattern in a list item
    m = re.match(r'^(-\s*)\[\[([^\]]+)\]\]\s*(.*)$', line)
    if not m:
        return line

    prefix = m.group(1)        # "- " portion
    link_text = m.group(2)     # content inside [[...]]
    suffix = m.group(3)        # anything after the ]]

    # If the link text is already a known title, no fix needed
    if link_text in KNOWN_TITLES:
        return line

    # Try to find a known title that is a prefix of link_text
    # Pattern: "Known Title - Description" or "Known Title — Description"
    best_match = None
    best_match_len = 0

    for title in KNOWN_TITLES:
        # Check if link_text starts with "title - " or "title — "
        for sep in [' - ', ' — ', ': ']:
            candidate = title + sep
            if link_text.startswith(candidate) and len(title) > best_match_len:
                best_match = title
                best_match_desc = link_text[len(candidate):]
                best_match_len = len(title)
                break
            # Also check case-insensitive
            if link_text.lower().startswith(candidate.lower()) and len(title) > best_match_len:
                best_match = title
                best_match_desc = link_text[len(candidate):]
                best_match_len = len(title)
                break

    if best_match:
        # Rebuild as [[Known Title]] — Description
        desc = best_match_desc.strip()
        if desc:
            return f'{prefix}[[{best_match}]] — {desc}'
        else:
            return f'{prefix}[[{best_match}]]'

    # No known title found as prefix - leave as-is
    return line

def process_file(filepath, filename):
    """Process one file: fix Related Notes links."""
    content = read_file(filepath)
    original = content

    # Find all Related sections and process their lines
    lines = content.split('\n')
    new_lines = []
    in_related = False

    for line in lines:
        # Detect Related section headers
        if re.match(r'^## Related', line, re.IGNORECASE):
            in_related = True
            new_lines.append(line)
            continue

        # Detect next section header (ends Related section)
        if in_related and re.match(r'^## ', line):
            in_related = False

        if in_related:
            fixed = fix_related_link_line(line)
            new_lines.append(fixed)
        else:
            new_lines.append(line)

    new_content = '\n'.join(new_lines)

    if new_content != original:
        write_file(filepath, new_content)
        return 'UPDATED'
    return 'no changes'

def main():
    """Process all NLP .md files."""
    skip_prefixes = ("NLP Forum —", "NLP Master Class")
    skip_exact = {
        "NLP-CompuServe Forum Member Directory (February 1994).md",
        "Time Line Therapy.md", "What's Wired In.md",
        "TransDerivational Search.md",
        "Transcript of a CompUSERVE Thread On The Use Of NLP In Training.md",
        "Rapport with Self.md",
        "NLP Forum — Rapport with Self (July 1995).md",
        "SCORE in Business.md",
    }

    files = []
    for fname in sorted(os.listdir(NLP_DIR)):
        fpath = os.path.join(NLP_DIR, fname)
        if os.path.isdir(fpath):
            continue
        if not fname.endswith('.md'):
            continue
        if fname in skip_exact:
            continue
        if any(fname.startswith(p) for p in skip_prefixes):
            continue
        files.append((fpath, fname))

    updated = 0
    for fpath, fname in files:
        status = process_file(fpath, fname)
        if status == 'UPDATED':
            updated += 1
            print(f'  UPDATED: {fname}')

    print(f'\nDone. Updated {updated}/{len(files)} files.')

if __name__ == '__main__':
    main()
