---
name: Obsidian Vault — Working Rules
description: Operational rules for working with the Obsidian vault at C:\Users\awt\Sync\Obsidian — tools, MOCs, People Index, Bahá'í content, activity logging
type: feedback
originSessionId: f2c229e5-bd10-4e40-b472-28911306b580
---
Load this file at the start of any Obsidian vault session.

## Tool Preference: MCP Obsidian Tools

Prefer `mcp__mcp-obsidian__*` tools over Read/Write/Edit/Bash/Grep/Glob when they reduce round-trips.

**Substitutions:**
- "What's recently changed?" → `obsidian_get_recent_changes`
- Reading multiple files → `obsidian_batch_get_file_contents`
- Adding a link under a MOC heading → `obsidian_patch_content` (target_type: heading)
- Quick text search → `obsidian_simple_search`
- Listing a directory → `obsidian_list_files_in_dir`
- Today's daily note → `obsidian_get_periodic_note` (period: daily)
- Tag/path queries → `obsidian_complex_search` with JsonLogic

**Condition:** Only substitute when the MCP tool returns a satisfactory response. Fall back to standard tools without hesitation if it fails.

**Critical:** MCP reads do NOT satisfy the Edit tool's "file must be Read first" requirement. If you need to Edit a file, Read it with the Read tool first even if you already fetched it via MCP.

---

## MOC Rules

**Multi-presence:** A note may appear in multiple MOCs simultaneously. Remove a link from a MOC only if it is topically wrong for that MOC — not simply because it appears elsewhere. Cross-MOC presence is a feature.

---

## People Index Rules

**Threshold rules:** See [[feedback_people_index_stubs]] — add every name immediately; create `15 - People/<Name>.md` only at 5+ vault links.

**Individuals only:** The People Index is for named human individuals only. Never add:
- Groups or study groups (e.g., "Group, Junior Youth")
- Organizations or committees
- Roles or titles
- Software tools, APIs, apartment complexes
- Any entry where the "last name" is a non-person term

If uncertain whether an entry is a person, err on the side of exclusion.

---

## Related Notes — Verified Wikilinks Only

Only add `[[wikilinks]]` to Related Notes sections after confirming the target file **exists** in the vault (via Glob, Grep, or directory listing).

**Why:** Unverified links create broken wikilinks and phantom graph nodes. The tipi note incident added `[[Warren-Two Winters in a Tipi]]` before checking the correct filename.

**How to apply:** Before writing any `[[link]]` in Related Notes, confirm the file exists. If unsure, skip it rather than guess.

---

## Activity Log — Append After Every Vault Action

After completing any Obsidian vault action, append an entry to the Claude Action Log — NOT the daily journal.

**File:** `C:\Users\awt\Sync\Obsidian\01\PKM\Claude Action Log.md`

**Format:** Append under today's `## YYYY-MM-DD` section (create it if it doesn't exist). Use parseable prefixes:

| Prefix | Meaning |
|--------|---------|
| `[INGEST]` | New source classified |
| `[SYNTHESIS]` | Synthesis page updated |
| `[QUERY→FILE]` | Query answer filed as synthesis page |
| `[LINT]` | Lint pass completed |
| `[PEOPLE]` | New People Index entry |

The daily journal (`C:\Users\awt\Sync\Obsidian\YYYY-MM-DD.md`) is for Wayne's personal notes only — Claude does not write there.

---

## Riḍván Spelling

When processing any Bahá'í-related files — classification, moving, editing, creating, linking — always verify and fix the spelling of Riḍván:

- **Correct:** `Riḍván` — R + i + ḍ (U+1E0D) + v + á (U+00E1) + n
- **Wrong forms to fix:** `Ridvan`, `Ridván`, `Riḍvan`

**In PowerShell:** `$dotD = [char]0x1E0D; $aAcute = [char]0x00E1; "Ri$($dotD)v$($aAcute)n"`

Applies to file **content**, **frontmatter**, **filenames**, and **wikilinks**. Two-step rename required for Windows filename case changes.

**Why:** The vault had 261+ instances of incorrect spelling across 145 files (2026-04-28).
