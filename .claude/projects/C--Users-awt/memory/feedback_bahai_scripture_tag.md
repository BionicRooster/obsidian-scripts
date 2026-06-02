---
name: feedback-bahai-scripture-tag
description: "Add BahaiScripture tag to any vault note whose content is attributed to a Central Figure of the Bahá'í Faith"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cb1e4560-c2f0-4ab0-801e-357984912080
---

Any Obsidian note that contains text attributed to a Central Figure of the Bahá'í Faith must have `BahaiScripture` in its frontmatter tags list.

**Why:** The user wants all scripture tagged consistently so Dataview queries and searches can filter on this tag across the vault.

**How to apply:**
- Central Figures are: **Bahá'u'lláh**, **The Báb**, and **'Abdu'l-Bahá**
- Trigger contexts: creating a new note, classifying a recent note, ingesting a book/transcript, running any vault workflow that touches Bahá'í content
- Tag form: `BahaiScripture` (no diacriticals — per [[feedback-tag-regex]] rule)
- If the note already has the tag, skip; do not add duplicates
- Note that the Daily Quotes notes (2024-03 through present) already have this tag, and the generation script `bahai_quotes_to_vault.py` includes it automatically
- Shoghi Effendi and the Universal House of Justice are NOT Central Figures; their writings do not get this tag unless the user specifically requests it
