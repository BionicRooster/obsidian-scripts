#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
convert_nlp_forum_dec1994.py
Extracts 25 CompuServe NLP forum threads from December 1994 out of NLP-FRUM.docx
and writes them as individual Obsidian markdown notes.

Threads with the same subject are combined into a single file.
"""

import docx
import re
import os
from datetime import datetime

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

DOCX_PATH = r'D:\Documents\NLP\converted\NLP-FRUM.docx'
OUTPUT_DIR = r'C:\Users\awt\Sync\Obsidian\01\NLP'

# Thread IDs to include (skip 2C88=Time Line Therapy and 2CCC=NLP World)
THREADS_TO_INCLUDE = {
    '2CB9', '2CE1', '2CE9', '2CF0', '2CF6', '2CF7', '2CFA', '2CFB',
    '2D02', '2D04', '2D06', '2D07', '2D09', '2D0A', '2D0B', '2D12',
    '2D18', '2D19', '2D1A', '2D1F', '2D22', '2D2C', '2D30', '2D37', '2D38'
}

# Groups of thread IDs that should be combined into a single file.
# Key = canonical file name subject, value = set of thread IDs to merge.
COMBINE_GROUPS = {
    'Science and NLP':      {'2CB9', '2D1A', '2D2C'},
    'Truth vs Use Theorem': {'2D06', '2D07'},
}

# Mapping from combined-group name → output filename stem
# (em-dash is U+2014; these are the exact desired filenames)
COMBINED_FILENAME = {
    'Science and NLP':      'NLP Forum \u2014 Science and NLP (December 1994)',
    'Truth vs Use Theorem': 'NLP Forum \u2014 Truth vs Use Theorem (December 1994)',
}

# Metadata lines in the file-header block that should be dropped entirely
HEADER_DROP_PATTERNS = [
    re.compile(r'^Type\s+:'),
    re.compile(r'^Forum\s+:'),
    re.compile(r'^Section\s+:'),
    re.compile(r'^Last update:'),
    re.compile(r'^Created\s+:'),   # file-level created line
]

# Punctuation that signals a line is complete (no word-wrap continuation)
SENTENCE_ENDINGS = '.?!:>'

# ---------------------------------------------------------------------------
# Step 1: Parse the DOCX into raw thread blocks
# ---------------------------------------------------------------------------

def load_docx_lines(path):
    """Return all paragraph texts from the DOCX as a list of strings."""
    doc = docx.Document(path)
    return [p.text for p in doc.paragraphs]


def split_into_thread_blocks(lines):
    """
    Return a dict mapping thread_id (e.g. '2CB9') -> list of lines for that thread.
    """
    # Regex: matches "File       : '2XYZ.THD'"
    thread_header_re = re.compile(r"File\s+: '([0-9A-F]{4})\.THD'", re.IGNORECASE)

    blocks = {}         # thread_id -> list of lines
    current_id = None   # thread ID currently being collected
    current_lines = []  # lines accumulated for current_id

    for line in lines:
        m = thread_header_re.match(line)
        if m:
            # Save the previous block
            if current_id is not None:
                blocks[current_id.upper()] = current_lines
            current_id = m.group(1).upper()
            current_lines = [line]  # include the File: line itself
        else:
            if current_id is not None:
                current_lines.append(line)

    # Don't forget the last block
    if current_id is not None:
        blocks[current_id.upper()] = current_lines

    return blocks


# ---------------------------------------------------------------------------
# Step 2: Parse a single thread block into structured messages
# ---------------------------------------------------------------------------

def extract_subject(lines):
    """Extract the Subject from the thread header lines."""
    for line in lines:
        m = re.match(r'Subject\s+:\s*(.*)', line)
        if m:
            return m.group(1).strip()
    return 'Unknown'


# Regex that detects the start of a message:
# e.g. " Message   1  Science & NLP "  (space-padded)
MSG_HEADER_RE = re.compile(r'^ Message\s+(\d+)\s+')

# Regex for To/From/Created metadata lines within a message
META_TO_RE      = re.compile(r'^To\s+:\s*(.*)')
META_FROM_RE    = re.compile(r'^From\s+:\s*(.*)')
META_CREATED_RE = re.compile(r'^Created\s+:\s*(.*)')


def clean_name(raw):
    """
    Strip the CompuServe UID (e.g. 73321,300) from a name field.
    'Bruce E. Foster             73321,300' -> 'Bruce E. Foster'
    """
    # UID pattern: spaces then digits,digits at end
    return re.sub(r'\s+\d+,\d+\s*$', '', raw).strip()


def format_created(raw):
    """
    Convert '05-Dec-1994 , 12:21:15' to '05 Dec 1994'
    Strips reply count suffix like '1 reply'.
    """
    raw = re.sub(r'\s+\d+ repl.*$', '', raw).strip()
    # Try to parse with various formats
    for fmt in ('%d-%b-%Y , %H:%M:%S', '%d-%b-%Y, %H:%M:%S'):
        try:
            dt = datetime.strptime(raw, fmt)
            return dt.strftime('%d %b %Y')
        except ValueError:
            pass
    return raw  # fallback: return as-is


def is_header_drop_line(line):
    """Return True if this file-level header line should be omitted."""
    for pat in HEADER_DROP_PATTERNS:
        if pat.match(line):
            return True
    return False


def parse_messages(lines):
    """
    Parse the raw lines of a thread block into a list of message dicts:
        {
          'number': int,
          'to': str,
          'from': str,
          'date': str,
          'body_lines': [str, ...],   # raw, possibly wrapped lines
        }
    Also returns the list of participants (unique From names).
    """
    messages = []
    participants = []          # ordered list, deduped
    participants_seen = set()  # for dedup

    # --- skip the file header block (until first Message line) ---
    in_header = True
    pending_msg = None         # accumulator for the current message being parsed
    # States within a message: 'meta' (reading To/From/Created) or 'body'
    msg_state = None

    for line in lines:
        # Detect message start
        if MSG_HEADER_RE.match(line):
            # Save previous message
            if pending_msg is not None:
                messages.append(pending_msg)
            m = MSG_HEADER_RE.match(line)
            pending_msg = {
                'number': int(m.group(1)),
                'to': '',
                'from': '',
                'date': '',
                'body_lines': [],
            }
            msg_state = 'meta'
            in_header = False
            continue

        if in_header:
            continue  # skip file-header lines

        if pending_msg is None:
            continue

        if msg_state == 'meta':
            # Try to match To / From / Created
            m = META_TO_RE.match(line)
            if m:
                pending_msg['to'] = clean_name(m.group(1))
                continue
            m = META_FROM_RE.match(line)
            if m:
                pending_msg['from'] = clean_name(m.group(1))
                # Track participant
                name = pending_msg['from']
                if name and name not in participants_seen:
                    participants_seen.add(name)
                    participants.append(name)
                continue
            m = META_CREATED_RE.match(line)
            if m:
                pending_msg['date'] = format_created(m.group(1))
                continue
            # Once we get a non-meta line after meta started, switch to body
            # (blank lines between meta and body are common — skip them)
            if line.strip() == '':
                continue
            # First non-blank, non-meta line → body starts
            msg_state = 'body'
            pending_msg['body_lines'].append(line)

        elif msg_state == 'body':
            pending_msg['body_lines'].append(line)

    # Don't forget the last message
    if pending_msg is not None:
        messages.append(pending_msg)

    return messages, participants


# ---------------------------------------------------------------------------
# Step 3: Word-wrap collapse
# ---------------------------------------------------------------------------

def collapse_wrapped_lines(lines):
    """
    BBS forums hard-wrapped long lines. Join continuation lines:
    - If a line doesn't end with a sentence-ending character (.?!:>) AND
      the next line is not blank AND not a metadata-style line,
      join them with a space.
    Returns a new list of lines.
    """
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Check if this line should be joined with the next
        if (
            i + 1 < len(lines)
            and line.strip() != ''
            and lines[i + 1].strip() != ''
            and not lines[i + 1].startswith(' ')   # indented lines stay separate
            and not re.match(r'^[A-Z][a-z]+\s+:', lines[i + 1])  # meta lines
            and len(line.rstrip()) > 0
            and line.rstrip()[-1] not in SENTENCE_ENDINGS
        ):
            # Join with next line
            lines[i + 1] = line.rstrip() + ' ' + lines[i + 1].lstrip()
            i += 1
            continue
        result.append(line)
        i += 1
    return result


def render_body(body_lines):
    """
    Clean and collapse the body lines of a message, returning a markdown string.
    Strips trailing separator lines (20+ dashes) and excessive blank lines.
    """
    # Remove separator lines (20+ dashes)
    cleaned = [l for l in body_lines if not re.match(r'^-{20,}\s*$', l)]
    # Collapse word-wrap
    collapsed = collapse_wrapped_lines(cleaned)
    # Remove more than two consecutive blank lines
    result_lines = []
    blank_count = 0
    for line in collapsed:
        if line.strip() == '':
            blank_count += 1
            if blank_count <= 1:
                result_lines.append('')
        else:
            blank_count = 0
            result_lines.append(line)
    # Strip leading/trailing blank lines
    while result_lines and result_lines[0] == '':
        result_lines.pop(0)
    while result_lines and result_lines[-1] == '':
        result_lines.pop()
    return '\n'.join(result_lines)


# ---------------------------------------------------------------------------
# Step 4: Compose the markdown note
# ---------------------------------------------------------------------------

def title_case_filename(subject):
    """
    Convert a subject string to title case suitable for a filename.
    Handles special cases like 'NLP', 'vs', 'and', 'the'.
    """
    # Words that should stay lowercase (unless first/last)
    lowercase_words = {'a', 'an', 'the', 'and', 'but', 'or', 'for',
                       'nor', 'on', 'at', 'to', 'by', 'in', 'of', 'vs'}
    # Words that should stay UPPERCASE
    uppercase_words = {'NLP', 'DHE', 'BBS', 'FAQ', 'AI', 'NHR'}

    words = subject.split()
    result = []
    for i, word in enumerate(words):
        # Strip leading/trailing punctuation for comparison
        core = word.strip('.,!?:;()[]{}')
        upper_core = core.upper()
        if upper_core in uppercase_words:
            # Preserve as uppercase, re-attach punctuation
            result.append(word.replace(core, upper_core))
        elif i == 0 or i == len(words) - 1:
            result.append(word[0].upper() + word[1:] if word else word)
        elif core.lower() in lowercase_words:
            result.append(word.lower())
        else:
            result.append(word[0].upper() + word[1:] if word else word)
    return ' '.join(result)


def sanitize_windows_filename(name):
    """
    Remove or replace characters that are illegal in Windows filenames.
    Illegal: \\ / : * ? " < > |
    """
    # Replace question mark with empty string (e.g. "Foundations of NLP?" → "Foundations of NLP")
    illegal = r'[\\/:*?"<>|]'
    return re.sub(illegal, '', name)


def make_filename(subject_for_file):
    """Build the output filename stem from a subject string."""
    stem = f'NLP Forum \u2014 {subject_for_file} (December 1994)'
    return sanitize_windows_filename(stem)


def make_note(subject, filename_stem, messages, participants, topics_hint=''):
    """
    Compose the full markdown note text.

    subject        : display subject (e.g. 'Science & NLP')
    filename_stem  : the stem used for the filename (no .md)
    messages       : list of message dicts from parse_messages()
    participants   : ordered list of participant names
    topics_hint    : optional extra topics text (unused; auto-derived)
    """
    # --- Build a brief description from message count and first body ---
    first_body = ''
    if messages:
        first_body = render_body(messages[0]['body_lines'])
        # Truncate to ~200 chars for description
        desc_text = ' '.join(first_body.split())[:200]
        if len(desc_text) == 200:
            # Find last space to avoid mid-word cut
            cut = desc_text.rfind(' ')
            desc_text = desc_text[:cut] + '...'
    else:
        desc_text = f'CompuServe forum discussion on {subject}.'

    # Sanitise the description for YAML (escape double quotes)
    desc_yaml = desc_text.replace('"', '\\"')

    # --- Participants list (comma-separated) ---
    parts_str = ', '.join(participants) if participants else 'Unknown'

    # --- Topics: derive from subject ---
    topics_str = f'Discussion of {subject} in the context of NLP practice.'

    # --- Build message sections ---
    msg_sections = []
    for msg in messages:
        body = render_body(msg['body_lines'])
        section = f"### Message {msg['number']}\n\n"
        if msg['from']:
            section += f"**From:** {msg['from']}  \n"
        if msg['to']:
            section += f"**To:** {msg['to']}  \n"
        if msg['date']:
            section += f"**Date:** {msg['date']}\n"
        section += '\n'
        if body:
            section += body + '\n'
        msg_sections.append(section)

    messages_text = '\n'.join(msg_sections)

    note = f"""---
