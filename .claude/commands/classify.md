Classify recent Obsidian vault notes: add MOC links, nav properties, move to correct folders, check People Index, check Synthesis layer.

## Parameters

`$ARGUMENTS` — optional date range or count:
- `/classify` — classify notes from the last 7 days (default)
- `/classify 14 days` — last 14 days
- `/classify 2026-05-20 to 2026-06-02` — explicit date range
- `/classify 30` — last 30 days

---

## Always Skip These Folders

Never process files in:
- `\People\` or `\15 - People\`
- `\Journals\` or `\00 - Journal\`
- `\Templates\` or `\05 - Templates\`
- `\.resources\`
- `\images\`, `\Attachments\`, `\09 - Attachments\`, `\00 - Images\`
- `\00 - Home Dashboard\` (MOC files themselves)
- `Orphan Files.md`
- Kindle Clippings files — read-only, never modify

---

## Step 0 — Rename Curly Apostrophes (ALWAYS FIRST)

Before any other operation, scan all files to be processed for U+2019 (`'`) in their filenames. Rename in-place using:
```powershell
$name -replace [char]0x2019, "'"
```
Curly apostrophes in filenames cause `Move-Item` to fail silently or delete the source without copying. This step must complete before any move or link operation.

---

## Step 1 — Video Clipper Sweep

Before processing new notes, grep `D:\Obsidian\Main\10 - Clippings\` for files containing `*Transcript pending*`. These are Web Clipper skeletons needing transcripts.

For each found file:
1. Read the file's `source:` frontmatter field to get the YouTube URL
2. Download captions via yt-dlp (always use `py -3.12`):
   ```
   py -3.12 -m yt_dlp --write-auto-sub --sub-lang en --skip-download --output "C:\Users\awt\AppData\Local\Temp\yt_transcriptN" "URL"
   ```
   Increment `N` per video in the same session
3. Run the deduplication/merge Python script (see `workflow_video_processing.md` Step 3) to produce a clean timestamped transcript
4. Replace the `*Transcript pending*` placeholder with the full grouped transcript (topic-shifted paragraphs, first timestamp per paragraph only)
5. Add `nav: "[[MOC - Relevant MOC]]"` to frontmatter if absent; add `[[MOC - Relevant MOC]]` backlink as the first line after the frontmatter closing `---`
6. Do NOT rewrite Summary, Key Points, or Action Items sections if the Web Clipper already populated them — only fill if blank
7. Link the finished note in the appropriate MOC subsection
8. Log: `[INGEST] <Title> — Web Clipper skeleton finished (transcript added), linked to <MOC subsection>`

Files finished in the sweep are already in `10 - Clippings\` — do not move them again.

---

## Step 2 — Main Classification Loop

Find files created or modified within the requested date range (use `(Get-Item $file).CreationTime`).

For each file (excluding the always-skip folders above):

1. **Read** the file and analyze topic, tags, and content keywords
2. **Classify** to the most appropriate MOC and subsection (see Classification Map below)
3. **Add wikilink** to the MOC subsection
4. **Add nav property** to the file's frontmatter pointing back to the MOC (bidirectional linking)
5. **Move** the file to the appropriate `01/` subdirectory — **BUT:**
   - Do NOT move files in the vault root (`D:\Obsidian\Main\*.md`) — classify and link them but leave in place; the user will manually review and move them to `20 - Permanent Notes\`
   - Do NOT move files already in `02 - Working Projects\` or `03 - Completed Projects\`
   - **Elias White Talbot exception (overrides all other rules):** If a note contains "Elias White Talbot" or has tag `EliasWhiteTalbot`, move it to `D:\Obsidian\Main\02 - Working Projects\Elias White Talbot - Project\`. Ensure `EliasWhiteTalbot` tag is in frontmatter. This applies even to vault root files.
   - **Japan Trip rule:** Notes tagged `#JapanTrip` belong in `D:\Obsidian\Main\02 - Working Projects\2026 Japan Trip\` and must be linked in `MOC - Travel & Exploration.md` → `## Specific Locations` → `### Japan 2026 Trip`
   - **Columbia River Trip rule:** Notes tagged `#2024-WashingtonTrip` belong in `D:\Obsidian\Main\03 - Completed Projects\2024 Columbia River Trip\` and linked in `### 2024 Columbia River Trip`

---

## Classification Map

| Content type | MOC | Subsection hint |
|---|---|---|
| FOL / library content | MOC - Friends of the Georgetown Public Library | — |
| Bahá'í Faith | MOC - Bahá'í Faith | Core Teachings, Administrative Guidance, etc. |
| AI / machine learning / tech | MOC - Technology & Computers | AI & Machine Learning |
| Health / nutrition | MOC - Health & Nutrition | — |
| Psychology / NLP / cognition | MOC - NLP & Psychology | — |
| Social / political issues | MOC - Social Issues | — |
| Science / nature | MOC - Science & Nature | — |
| Micrometeorites | MOC - Science & Nature | Micrometeorites |
| xkcd / Sketchplanations | MOC - Home & Practical Life | Sketchplanations |
| Soccer / Austin FC | MOC - Soccer | MLS / Austin FC / Soccer |
| Travel — Japan (JapanTrip tag) | MOC - Travel & Exploration | Japan 2026 Trip |
| Travel — Columbia River (2024-WashingtonTrip) | MOC - Travel & Exploration | 2024 Columbia River Trip |
| Recipes / food | MOC - Home & Practical Life | Recipes |
| PKM / Obsidian / productivity | MOC - Technology & Computers | PKM & Obsidian |

---

## Step 3 — People Index Check (after each file)

Scan the file's content for named individuals: authors, subjects, players, coaches, officials, roster members in box scores or team files.

For each name found:
- Check if a file exists at `D:\Obsidian\Main\15 - People\<Name>.md`
- Check if the name appears in `D:\Obsidian\Main\People Index.md`
- If absent from both: add to a **New Names** list for the session

At end of workflow, report the New Names list and offer to create stub People Index entries.

**People Index stub rule:** Add every name immediately with a source note link. Create a full biography in `15 - People\` only when a person accumulates 5+ vault links.

---

## Step 4 — Synthesis Check (after each file)

Read `D:\Obsidian\Main\30 - Synthesis\index.md`. If the file's topic matches an existing synthesis page:
- Read that synthesis page
- Update it to reflect any new evidence, revised claims, or contradictions
- Increment `source_count` in the synthesis page frontmatter

---

## Output

Summary table:

| File | Moved to | MOC linked | Subsection | Notes |
|---|---|---|---|---|

Plus New Names list if any were found.

Log each classified note to the Claude Action Log with `[INGEST]` prefix:
`[INGEST] <filename> → <MOC> / <Subsection>`

Preserve UTF-8 encoding on all file reads and writes.
