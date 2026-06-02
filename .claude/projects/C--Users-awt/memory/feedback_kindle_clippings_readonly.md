---
name: kindle-clippings-readonly
description: "Kindle Clippings files are read-only — link INTO them from MOCs/notes, never modify the clipping files themselves"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0b78a596-224e-45d6-a625-af4aa16a4098
---

Never modify files in `09 - Kindle Clippings\`. When linking Kindle Clippings:
- Add the wikilink in the MOC or source note (link IN to the clipping)
- Do NOT add `nav` frontmatter, backlinks, or any other content to the clipping file itself

**Why:** Kindle Clippings are preserved as-imported source records. Modifications risk corrupting the original highlight data and violate the read-only intent of that folder.

**How to apply:** In any linking workflow (classify, crosslink, orphan fix), if the target is in `09 - Kindle Clippings\`, only update the linking side (MOC or note). Leave the clipping file untouched.
