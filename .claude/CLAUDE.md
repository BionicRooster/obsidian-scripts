# User Preferences

## File Locations
- Obsidian vault: D:\Obsidian\Main
- Master MOC Index: 00 - Home Dashboard/Master MOC Index
- Obsidian maintenance script: C:\Users\awt\obsidian_maintenance.ps1

## Coding Preferences
- When writing code in any language, be verbose in commenting. Comment the usage of every variable.

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

## 2024 Columbia River Trip — Standing MOC Rule
- Project folder: `D:\Obsidian\Main\02 - Working Projects\2024 Columbia River Trip\`
- MOC section: `MOC - Travel & Exploration.md` → `## Specific Locations` → `### 2024 Columbia River Trip`
- Any note tagged `#2024-WashingtonTrip` (or tagged with both `Travel` and `Megaflood`/`Washington`) belongs in this project folder and must be linked in the `### 2024 Columbia River Trip` subsection.
- When classifying recent notes or cleaning MOCs, check for these tags and update the subsection accordingly.
- Sub-groupings within the subsection: **Trip Journal**, **Columbia River Gorge**, **Eastern Washington / Grand Coulee**

## Cleanup MOCs Workflow
When the user says "cleanup MOCs" or "clean up MOCs":
1. MOC files location: D:\Obsidian\Main\00 - Home Dashboard\*MOC*.md
2. Purpose: Remove links that don't belong in their subsections (misplaced by automated linking)
3. Workflow:
   - Read each MOC file in the vault
   - Examine each subsection and its links
   - Identify links that don't match the subsection topic (e.g., recipes in Bahá'í Faith, technology in Health)
   - Remove misplaced links while preserving properly categorized ones
   - Common misplacements to look for:
     - Recipes (Black Bean, Quinoa, etc.) in non-recipe MOCs
     - Religious content in secular MOCs and vice versa
     - Technology/AI content in unrelated MOCs
     - Folder links like [[10 - Clippings]] that aren't actual notes
     - Generic items like "Orphan File Connection Report" that got linked everywhere
   - Write cleaned MOC files back
   - Reassign removed links to correct MOCs and subsections:
     - For each removed link, determine the appropriate MOC based on content topic
     - Add the link to the correct subsection within that MOC
     - Common reassignments:
       - Tech/programming links → Technology & Computers (appropriate subsection)
       - Religious/spiritual content → Social Issues > Religion & Society
       - Travel tips → Travel & Exploration
       - Life hacks/practical tips → Home & Practical Life > Practical Tips & Life Hacks
       - Cognitive/psychology content → NLP & Psychology > Cognitive Science
       - Nature/ecology content → Science & Nature > Gardening & Nature
       - Cross-reference MOC links → Related Topics section
     - Provide a summary table of all reassignments made
4. Key MOCs to check:
   - MOC - Bahá'í Faith.md
   - MOC - Health & Nutrition.md
   - MOC - NLP & Psychology.md
   - MOC - Technology & Computers.md
   - MOC - Social Issues.md
   - MOC - Home & Practical Life.md
   - MOC - Science & Nature.md
   - MOC - Music & Record.md
   - MOC - Personal Knowledge Management.md
5. Preserve UTF-8 encoding when writing files

## FOL (Friends of the Georgetown Public Library)
- MOC location: D:\Obsidian\Main\00 - Home Dashboard\MOC - Friends of the Georgetown Public Library.md
- FOL files folder: D:\Obsidian\Main\01\FOL
- When an item is tagged with #FOL, ensure it is included in the FOL MOC
- Move any new FOL-related files to the 01/FOL folder

## Crosslink Files Workflow (crosslink_files)
When the user says "crosslink_files" or "crosslink files":
1. Purpose: Find notes in the vault that are logically related across different topics/MOCs and add wikilinks between them
2. Workflow:
   - Read MOC files to identify key notes in different topic areas
   - Search for notes that bridge multiple disciplines (e.g., cognitive science + health, race issues + religion)
   - For each identified note, read the actual note file (not the MOC)
   - Add a "## Related Notes" section (or update existing one) with wikilinks to logically connected notes from OTHER topic areas
   - Do NOT add links to MOC files - only link to actual content notes
   - Do NOT modify files in "09 - Kindle Clippings" folder (no outgoing links added), but other files CAN link TO files in that folder
3. Cross-topic connection patterns to look for:
   - Cognitive science/psychology ↔ Health/medical (brain, learning, memory)
   - Race/social justice books ↔ Bahá'í teachings on unity
   - Productivity/PKM resources ↔ Psychology/cognitive science
   - Maker/technology projects ↔ Social development/education
   - Religious/spiritual topics ↔ Social issues
   - Science/nature ↔ Indigenous knowledge
   - Books that reference each other or share themes
