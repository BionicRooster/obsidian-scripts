"""
Reformat: Transcript of a CompUSERVE THREAD ON THE USE OF NLP IN TRAINING
- Replace YAML frontmatter
- Collapse excessive blank lines (every paragraph line has blank lines between each line)
- Bold speaker name labels (STEVER:, DAVID:, JOEL:, SHELLE:, DON:, K:)
- Handle mid-line speaker transitions (e.g. "...pull off JOEL:\n\n")
- Add navigation header
- Clean Related Notes
"""

import re

SRC = 'D:/Obsidian/Main/01/NLP/Transcript of a CompUSERVE THREAD ON THE USE OF NLP IN TRAINING.md'

# Read file
with open(SRC, 'r', encoding='utf-8') as f:
    raw = f.read()

# ── 1. Strip original YAML ──────────────────────────────────────────────────
# Remove content from start through the closing ---
raw = re.sub(r'^---.*?---\n', '', raw, count=1, flags=re.DOTALL)

# ── 2. Remove the [[NLP]] breadcrumb line (replaced by new header) ──────────
raw = re.sub(r'^\[\[NLP\]\]\s*\n', '', raw, flags=re.MULTILINE)

# ── 3. Collapse the title/intro block at the top ───────────────────────────
# The file starts with a title line, a source line, and a date line.
# We'll preserve these but they'll be handled in the new header.

# ── 4. Collapse runs of blank lines: 2+ blank lines → 1 blank line ──────────
raw = re.sub(r'\n{3,}', '\n\n', raw)

# ── 5. Fix mid-line speaker transitions ────────────────────────────────────
# Pattern: text ending without newline, then SPEAKER: at start of next chunk
# These appear as "...sentence SPEAKER:\n\ntext..." after the collapse
# Also handles "sentence STEVER" (no colon) followed by newline
SPEAKERS = r'(STEVER|DAVID|JOEL|SHELLE|DON|K)'
# Mid-line: "word SPEAKER:" at end of a line → split before SPEAKER:
raw = re.sub(r'(\w)\s+(' + SPEAKERS[1:-1] + r'):\n', r'\1\n\n**\2:**\n\n', raw)
# "word SPEAKER\n" with no colon (some cases like "...precision to pull off JOEL:")
raw = re.sub(r'(\w)\s+(' + SPEAKERS[1:-1] + r')(\s*\n)', r'\1\n\n**\2:**\3', raw)

# ── 6. Bold speaker names at the start of a line ───────────────────────────
# Pattern: line beginning with SPEAKER: (with or without space after)
raw = re.sub(r'^(' + SPEAKERS[1:-1] + r'):\s*$', r'**\1:**', raw, flags=re.MULTILINE)
raw = re.sub(r'^(' + SPEAKERS[1:-1] + r'):\s+', r'**\1:** ', raw, flags=re.MULTILINE)

# ── 7. Remove Related Notes section entirely (we'll replace it) ────────────
raw = re.sub(r'\n---\n## Related Notes.*$', '', raw, flags=re.DOTALL)

# ── 8. Strip trailing whitespace ────────────────────────────────────────────
raw = raw.strip()

# ── 9. Build new YAML + header ──────────────────────────────────────────────
NEW_HEADER = """---
title: "NLP in Training — CompuServe Forum Thread (Aug–Sep 1992)"
source: "CompuServe AI Expert+ Forum, NeuroLinguistic Section (#10)"
created: 1992-08
description: "Forum discussion on applying NLP techniques to training: anchoring states in a classroom, using stories and metaphors, nested loops for strategy installation, covert teaching, and the ethics of manipulation in training contexts. Participants include Stever Robbins, Joel P. Bowman, Shelle Rose Charvet, and others."
tags:
  - NLP
  - Training
  - CompuServe
  - ForumArchive
  - Anchoring
nav: "[[01/NLP]] | [[MOC - NLP & Psychology]]"
---

[[01/NLP]] | [[MOC - NLP & Psychology]]

*Archived forum thread from the CompuServe AI Expert+ Forum, NeuroLinguistic Section — August 24 – September 10, 1992.*

**Participants:** Stever Robbins (NLP trainer), Joel P. Bowman, Shelle Rose Charvet, David, Don, K.

**Topics:** Using anchoring and state-chaining in classroom training; eliciting class-wide states; nested loops for covert strategy installation; ethics of unconscious manipulation; using stories and metaphors methodically; NLP for employee motivation.

"""

FOOTER = """

---

## Related Notes

- [[MOC - NLP & Psychology]]
- [[NLP in Training]]
- [[Time Line Therapy]]
"""

final = NEW_HEADER + raw + FOOTER

# Write output
with open(SRC, 'w', encoding='utf-8') as f:
    f.write(final)

print(f"Done. {len(final.splitlines())} lines.")
