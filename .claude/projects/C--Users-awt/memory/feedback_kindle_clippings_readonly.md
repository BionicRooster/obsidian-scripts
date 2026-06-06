---
name: kindle-clippings-readonly
description: "Kindle Clippings files are read-only — link INTO them from MOCs/notes, never modify the clipping files themselves"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0b78a596-224e-45d6-a625-af4aa16a4098
---

Files in `09 - Kindle Clippings\` are created by the Kindle Highlights Obsidian plugin — they are NOT Claude-extracted book highlights. Never modify or move them.

**Two distinct folders:**
- `09 - Kindle Clippings\` — Kindle plugin output; read-only; contain `asin:` frontmatter field
- `09 - eBook Clippings\` — Claude-extracted book highlights; contain `nav:` frontmatter, no `asin:` field

**How to apply:** When the user asks to move or reorganize book clippings, only touch files in `09 - eBook Clippings\`. Identify Claude-created files by presence of `nav:` and absence of `asin:` in frontmatter. Never move or bulk-operate on `09 - Kindle Clippings\`.

**Exception:** Frontmatter structural repairs (malformed YAML tags, missing closing `---`) are permitted on Kindle Clippings files when flagged by the maintenance log. Content of the clipping remains untouched.
