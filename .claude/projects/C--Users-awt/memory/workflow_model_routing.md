---
name: workflow-model-routing
description: Which vault workflows are safe to run on Haiku vs. require Sonnet — for token-cost optimization
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 878e4a3b-1840-4509-a6b8-1fd02eee9107
---

Use this to decide whether to spawn a Haiku subagent, suggest `/model haiku` for a session, or stay on Sonnet.

**Why:** Haiku is ~20× cheaper per token. Mechanical, rule-based tasks don't benefit from Sonnet's reasoning. Sonnet/Opus should be reserved for judgment, synthesis, and cross-domain work.

**How to apply:** At session start, assess the task list. If all tasks are Haiku-safe, suggest `/model haiku`. If mixed, stay on Sonnet and spawn Haiku subagents for the mechanical portions.

**CONFIRMED USER PREFERENCE (2026-05-28):** Always apply model routing on classify-recent-notes sessions. Call it out explicitly at the start: identify which steps will run on Haiku vs. Sonnet before beginning work. For classify sessions, Haiku-safe steps include: file moves, action log append, People Index link additions. Sonnet steps: MOC subsection matching, frontmatter judgment, synthesis check.

---

## Haiku-Safe (mechanical, rule-based)

| Workflow | Notes |
|----------|-------|
| Sort to-do list | Pure file parse/sort/write — no judgment |
| Find duplicate files (name + content) | File scan and hash comparison |
| Check for empty files | File system scan only |
| Fix broken image links | Script-driven search and replace |
| Fix backslash paths in image links | Mechanical string replacement |
| Rename files (curly apostrophe fix, title case) | Pattern-based rename |
| Move files to correct folders (clear-cut) | When destination is unambiguous |
| Create People Index stub entries | Template-based, no content judgment |
| People Index — add new names from a list | Mechanical append |
| Vault activity log — append session entry | Structured log write |
| Delete confirmed duplicate/inferior files | After human confirms which to keep |
| Check for files with problematic characters | File scan only |
| eM Client SQLite database scan (schema discovery, keyword search) | Pure data retrieval — Python scripts against .dat files; no judgment needed |
| eM Client email result formatting | Structuring raw rows into a summary table; no synthesis |

---

## Sonnet-Required (judgment, synthesis, domain knowledge)

| Workflow | Why Sonnet |
|----------|------------|
| Classify recent notes | MOC subsection matching requires domain knowledge; ambiguous cases need judgment |
| MOC cleanup | Deciding what belongs where requires understanding topic relationships |
| Link orphans to MOCs | AI relevance ranking across vault content |
| Crosslink files | Cross-domain connection reasoning |
| Synthesis page updates | Multi-source integration, contradiction detection |
| Lint vault | Cross-page contradiction analysis, stale claim detection |
| Query-to-file (synthesis creation) | Requires analysis and synthesis |
| Book highlights extraction (Path D/E) | Content judgment, session divider decisions |
| Soccer box scores | Multi-source reconciliation, discrepancy flagging |
| Memory system updates | Requires understanding patterns across conversations |
| Bahá'í content classification | Publication standards, diacriticals, subsection judgment |
| EWT project research | Complex genealogical reasoning |
| Video transcript processing | Topic-shift grouping, deduplication judgment |
| Repair broken Related Notes (vault-wide) | Pattern recognition across thousands of files |

---

## Opus-Appropriate (optional upgrade for highest-stakes work)

| Workflow | Why Opus |
|----------|----------|
| New synthesis page creation | When establishing a new canonical view from scratch |
| EWT research with conflicting primary sources | Maximum reasoning depth on genealogical contradictions |
| Memory system restructuring | When reorganizing the memory layer itself |

---

## Subagent Spawning Pattern

When a session mixes task types, spawn Haiku subagents for mechanical steps:
- Example: "classify recent notes" — Haiku scans files and moves them; Sonnet does MOC judgment and synthesis updates
- Example: "clean up vault" session — Haiku handles duplicates/empty files; Sonnet handles orphan linking decisions
