---
name: memory-map
description: "Full map of all Claude memory files — global and project layers, file locations, auto-injection behavior, and CLAUDE.md stub pattern"
metadata: 
  node_type: memory
  type: reference
  created: 2026-05-26
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Architecture Overview

Claude memory operates in two layers. Both index files are auto-injected before every tool call via the PreToolUse hook — they are always present in context. Detail files are loaded on demand only when relevant.

```
C:\Users\awt\.claude\
├── CLAUDE.md                          ← Always loaded (target <15k chars); contains stubs + standing rules
├── memory\                            ← GLOBAL layer (applies to all projects)
│   ├── memory.md                      ← Global index (auto-injected every turn)
│   ├── user_identity.md
│   ├── feedback_model_policy_changes.md
│   ├── feedback_word_choice.md
│   ├── feedback_acronyms.md
│   ├── feedback_transparency_agentic.md
│   ├── feedback_research_standards.md
│   ├── feedback_verbose_explanations.md
│   ├── feedback_claudemd_structure.md  ← NEW: keep CLAUDE.md lean; workflows → memory files
│   ├── domain\
│   │   └── powershell.md
│   └── tools\
│       └── mcp-obsidian.md
└── projects\
    └── C--Users-awt\
        └── memory\                    ← PROJECT layer (Obsidian vault / home directory work)
            ├── MEMORY.md              ← Project index (auto-injected every turn)
            ├── memory_map.md          ← THIS FILE
            │
            ├── — USER —
            ├── user_intellectual_interests.md
            │
            ├── — DOMAIN KNOWLEDGE —
            ├── domain\
            │   ├── obsidian.md        ← MCP tools, MOC rules, People Index, Related Notes
            │   ├── bahai_publication_standards.md
            │   ├── synthesis.md       ← Synthesis Layer + Query-to-File Rule + Vault Lint
            │   ├── elias_talbot.md    ← EWT project; Elias William Talbot (1820–1876)
            │   ├── soccer_sources.md  ← Source reliability tiers; FBref, FotMob, Sofascore
            │   ├── soccer_national_teams.md
            │   └── libreoffice.md
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

CLAUDE.md target size: **under 15k chars**. Current size after 2026-05-26 restructure: ~11,887 chars.

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
