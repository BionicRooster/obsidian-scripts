---
name: workflow-moc-orphan-linker
description: Procedure for linking orphan vault notes to MOC subsections using moc_orphan_linker.ps1
metadata: 
  node_type: memory
  type: reference
  originSessionId: 60c405b8-8c2b-4b8f-9074-e80d2873b489
---

## Trigger
"link orphans" or "find orphans for [MOC]" or "find relevant orphans for [MOC / Subsection]" or "classify orphans"

**"classify orphans"** — vault-wide sweep with no date filter; find all unlinked notes across the entire vault and link them to appropriate MOC subsections.

## Helper Script
`C:\Users\awt\moc_orphan_linker.ps1`

**Available actions:** `list-mocs` · `get-subsections` · `get-orphans` · `link-orphan`

## Critical: Path Format for link-orphan
`-OrphanPath` and `-MOCPath` take **relative paths from the vault root**, NOT absolute paths.
- Correct: `01\Bahá'í\Daily Quotes\2024-03.md`
- Wrong: `C:\Users\awt\Sync\Obsidian\01\Bahá'í\Daily Quotes\2024-03.md`

Use `$orphans[$i].RelativePath` from `orphan_list.json` and strip the vault prefix from MOC paths.
MOC list is saved to `C:\Users\awt\moc_list.json` after `list-mocs`; strip `C:\Users\awt\Sync\Obsidian\` to get relative path.

## Classify-Orphans Batch Pattern
For vault-wide sweeps, load both JSON files and run inline (do NOT write a script file — encoding issues with em dashes in filenames):
```powershell
$orphans = Get-Content "C:\Users\awt\orphan_list.json" -Encoding UTF8 | ConvertFrom-Json
$mocList = Get-Content "C:\Users\awt\moc_list.json" -Encoding UTF8 | ConvertFrom-Json
$vault = "C:\Users\awt\Sync\Obsidian\"
function Rel($full) { $full.Replace($vault, '') }
# then call: powershell -File $s -Action link-orphan -OrphanPath $orphans[$i].RelativePath -MOCPath (Rel $mocList[$j].FullPath) -SubsectionName '...'
```

## Procedure

1. **List available MOCs** — run `list-mocs` action; present to user for selection
2. **Get subsections** — run `get-subsections` for the chosen MOC; present to user for selection
3. **Find candidates** — for the selected subsection, Grep `C:\Users\awt\Sync\Obsidian\` for relevant keywords based on the subsection topic; analyze relevance; rank top 20 candidates
4. **Present for approval** — show candidates with brief rationale; user approves or rejects each
5. **Create links** — for approved files, run `link-orphan` action using relative paths (see above)

## Example invocations
- "link orphans to Recipes"
- "find orphans for Bahá'í Faith / Core Teachings"
- "link orphans for Georgetown LSA"
