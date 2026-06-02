Remove misplaced links from MOC files, reassign them to correct subsections, and clean up structural artifacts.

## Parameters

No arguments. Always operates on all MOC files in `D:\Obsidian\Main\00 - Home Dashboard\`.

---

## Step 1 — Locate MOC Files

Glob `D:\Obsidian\Main\00 - Home Dashboard\*MOC*.md` to get all MOC files.

The 9 key MOCs to inspect:
- `MOC - Bahá'í Faith.md`
- `MOC - Health & Nutrition.md`
- `MOC - NLP & Psychology.md`
- `MOC - Technology & Computers.md`
- `MOC - Social Issues.md`
- `MOC - Home & Practical Life.md`
- `MOC - Science & Nature.md`
- `MOC - Music & Record Collection.md`
- `MOC - Travel & Exploration.md`

---

## Step 2 — Detect Misplacements

For each MOC, read its full content and flag:

| Pattern | What to look for |
|---|---|
| Folder links | `[[10 - Clippings]]`, `[[20 - Permanent Notes]]`, `[[09 - Attachments]]` — folder wikilinks, not note links |
| Generic cleanup artifacts | `"Orphan File Connection Report"`, `"Untitled"`, `"New Note"` — non-content stubs |
| Wrong-domain notes | Recipes in Technology MOC; travel tips in Health MOC; cognitive science in Social Issues MOC |
| Duplicate links | Same note linked more than once in a single MOC |
| Cross-reference MOC links | `[[MOC - X]]` appearing inside a content section (not the Related Topics section) |

---

## Step 3 — Reassignment Table

Use this table to determine where misplaced links belong:

| Content type | Correct MOC | Correct subsection |
|---|---|---|
| Programming, software, AI, PKM, Obsidian | MOC - Technology & Computers | AI & Machine Learning / PKM & Obsidian |
| Religious/spiritual (non-Bahá'í) | MOC - Social Issues | Religion & Society |
| Travel tips, packing lists, destination guides | MOC - Travel & Exploration | — |
| Life hacks, household, practical advice | MOC - Home & Practical Life | Practical Tips & Life Hacks |
| Cognitive science, memory, learning, bias | MOC - NLP & Psychology | Cognitive Science |
| Nature, ecology, gardening, plants, animals | MOC - Science & Nature | Gardening & Nature |
| Cross-reference MOC links | Any MOC | Related Topics section at bottom |

---

## Step 4 — Clean Each MOC

For each flagged item:

1. **Remove** the misplaced link from its current location
2. **Add** the link to the correct MOC at the correct subsection
3. If the receiving MOC's subsection does not exist yet, create it with a `###` heading in the right alphabetical position
4. For cross-reference MOC links (`[[MOC - X]]`): move to a `## Related Topics` section at the bottom of the file (create if absent)
5. For folder links and generic stubs: remove entirely, do not relocate

Do NOT remove links that are merely in unexpected subsections but in the right MOC — only reassign when the MOC itself is wrong.

---

## Step 5 — Report

Summary table of all changes made:

| Link | Was in | Moved to | Subsection | Action |
|---|---|---|---|---|
| [[Recipe - Sourdough Bread]] | MOC - Technology | MOC - Home & Practical Life | Recipes | Reassigned |
| [[10 - Clippings]] | MOC - Bahá'í Faith | — | — | Removed (folder link) |

Also report a count of: links reassigned · links removed · duplicates removed · MOCs with no changes needed.

---

## Step 6 — Preserve Encoding

Read and write all files with UTF-8 encoding. Do not alter any diacritical characters (Bahá'í, Riḍván, etc.).

---

## Output

Print the summary table. Do not log to Claude Action Log — this is housekeeping.
