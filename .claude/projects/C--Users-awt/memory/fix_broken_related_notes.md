---
name: fix_broken_related_notes
description: Scripts to repair vault-wide broken Related Notes sections (path/alias format, bare MOC refs)
type: reference
---

## Scripts (committed to git, `C:\Users\awt\`)

- **`fix_broken_related_notes.ps1`** — Pass 1: converts `- FolderPath/FileName|Alias` broken links to `[[wikilinks]]`; removes links to missing files and system files (Master MOC Index, etc.)
- **`fix_broken_related_notes2.ps1`** — Pass 2: removes bare `- MOC - SectionName` lines (no brackets) and converts bare `- FolderPath/FileName` entries (no alias) in Related Notes sections
- **`fix_orphans.ps1`** — Fixes orphan file issues: double-space filenames, Reed Island special chars, Kahneman link mismatch, adds Kindle Clippings to MOCs
- **`fix_reed.ps1`** — Helper: renames Reed Island file that had U+00A0 non-breaking spaces in filename

## When to reuse

Run both `fix_broken_related_notes.ps1` then `fix_broken_related_notes2.ps1` in sequence if:
- A batch crosslink/classification tool has run and produced broken Related Notes
- Grep finds `^- [A-Za-z0-9 -]+/[A-Za-z0-9 -]+\|` matches across the vault
- Grep finds `^- MOC - [^\[]` matches across the vault

## How it works

Both scripts build a vault-wide case-insensitive filename index, then scan every `.md` file for the broken patterns. Broken links are converted to `[[ActualFilename]]` (case-corrected from the index), removed if the file doesn't exist, or removed if the target is a system/MOC file.

## Scale of last run (2026-03-20)

- Pass 1: 641 files modified, 4,366 links converted, 1,113 removed
- Pass 2: 636 files modified, 5 links converted, 1,277 removed
- Root cause: old automated crosslink tool generated `path/name|alias` format instead of `[[wikilink]]`
