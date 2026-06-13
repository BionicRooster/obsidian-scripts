---
name: memory-map
description: "Full map of all Claude memory files — global and project layers, file locations, auto-injection behavior, and CLAUDE.md stub pattern"
metadata: 
  node_type: memory
  type: reference
  created: 2026-05-26
  updated: 2026-06-12
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Architecture Overview

Claude memory operates in two layers. Both index files are auto-injected before every tool call via the PreToolUse hook — they are always present in context. Detail files are loaded on demand only when relevant.

```
C:\Users\awt\.claude\
├── CLAUDE.md                              ← Always loaded (target <15k chars); stubs + standing rules
├── memory\                                ← GLOBAL layer (applies to all projects)
│   ├── memory.md                          ← Global index (auto-injected every turn)
│   ├── — USER —
│   ├── user_identity.md                   ← Wayne & Jo Talbot identity and emails
│   ├── user_roles.md                      ← Retired IT Manager; FOL, GCCMA, Bahá'í roles
│   ├── user_values.md                     ← Core values: family, health, learning, service, accuracy
│   ├── user_audience.md                   ← Vault audience and framing
│   ├── user_projects.md                   ← Active: AI/learning, EWT, Badí', micrometeorites
│   ├── user_bod.md                        ← Personal BOD: 8 members; voice profiles, frameworks
│   ├── — FEEDBACK (GLOBAL) —
│   ├── feedback_epistemic_honesty.md      ← 3× Rule: universal honesty standard
│   ├── feedback_model_policy_changes.md   ← Surface model/policy changes at session start
│   ├── feedback_claudemd_structure.md     ← Keep CLAUDE.md lean; workflows → memory files
│   ├── feedback_no_secrets_in_code.md     ← Never hardcode credentials in code
│   ├── feedback_script_catalog_check.md   ← Grep scripts.md before writing new scripts
│   ├── feedback_word_choice.md            ← Avoid hype/jargon; plain precise language
│   ├── feedback_acronyms.md               ← NHS, OAG, G4NP always all-caps
│   ├── feedback_transparency_agentic.md   ← Progress narration; Impact/Risk Matrix
│   ├── feedback_research_standards.md     ← Citation rules, inference labeling
│   ├── feedback_stub_audit.md             ← Image-only notes aren't stubs definition
│   ├── feedback_verbose_explanations.md   ← Hooks/automation: explain fully
│   ├── domain\
│   │   └── powershell.md                  ← Curly apostrophe pitfalls, char codes, PS1 gotchas
│   └── tools\
│       └── mcp-obsidian.md                ← Deferred loading, tool preference rules
└── projects\
    └── C--Users-awt\
        └── memory\                        ← PROJECT layer (Obsidian vault / home directory work)
            ├── MEMORY.md                  ← Project index (auto-injected every turn)
            ├── memory_map.md              ← THIS FILE
            │
            ├── — USER —
            ├── user_intellectual_interests.md  ← AI/RLHF, Grinder deletion, Meta Model
            │
            ├── — DOMAIN KNOWLEDGE —
            ├── domain\
            │   ├── obsidian.md            ← MCP tools, MOC rules, People Index, Related Notes
            │   ├── bahai_publication_standards.md  ← Diacriticals, Central Figure spellings
            │   ├── synthesis.md           ← Synthesis Layer + Query-to-File Rule + Vault Lint
            │   ├── elias_talbot.md        ← EWT project; Elias William Talbot (1820–1876)
            │   ├── soccer_sources.md      ← Source tiers; FBref, FotMob, Sofascore rules
            │   ├── soccer_national_teams.md  ← USMNT/USWNT records and box score workflow
            │   ├── libreoffice.md         ← LibreOffice path; RTF/.pages conversion
            │   ├── vault_mocs.md          ← 17 canonical MOC names, routing, special overrides
            │   ├── vault_tags.md          ← Tag vocabulary, duplicates, BahaiScripture rule
            │   ├── dashboard_iis.md       ← Weather/air quality IIS dashboard (192.168.68.65:8080)
            │   └── scripts.md             ← 549-script catalog (PS1 + PY); grep before new code
            │
            ├── — FEEDBACK —
            ├── feedback_color_contrast.md
            ├── feedback_bold_spacing.md
            ├── feedback_source_file_handling.md
            ├── feedback_content_filter.md
            ├── feedback_classify_notes.md
            ├── feedback_biography_format.md
            ├── feedback_transcript_format.md
            ├── feedback_recipe_processing.md
            ├── feedback_people_index_format.md
            ├── feedback_people_index_stubs.md
            ├── feedback_kindle_clippings_readonly.md
            ├── feedback_tag_regex.md
            ├── feedback_bahai_scripture_tag.md
            ├── feedback_vault_permissions.md
            ├── feedback_wcwbf_gccma.md
            ├── feedback_sketchplanations_xkcd.md
            ├── feedback_dual_moc_library.md
            ├── feedback_daily_note_whats_new.md
            ├── feedback_corrections_log.md
            │
            ├── — WORKFLOWS (loaded on demand) —
            ├── workflow_classify_notes.md    ← trigger: "classify recent notes"
            ├── workflow_daily_briefing.md    ← trigger: "daily journal" / "briefing"
            ├── workflow_soccer_box_score.md  ← trigger: "soccer box score [A] vs [B]"
            ├── workflow_book_highlights.md   ← trigger: "extract highlights from [book]"
            ├── workflow_resolve_unknowns.md  ← trigger: "resolve unknowns"
            ├── workflow_cleanup_mocs.md      ← trigger: "cleanup MOCs"
            ├── workflow_crosslink_files.md   ← trigger: "crosslink files"
            ├── workflow_update_person_files.md
            ├── workflow_video_processing.md
            ├── workflow_model_routing.md
            │
            ├── — TOOLS —
            ├── tools\
            │   └── emclient.md            ← eM Client SQLite schema, search scripts, Haiku routing
            │
            ├── — REFERENCES & SCRIPTS —
            ├── fix_broken_related_notes.md
            ├── project_resolve_unknowns_schedule.md
            └── projects_completed.md
```

