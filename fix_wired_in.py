"""
Reformat: What's Wired In.md
- Fix YAML
- Convert ==== Message N ==== headers to ### headings
- Format To/From/Created metadata
- Remove dot/equals separator lines
- Fix [[Whatever]] artifacts
- Clean Related Notes
"""

import re, glob, os

matches = glob.glob("D:/Obsidian/Main/01/NLP/What*Wired*")
if not matches:
    print("File not found")
    exit(1)

src = matches[0]
print(f"Source: {src}")

with open(src, 'r', encoding='utf-8') as f:
    lines = f.readlines()

NEW_YAML = """\
---
title: "What's Wired In? — CompuServe NLP Forum Thread (May–Jun 1995)"
source: "CompuServe AI Expert+ Forum, NeuroLinguistic Section"
created: 1995-05
description: "Forum discussion on whether humans have innate ('wired-in') naive physics, morality, and language. Participants draw on Chomsky, Piaget, Kohlberg, Pinker, and Cialdini. Touches on NLP's relationship to linguistics and innate cognitive structures."
tags:
  - NLP
  - CompuServe
  - ForumArchive
  - CognitiveScience
  - Linguistics
nav: "[[01/NLP]] | [[MOC - NLP & Psychology]]"
---

[[01/NLP]] | [[MOC - NLP & Psychology]]

*Archived forum thread from the CompuServe AI Expert+ Forum, NeuroLinguistic Section — May–June 1995.*

**Participants:** Jim Tipping, Nelson Zink, Stever Robbins, Bob Janes, Joseph O'Connor.

**Topics:** Innate ("wired-in") naive physics and morality; Chomskyan universal grammar; Piaget's developmental stages; Kohlberg's moral development; NLP's linguistic foundations; Cialdini's social influence patterns; perceptual positions and ethics.

"""

FOOTER = """\

---

## Related Notes

- [[MOC - NLP & Psychology]]
- [[Time Line Therapy]]
- [[Transcript of a CompUSERVE THREAD ON THE USE OF NLP IN TRAINING]]
"""

# Patterns
RE_FILE_HDR  = re.compile(r"^File\s*:")
RE_FORUM     = re.compile(r"^(Forum|Type|Section|Subject|Last update)\s*:")
RE_CREATED   = re.compile(r"^Created\s*:\s*(.+)")
RE_MSG_HDR   = re.compile(r"^={4}\s*Message\s+(\d+)\s*={4}")
RE_TO        = re.compile(r"^To\s*:\s*(.+)")
RE_FROM      = re.compile(r"^From\s*:\s*(.+)")
RE_SEP_DASH  = re.compile(r"^-{20,}\s*$")
RE_SEP_EQ    = re.compile(r"^={20,}\s*$")
RE_NLP_BC    = re.compile(r"^\[\[NLP\]\]\s*$")
RE_REL_NOTES = re.compile(r"^## Related Notes")

out = [NEW_YAML]

i = 0
# Skip original YAML
if lines[0].strip() == '---':
    i = 1
    while i < len(lines) and lines[i].strip() != '---':
        i += 1
    i += 1  # skip closing ---

in_thread_hdr = False
thread_subject = None
thread_date = None
in_message = False
pending_to = None
pending_from = None
pending_date = None
in_related = False

def flush_meta():
    parts = []
    if pending_from: parts.append(f"**From:** {pending_from}")
    if pending_to:   parts.append(f"**To:** {pending_to}")
    if pending_date: parts.append(f"**Date:** {pending_date}")
    if parts:
        out.append("  \n".join(parts) + "\n\n")

while i < len(lines):
    line = lines[i].rstrip('\n')
    i += 1

    # Related Notes section — replace entirely
    if RE_REL_NOTES.match(line):
        in_related = True
        continue
    if in_related:
        continue

    # Final separator before Related Notes
    if RE_SEP_EQ.match(line):
        continue

    # [[NLP]] breadcrumb or previously-injected header lines (dedup from prior run)
    if RE_NLP_BC.match(line):
        continue
    if re.match(r'^\[\[01/NLP\]\]', line):
        continue
    if re.match(r'^\*Archived forum thread', line):
        continue
    if re.match(r'^\*\*Participants:\*\*', line):
        continue
    if re.match(r'^\*\*Topics:\*\*', line):
        continue

    # Thread file header
    if RE_FILE_HDR.match(line):
        in_thread_hdr = True
        thread_subject = None
        thread_date = None
        continue

    if in_thread_hdr:
        m_subj = re.match(r"^Subject\s*:\s*(.+)", line)
        m_date = RE_CREATED.match(line)
        if m_subj:
            thread_subject = m_subj.group(1).strip()
            continue
        elif m_date and not thread_date:
            thread_date = m_date.group(1).strip()
            continue
        elif RE_FORUM.match(line) or not line.strip():
            continue
        else:
            in_thread_hdr = False
            date_str = f" *({thread_date})*" if thread_date else ""
            out.append(f"## {thread_subject}{date_str}\n\n")
            # Fall through

    # Message header line: ==== Message N ==== Subject ====
    m = RE_MSG_HDR.match(line)
    if m:
        msg_num = m.group(1)
        if pending_to or pending_from or pending_date:
            flush_meta()
            pending_to = pending_from = pending_date = None
        out.append(f"\n### Message {msg_num}\n\n")
        in_message = True
        continue

    # To/From/Created after message header
    if in_message:
        m_to   = RE_TO.match(line)
        m_from = RE_FROM.match(line)
        m_date = RE_CREATED.match(line)

        if m_to:
            to_val = m_to.group(1).strip()
            # Handle "To : All From : Jim Tipping..." on one line
            embedded_from = re.match(r'^(.+?)\s+From\s*:\s*(.+)$', to_val)
            if embedded_from:
                pending_to   = embedded_from.group(1).strip()
                pending_from = embedded_from.group(2).strip()
            else:
                pending_to = to_val
            continue
        elif m_from:
            pending_from = m_from.group(1).strip()
            continue
        elif m_date and (pending_to is not None or pending_from is not None):
            pending_date = m_date.group(1).strip()
            continue
        elif RE_SEP_DASH.match(line) and (pending_from is not None or pending_to is not None):
            flush_meta()
            pending_to = pending_from = pending_date = None
            continue

    # Skip other separator lines
    if RE_SEP_DASH.match(line):
        continue

    # Fix [[Whatever]] artifacts — these are corrupted text fragments
    line = re.sub(r'/\[\[Whatever\]\]ect ', '/whatever affect ', line)
    line = re.sub(r'What\[\[Whatever\]\]uld', 'What we could', line)
    line = re.sub(r'/Whatever aff\[\[Whatever\]\] ', '/whatever affects ', line)
    line = re.sub(r'\[\[Whatever\]\]', '', line)

    # [[Sciences]] → sciences (bare wikilink artifact)
    line = line.replace('[[Sciences]]', 'sciences')

    out.append(line + "\n")

# Strip trailing blank lines before footer
while out and out[-1].strip() == '':
    out.pop()

out.append(FOOTER)

# Collapse 3+ blank lines
content = ''.join(out)
content = re.sub(r'\n{4,}', '\n\n\n', content)

# Write back
dst = src  # same file, same location (name is fine)
with open(dst, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Done. {len(content.splitlines())} lines.")
