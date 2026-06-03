#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
reformat_nlp.py
Batch reformats legacy NLP notes in D:/Obsidian/Main/01/NLP/

Rules:
 1. Remove NLP_Psy tag, ensure NLP tag present
 2. Fix nav property to "[[01/NLP]] | [[MOC - NLP & Psychology]]"
 3. Fix breadcrumb line (first non-frontmatter content line)
 4. Add title to YAML if missing
 5. Add description to YAML if missing
 6. Fix Related Notes (plain text → wikilinks, pipe-style wikilinks → clean)
 7. Forum threads: remove raw file header block, add intro block, fix message headers
 8. Remove junk MOC lines from Related Notes (bare "MOC - Xxx" lines)
 9. Fix piped wikilinks [[A|A]] → [[A]] and bare paths like [[path/Note|Note]] → [[Note]]
"""

import os
import re
import sys

# Force stdout to UTF-8 so arrow characters don't crash on Windows cp1252 console
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# ─────────────────────────────── constants ────────────────────────────────────

# Vault root for the NLP folder
NLP_DIR = r"D:\Obsidian\Main\01\NLP"

# Files to SKIP (already clean or explicitly excluded)
SKIP_PREFIXES = ("NLP Forum —", "NLP Master Class")
SKIP_EXACT = {
    "NLP-CompuServe Forum Member Directory (February 1994).md",
    "Time Line Therapy.md",
    "What's Wired In.md",
    "TransDerivational Search.md",
    "Transcript of a CompUSERVE Thread On The Use Of NLP In Training.md",
    "Rapport with Self.md",
    "NLP Forum — Rapport with Self (July 1995).md",
    "SCORE in Business.md",
}
SKIP_EXTENSIONS = {".base", ".pdf"}

# The correct nav value
CORRECT_NAV = '"[[01/NLP]] | [[MOC - NLP & Psychology]]"'

# The correct breadcrumb line
CORRECT_BREADCRUMB = "[[01/NLP]] | [[MOC - NLP & Psychology]]"

# Bare MOC lines to strip from Related Notes (these are garbage auto-generated links)
JUNK_MOC_PATTERNS = [
    r"^- MOC - Finance & Investment\s*$",
    r"^- MOC - Reading & Literature\s*$",
    r"^- MOC - Technology & Computing\s*$",
    r"^- MOC - Home & Practical Life\s*$",
    r"^- MOC - Music & Recorders?\s*$",
    r"^- MOC - Soccer\s*$",
    r"^- MOC - Social Issues & Culture\s*$",
    r"^- MOC - Science & Nature\s*$",
    r"^- MOC - Health & Nutrition\s*$",
    r"^- MOC - Travel & Exploration\s*$",
    r"^- MOC - NLP & Psychology\s*$",
    r"^- MOC - Bahá'í Faith\s*$",
    r"^- MOC - Recipes\s*$",
    r"^- MOC - [A-Za-z &]+\s*$",  # catch-all for bare MOC lines
    r"^- Master MOC Index\s*$",
]

# ────────────────────────────── helper functions ──────────────────────────────

def read_file(path):
    """Read a file with UTF-8 encoding, return text string."""
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write_file(path, content):
    """Write a file with UTF-8 encoding (no BOM)."""
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def is_forum_thread(content):
    """Return True if the file body contains a CompuServe file header block."""
    return bool(re.search(r"^File\s*:\s*'[A-Z0-9]+\.THD'", content, re.MULTILINE))

def split_frontmatter(content):
    """
    Split content into (frontmatter_str, body_str).
    frontmatter_str includes the --- delimiters.
    If no frontmatter, returns ('', content).
    """
    # Match opening --- at start, then any content, then closing ---
    m = re.match(r'^(---\s*\n.*?\n---\s*\n?)(.*)', content, re.DOTALL)
    if m:
        return m.group(1), m.group(2)
    return '', content

def parse_yaml_lines(fm_str):
    """
    Return the list of lines between the --- delimiters (not including them).
    """
    lines = fm_str.split('\n')
    # Remove first line (---) and last non-empty lines (---)
    inner = []
    in_block = False
    for line in lines:
        if line.strip() == '---':
            if not in_block:
                in_block = True
                continue
            else:
                break
        if in_block:
            inner.append(line)
    return inner

def fix_yaml(fm_str, filename, body):
    """
    Fix the YAML frontmatter:
    - Remove NLP_Psy from tags, add NLP if not present
    - Fix nav value
    - Add title if missing
    - Add description if missing (derived from content)
    Returns updated frontmatter string.
    """
    # Work with the lines inside the frontmatter
    lines = fm_str.split('\n')

    # We'll rebuild the YAML content
    # First, parse into a simple structure tracking tags, nav, title, description
    yaml_lines = []          # lines inside ---, to be rebuilt
    has_title = False        # whether 'title:' key exists
    has_description = False  # whether 'description:' key exists
    has_nav = False          # whether 'nav:' key exists
    has_tags = False         # whether 'tags:' key exists
    has_nlp_tag = False      # whether NLP tag is in the list

    # Remove outer --- markers to work with inner content
    inner_text = re.sub(r'^---\s*\n', '', fm_str, count=1)
    inner_text = re.sub(r'\n---\s*$', '', inner_text.rstrip())
    inner_lines = inner_text.split('\n')

    # Pass 1: detect what exists and find NLP_Psy
    in_tags_block = False    # whether we're inside the tags: list
    new_inner_lines = []

    for line in inner_lines:
        stripped = line.strip()

        # Detect keys at top level (no leading spaces)
        if re.match(r'^title\s*:', line):
            has_title = True
            in_tags_block = False
            new_inner_lines.append(line)
        elif re.match(r'^description\s*:', line):
            has_description = True
            in_tags_block = False
            new_inner_lines.append(line)
        elif re.match(r'^nav\s*:', line):
            has_nav = True
            in_tags_block = False
            # Replace with correct nav
            new_inner_lines.append(f'nav: {CORRECT_NAV}')
        elif re.match(r'^tags\s*:', line):
            has_tags = True
            in_tags_block = True
            new_inner_lines.append(line)
        elif in_tags_block and re.match(r'^\s*-\s+', line):
            # This is a tag list item
            tag_val = re.sub(r'^\s*-\s+', '', line).strip()
            if tag_val == 'NLP_Psy':
                # Skip this tag (remove it)
                continue
            elif tag_val == 'NLP':
                has_nlp_tag = True
            new_inner_lines.append(line)
        else:
            # Not a tag item - if we were in tags block, we've left it
            if in_tags_block and not re.match(r'^\s', line):
                in_tags_block = False
            new_inner_lines.append(line)

    # If NLP tag was missing, add it to the tags section
    if has_tags and not has_nlp_tag:
        # Find the tags: line and insert NLP after it
        result_lines = []
        for line in new_inner_lines:
            result_lines.append(line)
            if re.match(r'^tags\s*:', line):
                result_lines.append('  - NLP')
        new_inner_lines = result_lines

    # If no tags section existed at all, add one
    if not has_tags:
        new_inner_lines.insert(0, 'tags:\n  - NLP')

    # If no nav existed, add it
    if not has_nav:
        # Insert nav after tags block
        result_lines = []
        added_nav = False
        in_tags = False
        for i, line in enumerate(new_inner_lines):
            result_lines.append(line)
            if re.match(r'^tags\s*:', line):
                in_tags = True
            elif in_tags and not re.match(r'^\s*-\s+', line) and not added_nav:
                # We've left the tags block, insert nav before this line
                result_lines.insert(len(result_lines)-1, f'nav: {CORRECT_NAV}')
                added_nav = True
                in_tags = False
        if not added_nav:
            result_lines.append(f'nav: {CORRECT_NAV}')
        new_inner_lines = result_lines

    # If no title, add it (derive from filename)
    if not has_title:
        title_val = filename.replace('.md', '')
        # Clean up truncated filenames that end with a period or are clearly cut off
        new_inner_lines.insert(0, f'title: "{title_val}"')

    # If no description, derive a short one from the body content
    if not has_description:
        desc = derive_description(filename, body)
        if desc:
            # Find insertion point: after title if present, or at start
            result_lines = []
            inserted = False
            for line in new_inner_lines:
                result_lines.append(line)
                if re.match(r'^title\s*:', line) and not inserted:
                    result_lines.append(f'description: "{desc}"')
                    inserted = True
            if not inserted:
                result_lines.insert(0, f'description: "{desc}"')
            new_inner_lines = result_lines

    # Reconstruct the frontmatter with --- delimiters
    rebuilt = '---\n' + '\n'.join(new_inner_lines) + '\n---\n'
    return rebuilt

def derive_description(filename, body):
    """
    Generate a short description (1-2 sentences) based on filename and body content.
    Keeps it generic and safe; won't be perfect but better than nothing.
    """
    name = filename.replace('.md', '')

    # For forum threads, use the subject
    m = re.search(r"Subject\s*:\s*(.+)", body)
    if m:
        subject = m.group(1).strip()
        return f"CompuServe AI Expert+ Forum thread on the topic of {subject}."

    # For technique files, generic description
    if re.search(r'^\d+\s*[\.\)]', body, re.MULTILINE):
        return f"NLP technique: {name}. Step-by-step procedure for NLP practitioners."

    # For image-only files
    if re.match(r'\s*!\[\[', body.strip()):
        return f"Diagram or image related to the NLP concept of {name}."

    # Extract first meaningful sentence from body
    # Strip wikilinks and markdown syntax for cleaner text
    clean_body = re.sub(r'\[\[.*?\]\]', '', body)
    clean_body = re.sub(r'#\w+', '', clean_body)
    clean_body = re.sub(r'\*+', '', clean_body)
    clean_body = re.sub(r'^#{1,6}\s+', '', clean_body, flags=re.MULTILINE)
    clean_body = re.sub(r'!\[\[.*?\]\]', '', clean_body)
    clean_body = re.sub(r'\[.*?\]\(.*?\)', '', clean_body)
    # Get first non-empty, non-header line
    for line in clean_body.split('\n'):
        line = line.strip()
        if len(line) > 30 and not line.startswith('---') and not line.startswith('File :'):
            # Truncate to ~120 chars
            if len(line) > 120:
                line = line[:117] + '...'
            # Escape any quotes
            line = line.replace('"', "'")
            return line

    return f"NLP note on the topic of {name}."

def fix_breadcrumb(body):
    """
    Fix the first non-blank line of the body.
    If it contains [[NLP]] or similar old-style breadcrumbs, replace it.
    Don't add a duplicate if the correct breadcrumb is already there.
    """
    lines = body.split('\n')

    # Find the first non-blank line
    first_content_idx = None
    for i, line in enumerate(lines):
        if line.strip():
            first_content_idx = i
            break

    if first_content_idx is None:
        # Body is all whitespace - add breadcrumb at top
        return CORRECT_BREADCRUMB + '\n\n' + body

    first_line = lines[first_content_idx].strip()

    # Check if already correct
    if first_line == CORRECT_BREADCRUMB:
        return body

    # Patterns that indicate an old-style breadcrumb line to replace
    old_breadcrumb_patterns = [
        r'^\[\[NLP\]\]\s*\|?\s*(?:MOC - NLP & Psychology)?$',
        r'^\[\[NLP\]\]\s+(?:MOC - NLP & Psychology|#\[\[)',
        r'^\[\[NLP\]\]$',
        r'^\[\[NLP\]\]\s*\|',
    ]

    is_old_breadcrumb = any(re.match(p, first_line) for p in old_breadcrumb_patterns)

    if is_old_breadcrumb:
        # Replace that line with the correct breadcrumb
        # But if the old breadcrumb had extra content after it on the same line
        # (like "[[NLP]] Circle of Excellence"), preserve that content on the next line
        rest_of_line = re.sub(r'^\[\[NLP\]\]\s*\|?\s*(?:MOC - NLP & Psychology)?\s*', '', lines[first_content_idx]).strip()

        # Remove tags like #[[Psychology]] that shouldn't be in breadcrumb line
        rest_of_line = re.sub(r'#\[\[[A-Za-z]+\]\]', '', rest_of_line).strip()

        new_lines = lines[:]
        if rest_of_line:
            # There's additional content after [[NLP]] - put breadcrumb then content
            new_lines[first_content_idx] = CORRECT_BREADCRUMB
            new_lines.insert(first_content_idx + 1, '')
            new_lines.insert(first_content_idx + 2, rest_of_line)
        else:
            new_lines[first_content_idx] = CORRECT_BREADCRUMB
        return '\n'.join(new_lines)

    # The first line is content (not a breadcrumb) - prepend the breadcrumb
    # But first check if it starts with a file header (forum thread) - don't prepend there
    if re.match(r'^File\s*:', first_line):
        return body

    # Check if it's already a heading or has content - prepend breadcrumb
    # Only prepend if no breadcrumb-like line already at top
    if '[[01/NLP]]' not in first_line and '[[MOC - NLP & Psychology]]' not in first_line:
        return CORRECT_BREADCRUMB + '\n\n' + body

    return body

def fix_related_notes(body):
    """
    In the ## Related Notes section:
    1. Remove bare "MOC - Xxx" lines
    2. Fix plain-text links: "- Some Title" that clearly need brackets
    3. Fix piped links: [[Path/To/Note|Display]] → [[Display]]
    4. Fix [[A|A]] → [[A]]
    5. Fix old path-style links: - 20 - Permanent Notes/Title|Title → [[Title]]
    6. Remove bare folder links like [[10 - Clippings]]
    """
    # Find the Related Notes section
    # It may be "## Related Notes", "## Related NLP Xxx", etc.
    rn_match = re.search(r'(## Related\s+(?:Notes|NLP[^\n]*)[^\n]*\n)(.*?)(\Z|(?=\n## ))',
                          body, re.DOTALL | re.IGNORECASE)
    if not rn_match:
        # Try to find a section that starts with ## Related
        rn_match = re.search(r'(## Related[^\n]*\n)(.*?)(\Z|(?=\n## ))',
                              body, re.DOTALL | re.IGNORECASE)

    if not rn_match:
        return body

    section_header = rn_match.group(1)
    section_content = rn_match.group(2)
    section_after = rn_match.group(3)

    # Process each line of the section content
    lines = section_content.split('\n')
    new_lines = []

    for line in lines:
        stripped = line.strip()

        # Skip empty lines (keep them)
        if not stripped:
            new_lines.append(line)
            continue

        # Check if it matches a junk MOC pattern
        is_junk = any(re.match(p, stripped) for p in JUNK_MOC_PATTERNS)
        if is_junk:
            continue  # Remove junk MOC lines

        # Skip bare folder links like [[10 - Clippings]] or [[00 - Home Dashboard/...]]
        if re.match(r'^-?\s*\[\[\d+\s*-\s*', stripped):
            continue

        # Fix piped path links: [[path/to/Note|Display Text]] → [[Display Text]]
        # e.g., - 20 - Permanent Notes/How the coronavirus|How the coronavirus
        m = re.match(r'^(-\s*)([^\[|]+)\|([^\]]+)$', stripped)
        if m and '[' not in m.group(2):
            # It's a bare "path|display" format (not inside [[ ]])
            display = m.group(3).strip()
            new_lines.append(f'- [[{display}]]')
            continue

        # Fix [[Path/Note|Display]] → [[Display]]
        line = re.sub(r'\[\[[^\]|]+\|([^\]]+)\]\]', r'[[\1]]', line)

        # Fix [[Display|Display]] (pipe where both sides are same) → [[Display]]
        line = re.sub(r'\[\[([^\]|]+)\|\1\]\]', r'[[\1]]', line)

        # Fix bare "- Plain Text" that should be a wikilink
        # Only if it doesn't already have [[ ]] and looks like a note title
        bare_match = re.match(r'^-\s+([^[\n<*_`]+)$', stripped)
        if bare_match:
            candidate = bare_match.group(1).strip()
            # If it looks like a proper note title (title case or known pattern)
            # and doesn't start with lowercase "a ", "the ", "in ", etc.
            # We'll be conservative: only wrap if it has capital letters
            if candidate and candidate[0].isupper() and len(candidate) > 3:
                # Check if it's not already a wikilink
                if '[[' not in candidate and ']]' not in candidate:
                    new_lines.append(f'- [[{candidate}]]')
                    continue

        new_lines.append(line)

    # Remove trailing empty lines from the section
    while new_lines and not new_lines[-1].strip():
        new_lines.pop()

    new_section_content = '\n'.join(new_lines)
    if new_section_content:
        new_section_content += '\n'

    # Reconstruct
    start = rn_match.start()
    end = rn_match.end()
    new_body = body[:start] + section_header + new_section_content + section_after
    return new_body

def fix_forum_thread(body):
    """
    For forum thread files:
    1. Remove the raw file header block (File:, Type:, Forum:, Section:, Subject:, Created:, Last update:)
    2. Remove old [[NLP]] breadcrumb lines and any related notes group before the thread
    3. Format message headers as ### Message N
    4. Format To/From/Created lines as bold metadata
    5. Remove long separator lines (20+ dashes)
    6. Add an intro block
    Returns (cleaned_body, participants, subject, created_date)
    """
    # Extract metadata from header
    subject_m = re.search(r'^Subject\s*:\s*(.+)', body, re.MULTILINE)
    created_m = re.search(r'^Created\s*:\s*(.+)', body, re.MULTILINE)
    forum_m   = re.search(r'^Forum\s*:\s*(.+)', body, re.MULTILINE)

    subject   = subject_m.group(1).strip() if subject_m else "Unknown Subject"
    created   = created_m.group(1).strip() if created_m else ""

    # Remove the entire file header block (lines at start before first message)
    # The header ends before the first message
    body = re.sub(
        r'^(?:File|Type|Forum|Section|Subject|Created|Last update)\s*:.*\n',
        '', body, flags=re.MULTILINE
    )

    # Remove old [[NLP]] breadcrumb lines (including partial ones)
    body = re.sub(r'^\s*\[\[NLP\]\][^\n]*\n?', '', body, flags=re.MULTILINE)

    # Remove any "## Related Andrew Moreno Posts" type pre-thread sections
    # (These will be re-examined below; for now strip them since they're pre-thread fluff
    #  unless they have actual links. We'll be conservative and keep them if they have [[]])

    # Collect participants from To:/From: lines
    participants = set()
    for m in re.finditer(r'(?:To|From)\s*:\s*([A-Za-z][\w\s\.\-\']+?)(?:\s+\d{5,}|\s*$)',
                          body, re.MULTILINE):
        name = m.group(1).strip()
        # Clean up common junk
        name = re.sub(r'\s+\d+,\d+.*$', '', name).strip()
        if name and len(name) > 2 and name.lower() not in ('all', 'to', 'from'):
            participants.add(name)

    # Now process message headers
    # Pattern 1: ==== Message N ==== Subject ===...===
    # Pattern 2: Message N Subject =
    # Pattern 3: ===============...=== (separator lines of = chars)

    def format_message_header(m):
        """Replace message header with ### Message N"""
        num = m.group(1)
        return f'\n### Message {num}\n'

    # Handle ==== Message N ==== Subject ====...====
    body = re.sub(
        r'={2,}\s*Message\s+(\d+)\s*={2,}[^\n]*={2,}',
        format_message_header,
        body
    )

    # Handle Message N Subject =  (simpler pattern)
    body = re.sub(
        r'^Message\s+(\d+)\s+[A-Z][^\n=]*=+\s*$',
        format_message_header,
        body, flags=re.MULTILINE
    )

    # Handle === separator lines (20+ = chars)
    body = re.sub(r'^={20,}\s*$', '', body, flags=re.MULTILINE)

    # Handle long dash separator lines (20+ dashes) - just remove them
    # But keep short --- separators (Obsidian HR)
    body = re.sub(r'^-{20,}\s*$', '', body, flags=re.MULTILINE)

    # Format To/From/Created metadata lines inside messages
    # These look like:
    # To : Name\nFrom : Name\nCreated : date
    # or on one line: To : Name From : Name
    # or: To : All From : Klaus Marwitz 100273,2057

    def format_msg_metadata(m):
        """Format the To/From/Created block inside a message."""
        to_name   = (m.group(1) or '').strip()
        from_name = (m.group(2) or '').strip()
        date_val  = (m.group(3) or '').strip()

        # Clean CompuServe IDs (nnnnnn,nnnn)
        to_name   = re.sub(r'\s+\d+,\d+\s*$', '', to_name).strip()
        from_name = re.sub(r'\s+\d+,\d+\s*$', '', from_name).strip()
        # Clean "N replies" suffix
        to_name   = re.sub(r'\s+\d+\s+repl\w*\s*$', '', to_name, flags=re.IGNORECASE).strip()
        from_name = re.sub(r'\s+\d+\s+repl\w*\s*$', '', from_name, flags=re.IGNORECASE).strip()

        parts = []
        if from_name:
            parts.append(f'**From:** {from_name}')
        if to_name:
            parts.append(f'**To:** {to_name}')
        if date_val:
            parts.append(f'**Date:** {date_val}')

        return '  \n'.join(parts) + '\n\n'

    # Pattern: To : X From : Y Created : date  (all on consecutive lines)
    body = re.sub(
        r'^To\s*:\s*(.+?)\s*\n\s*From\s*:\s*(.+?)\s*\n\s*Created\s*:\s*(.+?)\s*\n',
        format_msg_metadata,
        body, flags=re.MULTILINE
    )

    # Pattern: To : X From : Y (on same line)
    body = re.sub(
        r'^To\s*:\s*(.+?)\s+From\s*:\s*(.+?)\s*(?:Created\s*:\s*(.+?))?$',
        format_msg_metadata,
        body, flags=re.MULTILINE
    )

    # Any remaining standalone Created : lines (from message headers)
    body = re.sub(
        r'^Created\s*:\s*(\d{2}-\w+-\d{4}[^\n]*)\s*(?:\d+\s+repl\w*)?\s*$',
        r'**Date:** \1\n',
        body, flags=re.MULTILINE
    )

    # Clean up multiple consecutive blank lines → max 2
    body = re.sub(r'\n{4,}', '\n\n\n', body)

    # Strip leading whitespace from body
    body = body.lstrip('\n')

    participants_str = ', '.join(sorted(participants)) if participants else 'Various'

    return body, participants_str, subject, created

