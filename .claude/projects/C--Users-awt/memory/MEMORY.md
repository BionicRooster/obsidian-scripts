# Memory

## Global Memory
- Global memory index: [memory.md](../../../memory/memory.md)
- [memory_map.md](memory_map.md) — Full map of all memory files (global + project), directory tree, auto-injection behavior, stub pattern, adding new memory guide

## User Interests
- [user_intellectual_interests.md](user_intellectual_interests.md) — AI training/learning/RLHF; John Grinder's deletion phenomenon; Meta Model; deep vs. surface structure in language; how AI handles under-specified prompts

## Obsidian Domain
- [domain/obsidian.md](domain/obsidian.md) — MCP tool preference, MOC rules, People Index rules, Related Notes, activity log, Riḍván spelling
- [domain/bahai_publication_standards.md](domain/bahai_publication_standards.md) — correct spellings/diacriticals for Central Figures, family terms (Afnán, Aghsán), capitalization rules, common misspellings to fix
- [domain/synthesis.md](domain/synthesis.md) — Synthesis Layer rules, Query-to-File Rule, Vault Lint Workflow, current synthesis pages

## Completed Projects
- [projects_completed.md](projects_completed.md) — Recipes (389 files), Amish Economics PDF, Title Case fix (456 renamed), Riḍván spelling fix (145 files)

## Feedback — UI & Design
- [feedback_color_contrast.md](feedback_color_contrast.md) — Blue text on dark backgrounds must be very bright; blues need the most contrast
- [feedback_bold_spacing.md](feedback_bold_spacing.md) — Bold `**text**` must be preceded by a space/tab; `-**text**` prints as literal asterisks in Obsidian print

## Feedback — Vault Workflows
- [feedback_source_file_handling.md](feedback_source_file_handling.md) — After RTF/DOCX→.md conversion, move source to 09 - Attachments; never delete
- [feedback_content_filter.md](feedback_content_filter.md) — API 400 content filter: use incremental Edit in small chunks; filter blocks output not input
- [feedback_classify_notes.md](feedback_classify_notes.md) — Always do all 3 steps: move (not vault root/02-Projects), link to MOC, add tags + nav
- [feedback_biography_format.md](feedback_biography_format.md) — Gold standard: Helen Cordes.md; 3 required resources (vault + web + email); full biography format
- [feedback_transcript_format.md](feedback_transcript_format.md) — Keep first timestamp per paragraph; group by topic shift; preserve footnotes
- [feedback_recipe_processing.md](feedback_recipe_processing.md) — Always retain narrative; place in ## Story after recipe, before Related Notes
- [feedback_people_index_format.md](feedback_people_index_format.md) — No blank lines between ### Name entries within a section
- [feedback_people_index_stubs.md](feedback_people_index_stubs.md) — Add every name to People Index immediately with source note link; create full biography in 15-People only at 5+ vault links; insert alphabetically, never append
- [feedback_vault_permissions.md](feedback_vault_permissions.md) — Do not pause for confirmation on vault read/write/move ops — permission is permanently pre-granted in CLAUDE.md
- [feedback_kindle_clippings_readonly.md](feedback_kindle_clippings_readonly.md) — Kindle Clippings are read-only; link INTO them from MOCs/notes only, never modify the clipping files
- [feedback_tag_regex.md](feedback_tag_regex.md) — Tags: "Bahai" only (no diacriticals); everywhere else always "Bahá'í"; regex must be line-anchored `(?m)^(\s*-\s+)TAG\s*$`
- [feedback_bahai_scripture_tag.md](feedback_bahai_scripture_tag.md) — Add BahaiScripture tag to any note attributed to a Central Figure (Bahá'u'lláh, The Báb, 'Abdu'l-Bahá); not for Shoghi Effendi or UHJ
- [feedback_daily_note_whats_new.md](feedback_daily_note_whats_new.md) — "What's New" dataview in daily notes uses dur(2 days), not dur(10 days)

## Feedback — Security
- `feedback_no_secrets_in_code` — moved to global memory (`~/.claude/memory/feedback_no_secrets_in_code.md`)

