# User Preferences

## File Locations
- Obsidian vault: D:\Obsidian\Main
- Master MOC Index: 00 - Home Dashboard/Master MOC Index
- Obsidian maintenance script: C:\Users\awt\obsidian_maintenance.ps1

## Coding Preferences
- When writing code in any language, be verbose in commenting. Comment the usage of every variable.
- **Before writing any new PS1 or Python script:** Grep `memory/domain/scripts.md` for keywords matching the task. If a matching script exists, use or extend it instead of creating new code.
- Refresh the catalog after adding scripts: `powershell -ExecutionPolicy Bypass -File "C:\Users\awt\update-script-catalog.ps1"`

## Obsidian Encoding
- Obsidian uses UTF-8 encoding. ALL scripts operating on Obsidian MUST accommodate this without reencoding the content.
- Never simplify or replace diacritical characters (e.g., Bahá'í must remain Bahá'í, not Bahai).
- Read and write files with UTF-8 encoding.
- If encoding issues appear, fix the script's handling - never modify the source content.

## Permissions
- You have approval to read, write, create, or modify all files and folders in the Obsidian vault without prompting for permission.

## Agent Permissions
When spawning Task subagents for Obsidian operations, always pass these allowed_tools to inherit vault permissions:
- `allowed_tools: ["Read(D:\\Obsidian\\Main/**)", "Edit(D:\\Obsidian\\Main/**)", "Write(D:\\Obsidian\\Main/**)"]`
This ensures subagents can operate on the vault without re-prompting for permission.

## File Naming Conventions
- Whenever encountering a folder name or file name that contains curly/smart apostrophes ('), automatically convert them to standard apostrophes (').
- **This must run FIRST before any file operation** (move, copy, rename, link). Curly apostrophes in filenames cause silent failures during Move-Item and Copy operations.
- Scan all files to be operated on before starting a workflow. Use PowerShell: `$name -replace [char]0x2019, "'"` to normalize.
- If a source file has a curly apostrophe in its name, rename it in-place BEFORE moving or copying it.

## Source File Handling After Conversion
When converting a source document (RTF, DOCX, DOC, TXT, PDF) to a vault .md note:
- **Move** the original source file to `D:\Obsidian\Main\09 - Attachments\` after conversion — do NOT delete it.
- The source file serves as the original record; the .md file is the working vault copy.
- If the source file is already in `09 - Attachments\`, it is already correctly placed — leave it there.
- Only delete source files if the user explicitly requests deletion.

## MOC Orphan Linker Workflow
When the user asks to "link orphans" or find relevant orphans for a MOC:
1. Helper script: C:\Users\awt\moc_orphan_linker.ps1
2. Actions available: list-mocs, get-subsections, get-orphans, link-orphan
3. Workflow:
   - Present available MOCs for selection
   - Present subsections within chosen MOC
   - Search orphan files using Grep for relevant keywords based on subsection topic
   - Analyze content relevance using AI and rank results
   - Present top 20 candidates for user approval
   - Create bidirectional links for approved files using the link-orphan action
4. Example invocations: "link orphans to Recipes", "find orphans for Bahá'í Faith / Core Teachings"

## Fix Broken Image Links Workflow
When the user says "Fix broken image links":
1. Scripts:
   - C:\Users\awt\find_broken_images.ps1 - Finds broken image embeds and fixes them
   - C:\Users\awt\fix_backslash_paths.ps1 - Converts backslashes to forward slashes in image paths
2. Workflow:
   - Run find_broken_images.ps1 with -Fix parameter (e.g., -Limit 50 -Fix)
   - IMPORTANT: Obsidian requires forward slashes (/) not backslashes (\) in paths
   - After fixing, run fix_backslash_paths.ps1 to ensure all paths use forward slashes
3. The script finds ![[image.jpg]] embeds pointing to wrong paths, locates the actual image file in the vault, and updates the link
4. Example: powershell -ExecutionPolicy Bypass -File "C:\Users\awt\find_broken_images.ps1" -Limit 100 -Fix

## 2026 Japan Trip — Standing MOC Rule
- Project folder: `D:\Obsidian\Main\02 - Working Projects\2026 Japan Trip\`
- MOC section: `MOC - Travel & Exploration.md` → `## Specific Locations` → `### Japan 2026 Trip`
- Any note tagged `#JapanTrip` belongs in the project folder, not in `01/Japan/`, and must be linked in the `### Japan 2026 Trip` subsection.
- General Japan interest notes (no `JapanTrip` tag) go in `01/Japan/` and the `### Japan` subsection.
- When classifying recent notes or cleaning MOCs, check for the `JapanTrip` tag and route accordingly.

## 2024 Columbia River Trip — Standing MOC Rule
- Project folder: `D:\Obsidian\Main\03 - Completed Projects\2024 Columbia River Trip\`
- MOC section: `MOC - Travel & Exploration.md` → `## Specific Locations` → `### 2024 Columbia River Trip`
- Any note tagged `#2024-WashingtonTrip` (or tagged with both `Travel` and `Megaflood`/`Washington`) belongs in this project folder and must be linked in the `### 2024 Columbia River Trip` subsection.
- When classifying recent notes or cleaning MOCs, check for these tags and update the subsection accordingly.
- Sub-groupings within the subsection: **Trip Journal**, **Columbia River Gorge**, **Eastern Washington / Grand Coulee**

## Cleanup MOCs Workflow
Trigger: "cleanup MOCs" or "clean up MOCs"
Read first: `memory/workflow_cleanup_mocs.md` — full procedure, 9 key MOCs, misplacement patterns, reassignment table.