---

## How Auto-Injection Works

The PreToolUse hook (`~/.claude/hooks/pre-tool-memory.sh`) runs before every tool call and injects:
1. The project `MEMORY.md` (index only — one line per file)
2. The global `memory.md` (index only)

Detail files are **not** auto-injected. They are loaded only when I explicitly read them.

---

## CLAUDE.md Stub Pattern

CLAUDE.md contains 3–5 line stubs for each workflow. Format:

```
## Workflow Name
Trigger: "exact phrase the user says"
Read first: `memory/workflow_<name>.md` — one-line summary of what the file contains.
```

CLAUDE.md target size: **under 15k chars**. Size at 2026-05-26 restructure: ~11,887 chars (grown since with new workflow stubs added through 2026-06-12).

---

## Loading Lifecycle

```
New session starts
  → MEMORY.md + memory.md auto-injected (always, ~3KB each)
  → User triggers a workflow
  → Specific workflow_<name>.md read (~2–6KB, now in context for this session)
  → Session ends / new conversation
  → Workflow file unloaded; next session starts clean
```

---

## Adding New Memory

| What you're adding | Where it goes |
|---|---|
| New workflow (multi-step procedure) | `memory/workflow_<name>.md` + 3-line stub in CLAUDE.md |
| Domain knowledge (terminology, constraints) | `memory/domain/<topic>.md` |
| User feedback / correction | `memory/feedback_<topic>.md` (project or global depending on scope) |
| Tool-specific behavior | `memory/tools/<toolname>.md` |
| Universal rule (all projects) | Global `~/.claude/memory/` + global `memory.md` index |
| Project-specific fact | Project `memory/` + project `MEMORY.md` index |

**Rule:** Never put full procedures in CLAUDE.md. If it's more than 5 lines, it belongs in a memory file. See [[feedback-claudemd-structure]].
