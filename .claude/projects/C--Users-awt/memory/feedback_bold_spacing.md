---
name: feedback-bold-spacing
description: Bold markdown must be preceded by whitespace (space or tab) for Obsidian print to render correctly
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2661a7b6-1c52-4110-8a45-356269a64677
---

In Obsidian markdown files, bold syntax `**text**` must be preceded by a space or tab character to print correctly using Obsidian's print function.

- `-**text**` — WRONG: bold immediately after a hyphen, no space; prints as literal asterisks
- `- **text**` — CORRECT: one space between hyphen and bold marker
- `-  **text**` — CORRECT: two spaces also work

**Why:** Obsidian's print renderer does not recognize `**` as bold when it immediately follows a non-whitespace character like `-`.

**How to apply:** When writing or editing any markdown list that uses bold — lab results, box scores, MOC items, anything — always ensure at least one space between the `-` and the opening `**`. Also applies to other non-whitespace characters that might precede bold (colons, commas, etc.) if they appear at the start of list items.
