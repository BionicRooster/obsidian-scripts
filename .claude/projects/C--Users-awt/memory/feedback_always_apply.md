---
name: feedback-always-apply
description: "Universal rules — load this file at the start of every session regardless of task type: name memories, 3× rule, Bahá'í diacriticals, vault folder rules, corrections log, model routing"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 60c405b8-8c2b-4b8f-9074-e80d2873b489
---

Load at the start of every session. These rules apply regardless of task type or domain.

## 1. Name memory files in dialogue
[[feedback_name_memories]]
When recalling or applying a memory file, name it inline: "using **domain/soccer_sources**" or "from **feedback_transparency_patterns**."

## 2. Three-times rule (epistemic honesty)
[[feedback_epistemic_honesty]] — full text in global memory.
Asserting a wrong fact is 3× worse than writing "Unknown." When unsure: write Unknown, never guess. Mark inferences with **[INFERENCE]**. Never fabricate paths, names, dates, quotes, or URLs.

## 3. Bahá'í diacritical rules
[[domain/bahai_publication_standards]] — load for the full spelling table.
- Bahá'u'lláh · 'Abdu'l-Bahá · the Báb · Shoghi Effendi · Riḍván · Afnán · Aghsán
- In YAML **tags only**: `Bahai` (no diacriticals). Everywhere else: always fully marked.
- Fix misspellings on sight in any vault content. Never strip diacriticals.

## 4. Vault folder rules

| Location | Path | Rule |
|---|---|---|
| Vault root | `C:\Users\awt\Sync\Obsidian\` | Base path for all vault operations |
| MOCs | `00 - Home Dashboard\MOC - *.md` | All canonical MOC files live here |
| Permanent notes | `20 - Permanent Notes\` | Long-form reference notes |
| Synthesis pages | `30 - Synthesis\` | Cross-source synthesis; update index after changes |
| People notes | `15 - People\` | Named individuals only; create at 5+ vault links |
| Attachments | `09 - Attachments\` | Move source files here after conversion; never delete originals |
| Clippings inbox | `10 - Clippings\` | Web Clipper landing zone; classify and move to `01/` after processing; never leave in place |
| Kindle Clippings | `01\Kindle Clippings\` | READ-ONLY — link into them; never modify content |

## 5. Log corrections
[[feedback_corrections_log]]
When the user confirms a correction, append a row to `C:\Users\awt\corrections.md` before the session ends. Fields: date · what I wrote · what they changed it to · category (Real miss / Preference / Carryover / Variation).

## 6. Model routing at session start
[[workflow_model_routing]]
Before starting work, assess the task list. If all steps are mechanical (file moves, log appends, renames), note that Haiku 4.5 could handle them and offer it. Stay on Sonnet 4.6 for judgment, synthesis, MOC matching, box scores. Spawn Haiku 4.5 subagents for mechanical portions of mixed sessions.

## 7. Model/policy check
[[feedback_model_policy_changes]] — full text in global memory.
Current confirmed model: claude-sonnet-4-6. If running on a different model, surface it before starting work.