## References & Scripts
- [fix_broken_related_notes.md](fix_broken_related_notes.md) — Scripts to repair vault-wide broken Related Notes (path/alias and bare MOC ref patterns)
- [domain/scripts.md](domain/scripts.md) — 549-script catalog (PS1 + PY); Grep this before writing new code; refresh with update-script-catalog.ps1

## Elias White Talbot Project
- [domain/elias_talbot.md](domain/elias_talbot.md) — EWT = Elias William Talbot (1820–1876); project folder; Johnson family is Wayne's family line

## Workflows
- [workflow_update_person_files.md](workflow_update_person_files.md) — Expand people stubs to biography format; already-processed list; private individuals to skip
- [workflow_video_processing.md](workflow_video_processing.md) — yt-dlp captions, Python deduplication, Obsidian note structure with timestamped transcript
- [workflow_model_routing.md](workflow_model_routing.md) — Haiku-safe vs Sonnet-required vs Opus-appropriate vault workflows; subagent spawning pattern
- [workflow_classify_notes.md](workflow_classify_notes.md) — Video Clipper sweep, MOC linking, People Index check, Synthesis check, moving rules, exclusions, Elias White Talbot exception
- [workflow_daily_briefing.md](workflow_daily_briefing.md) — Calendar, markets (CALM/KQQQ), Austin FC + USMNT/USWNT, Bahá'í Badí date and news; exact briefing format
- [workflow_soccer_box_score.md](workflow_soccer_box_score.md) — Sources, pre-flight clipping search, content rules, event format, cross-verification, discrepancy handling
- [workflow_book_highlights.md](workflow_book_highlights.md) — 5 extraction paths (photos, PDF, pasted text, vault .md, annotated DOCX); incremental append mode
- [workflow_resolve_unknowns.md](workflow_resolve_unknowns.md) — Parameters (age filter, scope, sources), 6-step procedure, 3× rule, re-check convention
- [workflow_cleanup_mocs.md](workflow_cleanup_mocs.md) — Remove misplaced MOC links, reassign to correct subsections, 9 key MOCs, common patterns
- [workflow_crosslink_files.md](workflow_crosslink_files.md) — Find cross-topic related notes, add wikilinks, connection patterns, example links
- `/improve-system` skill — 5 modes: Audit (stale/conflict/duplicate), Skill Review, Experience (capture win/lesson), Historical Review (mine .jsonl sessions), Foundation; full procedure in `~/.claude/commands/improve-system.md`

## Dashboard
- [domain/dashboard_iis.md](domain/dashboard_iis.md) — Weather/air quality dashboard; URL http://192.168.68.65:8080; IIS on port 8080; 500.19 fix via icacls

## Tools & Environment
- [domain/libreoffice.md](domain/libreoffice.md) — LibreOffice installed at `C:\Program Files\LibreOffice\program\soffice.exe`; enables full-fidelity RTF and .pages conversion in pdf_to_obsidian.py
- [tools/emclient.md](tools/emclient.md) — eM Client is the preferred email interface for all searches; local SQLite .dat files across 11+ accounts; schema, search pattern, skill script paths, Haiku-safe routing note

## Claude Configuration Records
- Vault folder: `D:\Obsidian\Main\01\Claude\` — dated snapshots of memory config and process docs; add new files here with `YYYY-MM-DD ` prefix whenever memory is restructured

## Recurring Workflows
- [project_resolve_unknowns_schedule.md](project_resolve_unknowns_schedule.md) — Run "resolve unknowns box scores older than 30 days" monthly; last run 2026-06-02; remind if forgotten

## Soccer Domain
- [domain/soccer_sources.md](domain/soccer_sources.md) — MLS box score source reliability tiers; FBref preferred clip source; FotMob ~7-min timing artifact; Sofascore banned; card reason limitations
- [domain/soccer_national_teams.md](domain/soccer_national_teams.md) — USMNT/USWNT records planned; MOC subsections added; same workflow applies
