---
name: workflow-crosslink-files
description: "Crosslink Files workflow — find cross-topic related notes, add wikilinks between them, connection patterns, example links"
metadata:
  node_type: memory
  type: reference
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Trigger
"crosslink_files" or "crosslink files"

---

## Purpose
Find notes in the vault that are logically related across different topics/MOCs and add wikilinks between them.

## Workflow
1. Read MOC files to identify key notes in different topic areas
2. Search for notes that bridge multiple disciplines (e.g., cognitive science + health, race issues + religion)
3. For each identified note, read the actual note file (not the MOC)
4. Add a `## Related Notes` section (or update existing one) with wikilinks to logically connected notes from OTHER topic areas
5. Do NOT add links to MOC files — only link to actual content notes
6. Do NOT modify files in `09 - Kindle Clippings` folder (no outgoing links added), but other files CAN link TO files in that folder

## Cross-Topic Connection Patterns
- Cognitive science/psychology ↔ Health/medical (brain, learning, memory)
- Race/social justice books ↔ Bahá'í teachings on unity
- Productivity/PKM resources ↔ Psychology/cognitive science
- Maker/technology projects ↔ Social development/education
- Religious/spiritual topics ↔ Social issues
- Science/nature ↔ Indigenous knowledge
- Books that reference each other or share themes

## Example Cross-Links
- Dyslexia articles → link to each other and to learning/cognitive notes
- Race books (Sum of Us, My Grandmother's Hands) → link to Bahá'í race unity teachings
- Kahneman's Thinking Fast and Slow → link to Dunning-Kruger, productivity notes, cognitive bias articles
- Inspirational tech stories (Boy Who Harnessed Wind) → link to maker projects, sustainability

## Output
Summary table showing which notes were updated and what links were added.

Preserve UTF-8 encoding when editing files.