title: "NLP Forum — {subject} (December 1994)"
source: "CompuServe AI Expert+ Forum, NeuroLinguistic Section"
created: 1994-12
description: "{desc_yaml}"
tags:
  - NLP
  - CompuServe
  - ForumArchive
nav: "[[01/NLP]] | [[MOC - NLP & Psychology]]"
---

[[01/NLP]] | [[MOC - NLP & Psychology]]

*Archived forum thread from the CompuServe AI Expert+ Forum, NeuroLinguistic Section — December 1994.*

**Participants:** {parts_str}

**Topics:** {topics_str}

---

## {subject} *(December 1994)*

{messages_text}
---

## Related Notes

- [[MOC - NLP & Psychology]]
- [[Time Line Therapy]]
- [[NLP World]]
"""
    return note


# ---------------------------------------------------------------------------
# Step 5: Main orchestration
# ---------------------------------------------------------------------------

def main():
    print(f'Loading {DOCX_PATH} ...')
    lines = load_docx_lines(DOCX_PATH)
    print(f'  {len(lines)} paragraph lines loaded.')

    print('Splitting into thread blocks ...')
    blocks = split_into_thread_blocks(lines)
    print(f'  {len(blocks)} thread blocks found: {sorted(blocks.keys())}')

    # Filter to only the threads we need
    relevant = {k: v for k, v in blocks.items() if k in THREADS_TO_INCLUDE}
    print(f'  {len(relevant)} relevant threads.')

    # Build a reverse map: thread_id -> group_name (for combined groups)
    thread_to_group = {}
    for group_name, ids in COMBINE_GROUPS.items():
        for tid in ids:
            thread_to_group[tid] = group_name

    # Collect groups of (thread_id, lines) to process together
    # group_name -> list of (thread_id, lines), preserving numeric order of IDs
    groups = {}   # group_name (or thread_id for singles) -> list of raw-line-lists
    singles = {}  # thread_id -> raw lines (for threads not in a combine group)

    for tid in sorted(relevant.keys()):
        if tid in thread_to_group:
            gname = thread_to_group[tid]
            groups.setdefault(gname, []).append((tid, relevant[tid]))
        else:
            singles[tid] = relevant[tid]

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    created_files = []

    # --- Process combined groups ---
    for group_name, id_line_pairs in groups.items():
        # Sort by thread ID (ascending) to preserve chronological order
        id_line_pairs.sort(key=lambda x: x[0])

        # Extract subject and messages from each constituent thread
        all_messages = []
        all_participants = []
        participants_seen = set()
        subject = group_name.replace('and', '&')  # display subject

        for tid, thread_lines in id_line_pairs:
            # The subject from the file (for reference)
            raw_subj = extract_subject(thread_lines)
            msgs, parts = parse_messages(thread_lines)
            all_messages.extend(msgs)
            for p in parts:
                if p not in participants_seen:
                    participants_seen.add(p)
                    all_participants.append(p)

        # Renumber messages sequentially across merged threads
        for i, msg in enumerate(all_messages, start=1):
            msg['number'] = i

        filename_stem = COMBINED_FILENAME[group_name]
        note_text = make_note(subject, filename_stem, all_messages, all_participants)
        out_path = os.path.join(OUTPUT_DIR, filename_stem + '.md')
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(note_text)
        size = os.path.getsize(out_path)
        created_files.append((filename_stem + '.md', size))
        print(f'  Written: {filename_stem}.md  ({size:,} bytes)')

    # --- Process single threads ---
    for tid in sorted(singles.keys()):
        thread_lines = singles[tid]
        subject = extract_subject(thread_lines)
        msgs, parts = parse_messages(thread_lines)

        # Build the filename subject (title-case, with special mapping)
        filename_subject = title_case_filename(subject)

        # Special override mappings
        special_map = {
            'HEALTH AND HEALING': 'Health and Healing',
            'beginer NLP questions': 'Beginner NLP Questions',
            "Richard over Germany '95": "Richard over Germany '95",
        }
        if subject in special_map:
            filename_subject = special_map[subject]

        filename_stem = make_filename(filename_subject)
        note_text = make_note(subject, filename_stem, msgs, parts)
        out_path = os.path.join(OUTPUT_DIR, filename_stem + '.md')
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(note_text)
        size = os.path.getsize(out_path)
        created_files.append((filename_stem + '.md', size))
        print(f'  Written: {filename_stem}.md  ({size:,} bytes)')

    # --- Summary ---
    print(f'\n{"="*70}')
    print(f'Created {len(created_files)} files in {OUTPUT_DIR}:')
    print(f'{"="*70}')
    total_bytes = 0
    for fname, sz in sorted(created_files):
        print(f'  {fname}  ({sz:,} bytes)')
        total_bytes += sz
    print(f'{"="*70}')
    print(f'Total: {total_bytes:,} bytes')
    return created_files


if __name__ == '__main__':
    main()
