# -*- coding: utf-8 -*-
"""
Convert CATALOGU.doc (CompuServe AIEXPERT+ forum thread dump, file 3184.THD)
into a single continuous-thread Obsidian note.

Source structure per message:
    = Message N = SUBJECT ==
    To         : ...
    From       : ...
    Created    : DD-Mon-YYYY , HH:MM:SS   N reply/replies
    -------------------------------------------------------------------------------
    <body, hard-wrapped at ~80 chars, blank line = paragraph break>

Approach:
- Read the LibreOffice-converted .docx (not the plain .txt export) so that
  Unicode characters in the original .doc are preserved instead of being
  silently re-encoded through the system codepage.
- Split into per-message blocks on the "= Message N = ... ==" marker.
- Within each message body, join hard-wrapped lines (no blank line between
  them) into single flowing paragraph lines; blank lines remain paragraph
  breaks. ">" quoted-reply lines and signature "--" lines are left as-is
  since both are already valid in Markdown.
- The 3 bytes in the original .doc that have no valid Unicode mapping
  (confirmed via raw zip/XML inspection) are replaced with the literal
  marker "[illegible character]" rather than guessed at, per instruction
  to never invent original content.
"""

import re
import docx  # python-docx: reads the LibreOffice-converted .docx for clean Unicode text

# DOCX_PATH: LibreOffice export of the source .doc, used instead of the raw .doc
# because python-docx cannot read the legacy binary .doc format directly.
DOCX_PATH = r"C:\Users\awt\AppData\Local\Temp\docconv\CATALOGU.docx"

# OUT_PATH: destination note at the vault root, per explicit user instruction
# (root placement, not the usual 01/NLP classification folder).
OUT_PATH = r"C:\Users\awt\Sync\Obsidian\PRODUCT CATALOG AVAILABL — AIEXPERT+ Forum Thread (Jul 1995).md"

# ILLEGIBLE_MARKER: replaces bytes in the source .doc that LibreOffice could
# not resolve to a real character. Confirmed by direct codepoint inspection
# that these decode as U+00A1 ("\xa1") in the docx XML -- a CP1252
# misinterpretation of whatever 8-bit BBS/DOS-era byte was in the original,
# not a legitimate inverted exclamation mark (there is no Spanish text in
# this thread). All 3 occurrences sit where an em-dash would grammatically
# fit, but that is a guess, so we mark rather than substitute.
ILLEGIBLE_MARKER = "[illegible character]"
ILLEGIBLE_BYTE = "\xa1"

# ── 1. Extract raw paragraph text from the docx, preserving Unicode ────────
doc = docx.Document(DOCX_PATH)
# raw_lines: one entry per docx paragraph; python-docx already separates
# paragraphs the way LibreOffice laid them out from the original .doc, so an
# empty string here corresponds to a blank line in the source.
raw_lines = [p.text.replace(ILLEGIBLE_BYTE, ILLEGIBLE_MARKER) for p in doc.paragraphs]
raw_text = "\n".join(raw_lines)

# ── 2. Split off the file-level header (before the first "= Message" line) ─
header_match = re.search(r"^= Message\s+1\s*=", raw_text, flags=re.MULTILINE)
file_header_text = raw_text[: header_match.start()].strip()
body_text = raw_text[header_match.start():]

# file_header_lines: the "File / Type / Forum / Section / Subject / Created /
# Last update" block at the top of the original thread dump.
file_header_lines = [l.strip() for l in file_header_text.splitlines() if l.strip()]
file_meta = {}
for line in file_header_lines:
    if ":" in line:
        key, _, val = line.partition(":")
        file_meta[key.strip()] = val.strip()

# ── 3. Split the body into individual messages ──────────────────────────────
# MESSAGE_SPLIT_RE: matches each "= Message N = SUBJECT ==" marker line,
# capturing the message number so messages can be rendered as ### headings.
MESSAGE_SPLIT_RE = re.compile(r"^=\s*Message\s+(\d+)\s*=.*?==\s*$", flags=re.MULTILINE)
splits = list(MESSAGE_SPLIT_RE.finditer(body_text))

