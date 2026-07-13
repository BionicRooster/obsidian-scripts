---
name: workflow-moc-orphan-linker
description: Procedure for linking orphan vault notes to MOC subsections using moc_orphan_linker.ps1
metadata: 
  node_type: memory
  type: reference
  originSessionId: 60c405b8-8c2b-4b8f-9074-e80d2873b489
---

## Trigger
"link orphans" or "find orphans for [MOC]" or "find relevant orphans for [MOC / Subsection]"

## Helper Script
`C:\Users\awt\moc_orphan_linker.ps1`

**Available actions:** `list-mocs` · `get-subsections` · `get-orphans` · `link-orphan`

## Procedure

1. **List available MOCs** — run `list-mocs` action; present to user for selection
2. **Get subsections** — run `get-subsections` for the chosen MOC; present to user for selection
3. **Find candidates** — for the selected subsection, Grep `C:\Users\awt\Sync\Obsidian\` for relevant keywords based on the subsection topic; analyze relevance; rank top 20 candidates
4. **Present for approval** — show candidates with brief rationale; user approves or rejects each
5. **Create links** — for approved files, run `link-orphan` action to create bidirectional links

## Example invocations
- "link orphans to Recipes"
- "find orphans for Bahá'í Faith / Core Teachings"
- "link orphans for Georgetown LSA"
