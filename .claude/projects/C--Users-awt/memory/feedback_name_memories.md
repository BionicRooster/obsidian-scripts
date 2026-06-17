---
name: feedback-name-memories
description: "Name memory files in dialogue when recalling them, so Wayne can see what's being used"
metadata:
  node_type: memory
  type: feedback
  originSessionId: current
---

When recalling a memory file during a conversation, name it explicitly in the dialogue (e.g., "using **feedback_anti_ai_style**" or "from **domain/synthesis**") so Wayne can see which memory is being applied.

**Why:** Wayne asked for this so he can follow what context is being loaded and verify it's the right source.

**How to apply:** Any time a memory file is read or applied, mention its name inline in the response text before using it.
