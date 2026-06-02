---
name: workflow-cleanup-mocs
description: "Cleanup MOCs workflow — remove misplaced links, reassign to correct MOC subsections, 9 key MOCs, common misplacement patterns"
metadata:
  node_type: memory
  type: reference
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Trigger
"cleanup MOCs" or "clean up MOCs"

---

## Location
MOC files: `D:\Obsidian\Main\00 - Home Dashboard\*MOC*.md`

## Purpose
Remove links that don't belong in their subsections (misplaced by automated linking)

## Workflow
1. Read each MOC file in the vault
2. Examine each subsection and its links
3. Identify links that don't match the subsection topic
4. Remove misplaced links while preserving properly categorized ones
5. Reassign removed links to correct MOCs and subsections
6. Write cleaned MOC files back

## Common Misplacements
- Recipes (Black Bean, Quinoa, etc.) in non-recipe MOCs
- Religious content in secular MOCs and vice versa
- Technology/AI content in unrelated MOCs
- Folder links like `[[10 - Clippings]]` that aren't actual notes
- Generic items like "Orphan File Connection Report" that got linked everywhere

## Common Reassignment Targets
| Content type | Correct destination |
|---|---|
| Tech/programming | Technology & Computers (appropriate subsection) |
| Religious/spiritual | Social Issues > Religion & Society |
| Travel tips | Travel & Exploration |
| Life hacks/practical | Home & Practical Life > Practical Tips & Life Hacks |
| Cognitive/psychology | NLP & Psychology > Cognitive Science |
| Nature/ecology | Science & Nature > Gardening & Nature |
| Cross-reference MOC links | Related Topics section |

Provide a summary table of all reassignments made.

## Key MOCs to Check
- `MOC - Bahá'í Faith.md`
- `MOC - Health & Nutrition.md`
- `MOC - NLP & Psychology.md`
- `MOC - Technology & Computers.md`
- `MOC - Social Issues.md`
- `MOC - Home & Practical Life.md`
- `MOC - Science & Nature.md`
- `MOC - Music & Record.md`
- `MOC - Personal Knowledge Management.md`

Preserve UTF-8 encoding when writing files.