messages = []
for i, m in enumerate(splits):
    msg_num = m.group(1)
    start = m.end()
    end = splits[i + 1].start() if i + 1 < len(splits) else len(body_text)
    chunk = body_text[start:end]
    messages.append((msg_num, chunk))

def join_wrapped_paragraphs(text):
    """Join hard-wrapped lines within a paragraph; keep blank-line paragraph
    breaks, '>' quote lines, and the '--' signature delimiter as separate
    lines rather than merging them into surrounding prose."""
    lines = text.splitlines()
    out_paragraphs = []
    buffer = []

    def flush():
        if buffer:
            out_paragraphs.append(" ".join(buffer))
            buffer.clear()

    for line in lines:
        stripped = line.strip()
        if stripped == "":
            flush()
            out_paragraphs.append("")  # blank line = paragraph break
        elif stripped.startswith(">") or stripped == "--":
            flush()
            out_paragraphs.append(stripped)
        else:
            buffer.append(stripped)
    flush()
    return "\n".join(out_paragraphs)

# ── 4. Render each message as a Markdown section ────────────────────────────
rendered_messages = []
for msg_num, chunk in messages:
    lines = chunk.splitlines()
    # meta_lines: the To/From/Created/divider block at the top of the chunk,
    # before the actual message body begins.
    meta_lines = []
    body_start_idx = 0
    for idx, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("---"):
            body_start_idx = idx + 1
            break
        if stripped:
            meta_lines.append(stripped)

    meta = {}
    for line in meta_lines:
        if ":" in line:
            key, _, val = line.partition(":")
            meta[key.strip()] = re.sub(r"\s{2,}", "  ", val.strip())

    to_field = meta.get("To", "")
    from_field = meta.get("From", "")
    created_field = meta.get("Created", "")

    body_chunk = "\n".join(lines[body_start_idx:])
    body_formatted = join_wrapped_paragraphs(body_chunk).strip()

    section = (
        f"### Message {msg_num}\n\n"
        f"**From:** {from_field}  \n"
        f"**To:** {to_field}  \n"
        f"**Created:** {created_field}\n\n"
        f"{body_formatted}\n"
    )
    rendered_messages.append(section)

thread_body = "\n---\n\n".join(rendered_messages)

# ── 5. Build the note header (frontmatter + intro), matching the precedent
#       set by the existing CompuServe NLP transcript note in 01/NLP ───────
subject = file_meta.get("Subject", "PRODUCT CATALOG AVAILABL")
created_range = f"{file_meta.get('Created', '')} to {file_meta.get('Last update', '')}"

frontmatter = f"""---
title: "{subject} — AIEXPERT+ Forum Thread (Jul 1995)"
source: "CompuServe AIEXPERT+ Forum, NeuroLinguistic Section — file {file_meta.get('File', '3184.THD').strip("'")}"
created: 1995-07
description: "Forum thread sparked by a product-catalog announcement from Rex Steven Sikes' IDHEA Seminars, which escalates into a debate among CompuServe AIEXPERT+ members (Christopher Le Bret, Stever Robbins, Patrick Merlevede, and others) over commercial spam in the forum and whether NLP belongs in a section originally intended for natural language processing."
tags:
  - NLP
  - ForumArchive
  - CompuServe
nav: "[[01/NLP]] | [[MOC - NLP & Psychology]]"
---

[[01/NLP]] | [[MOC - NLP & Psychology]]

*Archived forum thread from the CompuServe AIEXPERT+ Forum, NeuroLinguistic Section — {created_range}.*

**Participants:** Rex Steven Sikes, Christopher Le Bret, Stever Robbins, Patrick E. Merlevede, and others.

**Topics:** A catalog-announcement post from an NLP training company draws an accusation of commercial spam, which turns into a back-and-forth about advertising on early CompuServe forums and whether NLP discussion belongs in the AIEXPERT+ NeuroLinguistic section at all.

"""

footer = """

---

## Related Notes

- [[MOC - NLP & Psychology]]
"""

final_text = frontmatter + thread_body + footer

with open(OUT_PATH, "w", encoding="utf-8") as f:
    f.write(final_text)

print(f"Wrote {OUT_PATH}")
print(f"Messages: {len(messages)}, total lines: {len(final_text.splitlines())}")