4. Example cross-links:
   - Dyslexia articles → link to each other and to learning/cognitive notes
   - Race books (Sum of Us, My Grandmother's Hands) → link to Bahá'í race unity teachings
   - Kahneman's Thinking Fast and Slow → link to Dunning-Kruger, productivity notes, cognitive bias articles
   - Inspirational tech stories (Boy Who Harnessed Wind) → link to maker projects, sustainability
5. Output: Provide a summary table showing which notes were updated and what links were added
6. Preserve UTF-8 encoding when editing files

## Classify Recent Notes Workflow
When the user says "classify recent notes" or "link recent notes to MOCs":
1. Purpose: Find notes created in the last N days (default: 2) and link them to appropriate MOC subsections
2. Exclusions (always skip these):
   - People folder (\\People\\)
   - Journals folder (\\Journals\\, \\00 - Journal\\)
   - Templates folder (\\Templates\\)
   - Resources folders (\\.resources)
   - Images folder (\\images\\, \\Attachments\\, \\00 - Images\\)
   - Home Dashboard folder (MOC files themselves)
   - System files (Orphan Files.md)
3. Moving rules:
   - ONLY move files that are already in a subdirectory (e.g., 10 - Clippings, vault root subfolders)
   - Do NOT move files that are in the vault root (D:\Obsidian\Main\*.md) — classify and link them but leave them in place
   - Root-level files will be manually reviewed and moved to "20 Permanent Notes" by the user
   - **Elias White Talbot exception**: If a note contains the name "Elias White Talbot" or the tag "EliasWhiteTalbot", move it to `D:\Obsidian\Main\02 - Working Projects\Elias White Talbot - Project\` instead of any `01/` subdirectory. Also ensure the `EliasWhiteTalbot` tag is present in the frontmatter. This overrides all other moving rules (including the vault root rule — even vault root files with this content get moved to the project folder).
4. Workflow:
   - **Step 0 (always first): Rename any files with curly/smart apostrophes** (U+2019 `'`) in their names to use standard apostrophes (`'`) before any other operation. Curly apostrophes cause Move-Item to fail silently or delete the source without copying.
   - Run PowerShell script to find files by CreationTime within date range
   - Read all MOC files to understand available subsections
   - Read each recent file to analyze its content
   - Classify using AI based on topic, tags, and content keywords
   - Add wikilink to appropriate MOC subsection
   - Add nav property to file pointing back to MOC (bidirectional linking)
   - Move file to appropriate 01/ subdirectory ONLY if it is not in the vault root
   - **People Index check**: After classifying each file, scan its content for named individuals (authors, subjects, people mentioned). For each name found:
     - Check if a file exists in `D:\Obsidian\Main\15 - People\<Name>.md`
     - Check if the name appears in `D:\Obsidian\Main\People Index.md`
     - If the name is absent from both, add it to a "New Names" list for the session
   - At the end of the workflow, report the New Names list and offer to create stub entries in `15 - People\` and/or add them to the People Index
5. Classification guidelines:
   - FOL/library content → MOC - Friends of the Georgetown Public Library
   - Bahá'í content → MOC - Bahá'í Faith (match subsection: Core Teachings, Administrative Guidance, etc.)
   - AI/tech content → MOC - Technology & Computers > AI & Machine Learning
   - Health/nutrition → MOC - Health & Nutrition
   - Psychology/cognition → MOC - NLP & Psychology
   - Social/political → MOC - Social Issues
   - Science/nature → MOC - Science & Nature
   - xkcd/sketches → MOC - Home & Practical Life > Sketchplanations
   - Micrometeorites → MOC - Science & Nature > Micrometeorites
6. Output: Summary table showing files classified, their assigned MOC, and subsection
7. Preserve UTF-8 encoding when editing files

## Sort To-Do List Workflow
When the user says "sort todo", "sort to-do list", or "resort todos":
1. File location: D:\Obsidian\Main\To-Do List.md
2. Purpose: Organize tasks with uncompleted first, then completed sorted by date descending
3. Workflow:
   - Read the To-Do List file with UTF-8 encoding (preserve BOM)
   - Parse task lines between the header (---) and footer (--- ## Related Notes)
   - Identify completed tasks: lines containing `[x]`
   - Identify uncompleted tasks: lines containing `[ ]`
   - Extract completion dates from each task (patterns: `✅ YYYY-MM-DD`, `" YYYY-MM-DD`, or trailing `YYYY-MM-DD`)
   - Sort completed tasks by most recent date first (descending), dateless tasks at bottom
   - Reconstruct file: header → uncompleted → blank line → completed (sorted) → footer
   - Write back with UTF-8 encoding
4. Output: Count of uncompleted and completed tasks
5. Preserve original mojibake characters (°¸", ³, «, etc.) - do not attempt to fix encoding issues in task text
