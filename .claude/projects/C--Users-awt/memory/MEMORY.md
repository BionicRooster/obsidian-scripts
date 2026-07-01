# Memory

## Global Memory
- Global memory index: [memory.md](../../../memory/memory.md)
- [memory_map.md](memory_map.md) — Full map of all memory files (global + project); directory tree, auto-injection, adding new memory

## User Interests
- [user_intellectual_interests.md](user_intellectual_interests.md) — AI/RLHF, Grinder deletion, Meta Model; deep vs. surface structure in language

## Obsidian Domain
- [domain/obsidian.md](domain/obsidian.md) — MCP tool preference, MOC rules, People Index rules, Related Notes, activity log, Riḍván spelling
- [domain/bahai_publication_standards.md](domain/bahai_publication_standards.md) — Correct Bahá'í diacriticals, spellings, capitalization rules
- [domain/synthesis.md](domain/synthesis.md) — Synthesis Layer rules, Query-to-File Rule, Vault Lint Workflow, current synthesis pages
- [domain/vault_mocs.md](domain/vault_mocs.md) — 17 canonical MOC names, topic routing, special overrides (JapanTrip, EliasWhiteTalbot, FOL)
- [domain/vault_tags.md](domain/vault_tags.md) — Canonical tag vocabulary, duplicates/variants, import artifact tags; BahaiScripture and Bahai rules

## Completed Projects
- [projects_completed.md](projects_completed.md) — Recipes (389), Amish Economics PDF, Title Case fix (456), Riḍván spelling fix (145)

## Feedback — Writing Style
- [feedback_transparency_patterns.md](feedback_transparency_patterns.md) — Three required patterns every session: Agentic Update Formula pre-tool statements, TaskCreate task lists for >2-step workflows, receipt tables at workflow close
- [feedback_anti_ai_style.md](feedback_anti_ai_style.md) — Banned words, structural tics, and human constructions to use; self-check before any long response
- [feedback_name_memories.md](feedback_name_memories.md) — Name memory files in dialogue when recalling them so Wayne can see what's being used
- [feedback_adversarial_review.md](feedback_adversarial_review.md) — Adversarial-critic + independent verification before applying corrections; confirmed effective, now `/adversarial-review` skill
- [feedback_abbreviation_format.md](feedback_abbreviation_format.md) — First use of any abbreviation in a vault note must spell out the full text followed by the abbreviation in parentheses

## Feedback — UI & Design
- [feedback_color_contrast.md](feedback_color_contrast.md) — Blue text on dark backgrounds must be very bright; blues need most contrast
- [feedback_bold_spacing.md](feedback_bold_spacing.md) — Bold `**text**` needs leading whitespace; `-**text**` = literal asterisks in print

## Feedback — Vault Workflows
- [feedback_source_file_handling.md](feedback_source_file_handling.md) — After RTF/DOCX→.md conversion, move source to 09 - Attachments; never delete
- [feedback_content_filter.md](feedback_content_filter.md) — API 400 filter: incremental Edit in small chunks; filter blocks output not input
- [feedback_classify_notes.md](feedback_classify_notes.md) — Always do all 3 steps: move (not vault root/02-Projects), link to MOC, add tags + nav
- [feedback_dual_moc_library.md](feedback_dual_moc_library.md) — Library-substantive content links to both its topical MOC and FOL MOC / Overview
- [feedback_sketchplanations_xkcd.md](feedback_sketchplanations_xkcd.md) — Tag routes to Sketchplanations section; xkcd same; topical dual-links OK
- [feedback_wcwbf_gccma.md](feedback_wcwbf_gccma.md) — WCWBF content always gets a GCCMA section link in addition to any other placement
- [feedback_biography_format.md](feedback_biography_format.md) — Gold standard: Helen Cordes.md; 3 required resources (vault + web + email)
- [feedback_transcript_format.md](feedback_transcript_format.md) — Keep first timestamp per paragraph; group by topic shift; preserve footnotes
- [feedback_recipe_processing.md](feedback_recipe_processing.md) — Always retain narrative; place in ## Story after recipe, before Related Notes
- [feedback_people_index_format.md](feedback_people_index_format.md) — No blank lines between ### Name entries within a section
- [feedback_people_index_stubs.md](feedback_people_index_stubs.md) — Every name in People Index immediately; full biography in 15-People at 5+ links
- [feedback_vault_permissions.md](feedback_vault_permissions.md) — Do not pause for vault read/write/move ops — permission is permanently pre-granted
- [feedback_kindle_clippings_readonly.md](feedback_kindle_clippings_readonly.md) — Kindle Clippings read-only; link INTO them; never modify
- [feedback_tag_regex.md](feedback_tag_regex.md) — Tags: "Bahai" only (no diacriticals); everywhere else always "Bahá'í"; regex line-anchored
- [feedback_bahai_scripture_tag.md](feedback_bahai_scripture_tag.md) — Add BahaiScripture tag to notes by Central Figures; not Shoghi Effendi or UHJ
- [feedback_daily_note_whats_new.md](feedback_daily_note_whats_new.md) — "What's New" dataview in daily notes uses dur(2 days), not dur(10 days)

