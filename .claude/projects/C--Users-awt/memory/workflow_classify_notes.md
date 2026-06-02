---
name: workflow-classify-notes
description: "Classify recent notes — Video Clipper sweep, MOC linking, People Index check, Synthesis check, moving rules, exclusions, Elias White Talbot exception"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Trigger
"classify recent notes" or "link recent notes to MOCs"

---

## Exclusions (always skip these folders)
- People folder (`\\People\\`)
- Journals folder (`\\Journals\\`, `\\00 - Journal\\`)
- Templates folder (`\\Templates\\`)
- Resources folders (`\\.resources`)
- Images folder (`\\images\\`, `\\Attachments\\`, `\\00 - Images\\`)
- Home Dashboard folder (MOC files themselves)
- System files (Orphan Files.md)

## Moving Rules
- ONLY move files that are already in a subdirectory (e.g., 10 - Clippings, vault root subfolders)
- Do NOT move files in the vault root (`D:\Obsidian\Main\*.md`) — classify and link them but leave in place
- Root-level files will be manually reviewed and moved to "20 Permanent Notes" by the user
- **Elias White Talbot exception:** If a note contains "Elias White Talbot" or tag "EliasWhiteTalbot", move it to `D:\Obsidian\Main\02 - Working Projects\Elias White Talbot - Project\`. Ensure the `EliasWhiteTalbot` tag is present in frontmatter. This overrides ALL other moving rules — including the vault root rule.

## Workflow Steps

**Step 0 (always first): Rename curly/smart apostrophes**
Rename any files with U+2019 (`'`) in their names to use standard apostrophes (`'`) before any other operation. Curly apostrophes cause Move-Item to fail silently or delete the source without copying.

**Step 1 — Video Clipper sweep:**
Before processing new notes, grep `D:\Obsidian\Main\10 - Clippings\` for any files containing `*Transcript pending*`. These are Web Clipper skeletons that need transcripts. For each found file:
- Read the file's `source:` frontmatter field to get the YouTube URL
- Download captions via yt-dlp (always use `py -3.12`): `py -3.12 -m yt_dlp --write-auto-sub --sub-lang en --skip-download --output "C:\Users\awt\AppData\Local\Temp\yt_transcriptN" "URL"` — increment N per video in the same session
- Run the deduplication/merge Python script (see `workflow_video_processing.md` Step 3) to produce a clean timestamped transcript
- Replace `*Transcript pending — run Claude video workflow to add deduplicated timestamped transcript.*` with the full grouped transcript (topic-shifted paragraphs, first timestamp per paragraph only)
- Add `nav: "[[MOC - Relevant MOC]]"` to frontmatter if absent; add `[[MOC - Relevant MOC]]` backlink as the first line after frontmatter closing `---`
- Do NOT rewrite Summary, Key Points, or Action Items sections if the Web Clipper already populated them — only fill if blank
- Link the finished note in the appropriate MOC subsection
- Log: `[INGEST] <Title> — Web Clipper skeleton finished (transcript added), linked to <MOC subsection>`
After the video sweep, continue with the main classification loop. Files finished in the sweep are already in `10 - Clippings\` — do not move them again.

**Step 2 — Main classification loop:**
- Run PowerShell script to find files by CreationTime within date range
- Read all MOC files to understand available subsections
- Read each recent file to analyze its content
- Classify using AI based on topic, tags, and content keywords
- Add wikilink to appropriate MOC subsection
- Add nav property to file pointing back to MOC (bidirectional linking)
- Move file to appropriate `01/` subdirectory ONLY if it is not in the vault root

**Step 3 — People Index check (after each file):**
Scan content for named individuals (authors, subjects, players, coaches, officials, and any other people — including all roster members in sports box scores or team files). For each name:
- Check if a file exists in `D:\Obsidian\Main\15 - People\<Name>.md`
- Check if the name appears in `D:\Obsidian\Main\People Index.md`
- If absent from both, add to a "New Names" list for the session
At end of workflow, report the New Names list and offer to create stub entries.

**Step 4 — Synthesis check (after each file):**
Check `30 - Synthesis/index.md`. If the file's topic matches an existing synthesis page, read that page and update it to reflect any new evidence, revised claims, or contradictions. Increment `source_count` in the synthesis page frontmatter.

## Classification Guidelines
- FOL/library content → MOC - Friends of the Georgetown Public Library
- Bahá'í content → MOC - Bahá'í Faith (match subsection: Core Teachings, Administrative Guidance, etc.)
- AI/tech content → MOC - Technology & Computers > AI & Machine Learning
- Health/nutrition → MOC - Health & Nutrition
- Psychology/cognition → MOC - NLP & Psychology
- Social/political → MOC - Social Issues
- Science/nature → MOC - Science & Nature
- xkcd/sketches → MOC - Home & Practical Life > Sketchplanations
- Micrometeorites → MOC - Science & Nature > Micrometeorites

## Output
Summary table: files classified, assigned MOC, subsection. Preserve UTF-8 encoding.
