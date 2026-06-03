---
name: vault-permissions-no-pause
description: Do not pause for confirmation on Obsidian vault read/write/move operations — permission is permanently pre-granted
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c8443fac-3c94-467b-b4a8-ac7a29d060bf
---

Do not ask for permission or pause before reading, writing, creating, or moving files anywhere in `D:\Obsidian\Main\`. Permission is permanently granted in CLAUDE.md.

**Why:** Wayne explicitly said "what are you waiting for?" when Claude paused before a vault write despite the pre-granted permission. Pausing adds friction with no safety benefit since vault operations are reversible and the permission is unconditional.

**How to apply:** Treat all vault file operations (Read, Edit, Write, Move, frontmatter edits, MOC links) as pre-approved. Only pause on destructive bulk operations outside the vault, or on actions that affect shared/external systems (git push, scheduled jobs, email).