## FOL (Friends of the Georgetown Public Library)
- MOC location: D:\Obsidian\Main\00 - Home Dashboard\MOC - Friends of the Georgetown Public Library.md
- FOL files folder: D:\Obsidian\Main\01\FOL
- When an item is tagged with #FOL, ensure it is included in the FOL MOC
- Move any new FOL-related files to the 01/FOL folder

## Crosslink Files Workflow
Trigger: "crosslink_files" or "crosslink files"
Use the `/crosslink` skill — finds cross-topic notes and adds bidirectional Related Notes links; full procedure in `~/.claude/commands/crosslink.md`.

## Classify Recent Notes Workflow
Trigger: "classify recent notes" or "link recent notes to MOCs"
Use the `/classify` skill — accepts optional date range (default: last 7 days); full procedure in `~/.claude/commands/classify.md`.

## Soccer Box Score Workflow
Trigger: "write a box score for [Team A] vs [Team B] on [date]" or "soccer box score [Team A] vs [Team B] [date]"
Use the `/box-score` skill — accepts "Team A vs Team B YYYY-MM-DD" as arguments; full procedure in `~/.claude/commands/box-score.md`.

## Resolve Unknowns Workflow
Trigger: "resolve unknowns", "check unknowns", or "update unknowns [parameters]"
Use the `/resolve-unknowns` skill — accepts scope, age filter, and source flags; full procedure in `~/.claude/commands/resolve-unknowns.md`.

## Sort To-Do List Workflow
Trigger: "sort todo", "sort to-do list", or "resort todos"
Use the `/sort-todo` skill — no arguments; full procedure in `~/.claude/commands/sort-todo.md`.

## Book Highlights Extraction Workflow
Trigger: "extract highlights from [book]", "create clippings for [book]", or user points at a source for highlight extraction.
Read first: `memory/workflow_book_highlights.md` — 5 extraction paths (A photos, B PDF, C pasted, D vault .md, E annotated DOCX), Path E `fix_missing_spaces()` technique, output format, incremental append mode with session dividers.

## Synthesis Layer, Query-to-File Rule, and Vault Lint Workflow
Read first: `memory/domain/synthesis.md` — synthesis layer location/purpose, when to check/update, Query-to-File Rule (when to file a query answer as a synthesis page), Vault Lint checks (Contradictions · Thin Pages · Topic Gaps · Stale Claims).

## Vault Activity Log Format

All Claude vault actions are logged in `D:\Obsidian\Main\01\PKM\Claude Action Log.md` — NOT in the daily journal `## My Notes` section. Append a new `## YYYY-MM-DD` section (or add to today's section if it already exists) at the end of the file after each session. Personal notes written by Wayne remain in the daily journal.

Use these parseable prefixes in the log so entries can be searched with grep/PowerShell:

| Prefix | Meaning | Example |
|--------|---------|---------|
| `[INGEST]` | New source classified | `[INGEST] llm-wiki.md → PKM / Obsidian Integration` |
| `[SYNTHESIS]` | Synthesis page updated | `[SYNTHESIS] Georgetown LSA updated — added Churchill Farms gatherings` |
| `[QUERY→FILE]` | Query answer filed as synthesis page | `[QUERY→FILE] Progressive Revelation created` |
| `[LINT]` | Lint pass completed | `[LINT] 2 thin pages, 1 topic gap (Economic Justice)` |
| `[PEOPLE]` | New People Index entry | `[PEOPLE] Karpathy, Andrej added` |
| `[RESOLVE]` | Unknowns resolution pass | `[RESOLVE] 2026-03-01 Austin FC box score — 2 jersey numbers confirmed` |

Search example: `Select-String "\[INGEST\]" "D:\Obsidian\Main\01\PKM\Claude Action Log.md"` reconstructs the full ingest history.

## Daily Journal Briefing Workflow
Trigger: "daily journal", "briefing", "update today's note", "morning briefing", or asks to populate today's daily note.
Use the `/briefing` skill — full procedure embedded in `~/.claude/commands/briefing.md`.

## Memory Management
- Global memory lives at `C:\Users\awt\.claude\memory\`
- Project memory lives at `C:\Users\awt\.claude\projects\{project}\memory\`
- Index files: `memory.md` (global) and `MEMORY.md` (project)
- Domain knowledge files go in `memory/domain/<topic>.md`
- Tool-specific knowledge goes in `memory/tools/<toolname>.md`

## Global Memory
- Project MEMORY.md and the global index are auto-injected before each tool call via PreToolUse hook
  (`~/.claude/hooks/pre-tool-memory.sh`). Load specific topic files only when relevant.
- Global memory supersedes project memory when they conflict
- Write to global memory when a rule or preference applies across all projects

## Global Memory Reference Rule
- When answering a question or beginning a task, check both layers:
  1. `C:\Users\awt\.claude\memory\memory.md` (global index)
  2. `C:\Users\awt\.claude\projects\{current-project}\memory\MEMORY.md` (project index)
- Load the specific memory files referenced by each index entry that is relevant to the task
- Do not load all memory files on every turn — only those whose index descriptions match the task

## Repo Memory Auto-Init
- When entering a project directory that has no `memory\MEMORY.md`, create one automatically
- Stub content: a `# Memory` heading and a `## Global Memory` section pointing to `C:\Users\awt\.claude\memory\memory.md`
- Do NOT auto-create project memory files that would overwrite existing ones

## Domain Knowledge Lifecycle
- Capture domain terminology, constraints, and standards as they arise during work
- After 3+ related facts accumulate, group them into `memory/domain/<topic>.md`
- At session start on a known domain (Bahá'í, Obsidian, PowerShell, soccer), read its domain file
- Retire stale or superseded entries — update or remove rather than letting them accumulate