def process_file(filepath, filename):
    """
    Process a single NLP file: read, determine type, apply fixes, write back.
    Returns a dict describing what was done.
    """
    changes = []  # list of change descriptions

    # Read file
    content = read_file(filepath)

    # Split into frontmatter and body
    fm_str, body = split_frontmatter(content)

    # Determine file type
    is_forum = is_forum_thread(body) or is_forum_thread(fm_str)

    # Check if it's basically just an image embed
    body_stripped = re.sub(r'\[\[.*?\]\]', '', body).strip()
    body_stripped = re.sub(r'!\[\[.*?\]\]', '', body_stripped).strip()
    body_stripped = re.sub(r'---', '', body_stripped).strip()
    body_stripped = re.sub(r'## Related.*', '', body_stripped, flags=re.DOTALL).strip()
    is_image_only = (
        '![[' in body and
        len(body_stripped) < 50
    )

    # ── Step 1: Fix YAML frontmatter ──────────────────────────────────────────
    if fm_str:
        new_fm = fix_yaml(fm_str, filename, body)
        if new_fm != fm_str:
            changes.append('YAML: fixed tags/nav/title/description')
        fm_str = new_fm
    else:
        # No frontmatter at all - create one
        desc = derive_description(filename, body)
        title_val = filename.replace('.md', '')
        fm_str = (
            f'---\n'
            f'title: "{title_val}"\n'
            f'description: "{desc}"\n'
            f'tags:\n  - NLP\n'
            f'nav: {CORRECT_NAV}\n'
            f'---\n'
        )
        changes.append('YAML: created new frontmatter')

    # ── Step 2: Forum thread processing ───────────────────────────────────────
    if is_forum and not is_image_only:
        new_body, participants, subject, created_date = fix_forum_thread(body)

        # Build intro block
        intro = (
            f'{CORRECT_BREADCRUMB}\n\n'
            f'*Archived forum thread from the CompuServe AI Expert+ Forum, '
            f'NeuroLinguistic Section.*\n\n'
            f'**Participants:** {participants}\n\n'
            f'**Topics:** {subject}\n\n'
            f'---\n\n'
        )

        # Check if intro already exists
        if CORRECT_BREADCRUMB not in new_body[:200]:
            new_body = intro + new_body
        elif '*Archived forum thread' not in new_body[:500]:
            # Has breadcrumb but no intro block
            new_body = re.sub(
                re.escape(CORRECT_BREADCRUMB),
                intro.rstrip('\n'),
                new_body, count=1
            )

        if new_body != body:
            changes.append('Forum: reformatted thread structure')
        body = new_body

        # Update YAML with source and created if missing
        if 'CompuServe' not in fm_str:
            fm_str = fm_str.replace(
                '\n---\n',
                f'\nsource: "CompuServe AI Expert+ Forum, NeuroLinguistic Section"\n---\n',
                1
            )
            changes.append('Forum: added source to YAML')

    # ── Step 3: Fix breadcrumb (for non-forum files, or forum files already done) ─
    elif not is_forum and not is_image_only:
        new_body = fix_breadcrumb(body)
        if new_body != body:
            changes.append('Breadcrumb: fixed')
        body = new_body
    elif is_image_only:
        # For image-only files, just ensure breadcrumb is present
        new_body = fix_breadcrumb(body)
        if new_body != body:
            changes.append('Breadcrumb: fixed (image file)')
        body = new_body

    # ── Step 4: Fix Related Notes section ────────────────────────────────────
    new_body = fix_related_notes(body)
    if new_body != body:
        changes.append('Related Notes: fixed links')
    body = new_body

    # ── Step 5: Final cleanup ─────────────────────────────────────────────────
    # Remove any remaining raw #[[Psychology]] tags in body
    new_body = re.sub(r'#\[\[(\w+)\]\]', r'#\1', body)
    if new_body != body:
        changes.append('Cleanup: removed #[[Tag]] style tags')
    body = new_body

    # Remove any "Andrew Moreno Posts" pre-thread section that has only bare links
    # (These are from the Anchor Point file and similar)

    # Reassemble
    new_content = fm_str + body

    # Determine file type label
    if is_forum:
        ftype = 'Forum Thread'
    elif is_image_only:
        ftype = 'Image/Diagram'
    elif re.search(r'^\d+\s*[\.\)]\s*\*?\*?', body, re.MULTILINE):
        ftype = 'Technique/Procedure'
    else:
        ftype = 'Article/Clipping'

    # Write file if changed
    if new_content != content:
        write_file(filepath, new_content)
        status = 'UPDATED'
    else:
        status = 'no changes'

    return {
        'filename': filename,
        'type': ftype,
        'status': status,
        'changes': '; '.join(changes) if changes else 'none'
    }

