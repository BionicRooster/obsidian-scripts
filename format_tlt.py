"""
Reformat Time Line Therapy.md:
- Fix YAML frontmatter
- Convert CompuServe thread file headers into ## headings
- Convert message headers (bullet lines) into ### headings with To/From metadata
- Replace dot-separator lines with markdown ---
- Clean up Related Notes (remove irrelevant entries)
"""

import re

# Read the source file with UTF-8 encoding
src = 'C:/Users/awt/Sync/Obsidian/01/NLP/Time Line Therapy.md'
with open(src, 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = []  # output lines buffer

# New YAML frontmatter to replace the original
NEW_YAML = """---
title: "Time Line Therapy — CompuServe NLP Forum Threads (December 1994)"
source: "CompuServe AI Expert+ Forum, NeuroLinguistic Section"
created: 1994-12
description: "A collection of forum threads from the CompuServe AI Expert+ NeuroLinguistic section, December 1994. Topics include Time Line Therapy, the science of NLP, daily practice ideas, electronic communication, health and healing, and more."
tags:
  - NLP
  - TimeLine
  - CompuServe
  - ForumArchive
nav: "[[01/NLP]] | [[MOC - NLP & Psychology]]"
---

[[01/NLP]] | [[MOC - NLP & Psychology]]

*Archived forum threads from the CompuServe AI Expert+ Forum, NeuroLinguistic Section — December 1994.*

"""

# Regex patterns for identifying structural lines
# Thread file header block start: line beginning with "File : '"
RE_FILE_HDR = re.compile(r"^File\s*:\s*'(.+)'")
# Subject line in file header
RE_SUBJECT  = re.compile(r"^Subject\s*:\s*(.+)")
# Thread created date
RE_THD_DATE = re.compile(r"^Created\s*:\s*(.+)")
RE_THD_UPDT = re.compile(r"^Last update\s*:\s*(.+)")
# Forum/section/type lines (consumed but not kept verbatim)
RE_FORUM    = re.compile(r"^(Forum|Type|Section)\s*:")
# Message header line: •••• Message N •••• Subject ••••
RE_MSG_HDR  = re.compile(r"^•{4}\s*Message\s+(\d+)\s*•{4}")
# To/From/Created metadata under each message
RE_TO       = re.compile(r"^To\s*:\s*(.+)")
RE_FROM     = re.compile(r"^From\s*:\s*(.+)")
RE_MSG_DATE = re.compile(r"^Created\s*:\s*(.+)")
# Dot-separator lines (lines of all dots/bullets)
RE_DOTS     = re.compile(r"^[•\-]{10,}\s*$")
# The [[NLP]] breadcrumb at line 6 (already handled by new header)
RE_NLP_BC   = re.compile(r"^\[\[NLP\]\]\s*$")
# Related notes section marker
RE_REL_NOTES= re.compile(r"^## Related Notes")

# YAML block: skip lines 0..4 (original frontmatter)
i = 0
# Skip original YAML
in_yaml = False
yaml_done = False
while i < len(lines):
    line = lines[i].rstrip('\n')
    if i == 0 and line.strip() == '---':
        in_yaml = True
        i += 1
        continue
    if in_yaml:
        if line.strip() == '---':
            yaml_done = True
            i += 1
            break
        i += 1
        continue
    break

# Write new YAML
out.append(NEW_YAML)

# State machine variables
current_thread_subject = None  # current thread's subject
in_message = False             # whether we're inside a message body
pending_to = None              # buffered To: line
pending_from = None            # buffered From: line
pending_date = None            # buffered Created: line
in_thread_header = False       # buffered thread header block
thread_file_id = None          # e.g. 2C88.THD
thread_created = None
in_related_notes = False       # once we hit ## Related Notes, switch mode

# Relevant related notes to keep (NLP/psychology topics only)
KEEP_RELATED = [
    'Time Line',
    'NLP',
    'nlp',
    'Psychology',
    'psychology',
    'Logical Level',
    'Language Pattern',
    'Therapy',
    'Trance',
    'Hypno',
    'Milton',
    'Bandler',
    'Grinder',
]

def flush_message_meta():
    """Emit To/From/Created metadata as a small formatted block."""
    parts = []
    if pending_from:
        parts.append(f"**From:** {pending_from}")
    if pending_to:
        parts.append(f"**To:** {pending_to}")
    if pending_date:
        parts.append(f"**Date:** {pending_date}")
    if parts:
        out.append("  \n".join(parts) + "\n\n")

while i < len(lines):
    line = lines[i].rstrip('\n')
    i += 1

    # ── Related Notes section ──────────────────────────────────────────────
    if RE_REL_NOTES.match(line):
        in_related_notes = True
        out.append("\n## Related Notes\n\n")
        out.append("- [[MOC - NLP & Psychology]]\n")
        continue

    if in_related_notes:
        # Only keep links that are NLP/psychology relevant
        # Skip all the irrelevant ones (Bahai, Rava Idli, etc.)
        # We'll just emit the curated list above and skip all original entries
        continue

    # ── Dot separator lines ────────────────────────────────────────────────
    if RE_DOTS.match(line):
        # Only emit --- if we're not in a thread header block
        if not in_thread_header:
            out.append("\n---\n\n")
        continue

    # ── Thread file header block ───────────────────────────────────────────
    m = RE_FILE_HDR.match(line)
    if m:
        in_thread_header = True
        thread_file_id = m.group(1)
        thread_created = None
        current_thread_subject = None
        continue

    if in_thread_header:
        m_subj = RE_SUBJECT.match(line)
        m_date = RE_THD_DATE.match(line)
        m_updt = RE_THD_UPDT.match(line)

        if m_subj:
            current_thread_subject = m_subj.group(1).strip()
            continue
        elif m_date and not thread_created:
            thread_created = m_date.group(1).strip()
            continue
        elif m_updt or RE_FORUM.match(line):
            continue
        else:
            # End of thread header block — emit the heading
            in_thread_header = False
            date_str = f" *({thread_created})*" if thread_created else ""
            out.append(f"\n## {current_thread_subject}{date_str}\n\n")
            # Don't skip current line; fall through to normal processing below

    # ── [[NLP]] breadcrumb (skip — replaced by new nav header) ────────────
    if RE_NLP_BC.match(line):
        continue

    # ── Message header line ────────────────────────────────────────────────
    m = RE_MSG_HDR.match(line)
    if m:
        msg_num = m.group(1)
        # Flush any pending metadata from previous message
        if pending_to or pending_from or pending_date:
            flush_message_meta()
            pending_to = pending_from = pending_date = None
        out.append(f"\n### Message {msg_num}\n\n")
        in_message = True
        continue

    # ── To/From/Created lines after a message header ───────────────────────
    if in_message:
        m_to   = RE_TO.match(line)
        m_from = RE_FROM.match(line)
        m_date = RE_MSG_DATE.match(line)

        if m_to:
            pending_to = m_to.group(1).strip()
            continue
        elif m_from:
            pending_from = m_from.group(1).strip()
            continue
        elif m_date and (pending_to is not None or pending_from is not None):
            # Only treat as message metadata date if we already have To or From
            pending_date = m_date.group(1).strip()
            continue
        elif line.strip() == '---' and pending_from is not None:
            # The --- after To/From/Created separates metadata from body
            flush_message_meta()
            pending_to = pending_from = pending_date = None
            continue

    # ── Normal content line ────────────────────────────────────────────────
    # Convert bare --- separators within messages to just a blank line
    # (they appear as quoted-text separators in the forum messages)
    if line.strip() == '---':
        out.append("\n")
        continue

    out.append(line + "\n")

# Write the output file
dst = 'C:/Users/awt/Sync/Obsidian/01/NLP/Time Line Therapy.md'
with open(dst, 'w', encoding='utf-8') as f:
    f.writelines(out)

print(f"Done. Wrote {len(out)} lines.")
