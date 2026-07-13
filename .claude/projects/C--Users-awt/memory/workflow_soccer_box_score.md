---
name: workflow-soccer-box-score
description: "Supplemental notes for soccer box score sessions. Full procedure in commands/box-score.md (authoritative)."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

**Full procedure:** `~/.claude/commands/box-score.md` — authoritative for all steps.

**Also read at session start:** `domain/soccer_sources.md` for source reliability tiers.

## Supplemental Notes

### Output file location
`C:\Users\awt\Sync\Obsidian\YYYY-MM-DD - {Team A} vs {Team B} Box Score.md` (vault root, not `01/Soccer/`)

### Austin FC roster note (jersey number primary source for MLS matches)
`C:\Users\awt\Sync\Obsidian\20 - Permanent Notes\2026 Austin FC Roster as of 2026-04-18 Status.md`

### FBref via Firecrawl
Plain WebFetch returns HTTP 403. Use Firecrawl with `waitFor: 8000, formats: ["markdown"], onlyMainContent: true`. Confirmed working 2026-06-08.

### FotMob timing artifact
First-half card times run ~7 min earlier than FBref/official match time. Record as a single pattern note — do not create individual discrepancy entries per card. Flag only if a specific card is >10 min off or in the wrong half.