# ─────────────────────────────── main ─────────────────────────────────────────

def main():
    """Main entry point: enumerate files, process each, print summary."""

    # Get all .md files in the NLP directory (flat, no subdirs)
    all_files = []
    for fname in sorted(os.listdir(NLP_DIR)):
        fpath = os.path.join(NLP_DIR, fname)

        # Skip directories
        if os.path.isdir(fpath):
            continue

        # Skip non-.md files
        _, ext = os.path.splitext(fname)
        if ext.lower() in SKIP_EXTENSIONS:
            continue
        if ext.lower() != '.md':
            continue

        # Skip excluded files
        if fname in SKIP_EXACT:
            continue

        # Skip files starting with excluded prefixes
        skip = False
        for prefix in SKIP_PREFIXES:
            if fname.startswith(prefix):
                skip = True
                break
        if skip:
            continue

        all_files.append((fpath, fname))

    print(f"Found {len(all_files)} files to process.\n")

    # Process each file
    results = []
    for i, (fpath, fname) in enumerate(all_files, 1):
        print(f"[{i:3d}/{len(all_files)}] Processing: {fname}")
        try:
            result = process_file(fpath, fname)
            results.append(result)
            print(f"         -> {result['status']}: {result['changes']}")
        except Exception as e:
            error_msg = str(e)
            results.append({
                'filename': fname,
                'type': 'ERROR',
                'status': 'ERROR',
                'changes': error_msg
            })
            print(f"         -> ERROR: {error_msg}")

    # Print summary table
    print("\n" + "="*100)
    print("SUMMARY")
    print("="*100)
    print(f"{'#':<4} {'Filename':<50} {'Type':<20} {'Status':<10} {'Changes'}")
    print("-"*100)

    updated_count = 0
    error_count = 0

    for i, r in enumerate(results, 1):
        fname_short = r['filename'][:48] + '..' if len(r['filename']) > 50 else r['filename']
        changes_short = r['changes'][:40] + '..' if len(r['changes']) > 42 else r['changes']
        print(f"{i:<4} {fname_short:<50} {r['type']:<20} {r['status']:<10} {changes_short}")
        if r['status'] == 'UPDATED':
            updated_count += 1
        elif r['status'] == 'ERROR':
            error_count += 1

    print("="*100)
    print(f"Total: {len(results)} files | Updated: {updated_count} | No changes: {len(results)-updated_count-error_count} | Errors: {error_count}")

    return 0 if error_count == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