## Feedback — Corrections Log
- [feedback_corrections_log.md](feedback_corrections_log.md) — Log confirmed corrections to corrections.md: date, original, changed, category

## Feedback — Security
- `feedback_no_secrets_in_code` — moved to global memory (`~/.claude/memory/feedback_no_secrets_in_code.md`)

## References & Scripts
- [fix_broken_related_notes.md](fix_broken_related_notes.md) — Scripts to repair vault-wide broken Related Notes (path/alias, bare MOC refs)
- [domain/scripts.md](domain/scripts.md) — 549-script catalog (PS1 + PY); Grep this before writing new code; refresh with update-script-catalog.ps1

## Elias White Talbot Project
- [domain/elias_talbot.md](domain/elias_talbot.md) — EWT = Elias William Talbot (1820–1876); project folder; Johnson family is Wayne's family line

## Workflows
- [workflow_update_person_files.md](workflow_update_person_files.md) — Expand stubs to biography format; processed list; skip private individuals
- [workflow_video_processing.md](workflow_video_processing.md) — yt-dlp captions, Python deduplication; timestamped transcript; Web Clipper path
- [workflow_model_routing.md](workflow_model_routing.md) — Haiku-safe vs Sonnet-required vs Opus-appropriate vault workflows; subagent spawning
- [workflow_classify_notes.md](workflow_classify_notes.md) — Video Clipper sweep, MOC linking, People Index, Synthesis, moving rules, EWT exception
- [workflow_daily_briefing.md](workflow_daily_briefing.md) — Calendar, markets (CALM/KQQQ), Austin FC + USMNT/USWNT, Bahá'í Badí date; exact format
- [workflow_soccer_box_score.md](workflow_soccer_box_score.md) — Sources, pre-flight clipping search, content rules, event format, cross-verification
- [workflow_book_highlights.md](workflow_book_highlights.md) — 5 extraction paths (photos, PDF, pasted, vault .md, DOCX); incremental append mode
- [workflow_resolve_unknowns.md](workflow_resolve_unknowns.md) — Parameters (age filter, scope, sources), 6-step procedure, 3× rule, re-check
- [workflow_cleanup_mocs.md](workflow_cleanup_mocs.md) — Remove misplaced MOC links, reassign to correct subsections, 9 key MOCs, common patterns
- [workflow_crosslink_files.md](workflow_crosslink_files.md) — Find cross-topic related notes, add wikilinks, connection patterns, example links
- `/improve-system` skill — Audit/Skill/Experience/Historical/Foundation modes; full procedure in `~/.claude/commands/improve-system.md`

## Dashboard
- [domain/dashboard_iis.md](domain/dashboard_iis.md) — Weather/air quality dashboard; 192.168.68.65:8080; IIS port 8080; 500.19 fix via icacls

## Tools & Environment
- [domain/libreoffice.md](domain/libreoffice.md) — LibreOffice installed; enables RTF and .pages conversion in pdf_to_obsidian.py
- [tools/emclient.md](tools/emclient.md) — eM Client email; SQLite .dat files across 11+ accounts; schema, search patterns, Haiku routing

## Claude Configuration Records
- Vault folder: `D:\Obsidian\Main\01\Claude\` — dated snapshots; add files with `YYYY-MM-DD ` prefix when restructuring memory

## Recurring Workflows
- [project_resolve_unknowns_schedule.md](project_resolve_unknowns_schedule.md) — Monthly: resolve unknowns box scores >30 days; last run 2026-06-02

## Soccer Domain
- [domain/soccer_sources.md](domain/soccer_sources.md) — MLS source tiers; FBref preferred; FotMob ~7-min timing artifact; Sofascore banned
- [domain/soccer_national_teams.md](domain/soccer_national_teams.md) — USMNT/USWNT records planned; MOC subsections added; same workflow applies
