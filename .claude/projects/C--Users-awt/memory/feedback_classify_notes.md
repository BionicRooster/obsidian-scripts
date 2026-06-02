---
name: Classify Notes Workflow — Required Steps
description: The three required steps whenever classifying vault notes — move, link, tag
type: feedback
originSessionId: f2c229e5-bd10-4e40-b472-28911306b580
---
When classifying notes (vault root, 10 - Clippings, or recent files), always do ALL THREE steps:

1. **Move** the file to the appropriate `01/` subdirectory — **BUT ONLY if:**
   - The file is NOT in the vault root (`D:\Obsidian\Main\*.md`) — leave vault root files in place
   - The file is NOT in `02 - Working Projects\` or any subdirectory thereof — never move these
   - Files in subdirectories (e.g., `10 - Clippings\`, `01\`) are moved normally

2. **Link** the file in the correct MOC subsection (add wikilink to `00 - Home Dashboard/MOC - *.md`)

3. **Add tags** to the file's frontmatter if missing or incomplete

Also add a `nav` property pointing back to the MOC for bidirectional linking.

**Why:** User corrected incomplete classify runs that did only one or two of these steps.
