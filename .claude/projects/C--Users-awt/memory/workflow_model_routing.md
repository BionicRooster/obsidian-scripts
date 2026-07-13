---
name: workflow-model-routing
description: Which vault workflows are safe to run on Haiku 4.5 vs. require Sonnet 4.6 vs. warrant Fable 5 delegation — model routing and subagent spawning
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 878e4a3b-1840-4509-a6b8-1fd02eee9107
---

Use this to decide whether to spawn a Haiku 4.5 subagent, suggest `/model haiku` for a session, or stay on Sonnet 4.6.

**Why:** Haiku 4.5 (`claude-haiku-4-5-20251001`) is significantly cheaper per token than Sonnet 4.6 or Opus 4.8. Mechanical, rule-based tasks don't benefit from Sonnet's reasoning. Sonnet 4.6/Opus 4.8 should be reserved for judgment, synthesis, and cross-domain work.

**How to apply:** At session start, assess the task list. If all tasks are Haiku-safe, suggest `/model haiku` (Haiku 4.5). If mixed, stay on Sonnet 4.6 (`claude-sonnet-4-6`) and spawn Haiku 4.5 subagents for the mechanical portions.

**CONFIRMED USER PREFERENCE (2026-05-28):** Always apply model routing on classify-recent-notes sessions. Call it out explicitly at the start: identify which steps will run on Haiku 4.5 vs. Sonnet 4.6 before beginning work. For classify sessions, Haiku-safe steps include: file moves, action log append, People Index link additions. Sonnet steps: MOC subsection matching, frontmatter judgment, synthesis check.

---

## Haiku 4.5-Safe (mechanical, rule-based)

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

## Sonnet 4.6-Required (judgment, synthesis, domain knowledge)

| Workflow | Why Sonnet 4.6 |
|----------|----------------|
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

## Opus 4.8-Appropriate (optional upgrade for highest-stakes work)

| Workflow | Why Opus 4.8 |
|----------|--------------|
| New synthesis page creation | When establishing a new canonical view from scratch |
| EWT research with conflicting primary sources | Maximum reasoning depth on genealogical contradictions |
| Memory system restructuring | When reorganizing the memory layer itself |

---

## Fable 5-Appropriate (highest-stakes reasoning, optional upgrade)

| Workflow | Why Fable 5 |
|----------|-------------|
| New synthesis page creation | Establishing a canonical view from scratch across conflicting sources |
| EWT research with conflicting primary sources | Maximum reasoning on genealogical contradictions |
| Memory system restructuring | Reorganizing the memory layer itself |
| Adversarial review of high-stakes notes | Deeper critic reasoning; catches subtle errors Sonnet misses |
| Deep synthesis across novel domains | When the task requires genuine open-ended reasoning, not rule application |

**Cost tradeoff:** Fable 5 is ~3.3× more expensive per token than Sonnet 4.6, uses a different tokenizer (same text tokenizes to ~1×–1.35× more tokens), and always runs thinking (billed even when omitted from display). Only route here when the reasoning depth is genuinely needed.

---

## Subagent Spawning Pattern

When a session mixes task types, spawn subagents at the appropriate model tier:
- Example: "classify recent notes" — Haiku 4.5 scans files and moves them; Sonnet 4.6 does MOC judgment and synthesis updates
- Example: "clean up vault" session — Haiku 4.5 handles duplicates/empty files; Sonnet 4.6 handles orphan linking decisions

### Delegating to Fable 5 via subagent

Pass `model: "fable"` to the Agent tool to route a non-fork subagent to Fable 5:

```
Agent(model: "fable", subagent_type: "general-purpose", prompt: "...")
```

**Hard rule: forks always inherit the parent model** — the `model` override is silently ignored on forks. If the coordinator is running on Sonnet 4.6, any fork is also Sonnet 4.6.

To route a subtask to Fable: spawn a **fresh** (non-fork) agent with `model: "fable"`. Fresh agents start cold with no conversation context, so the prompt must be fully self-contained — brief it like a colleague who just walked in.

**When to delegate to Fable:** the subtask is well-scoped enough to brief in a prompt, but benefits from stronger reasoning (adversarial critique, deep synthesis, conflicting-source reconciliation). Do not delegate mechanical or Sonnet-tier tasks to Fable — it wastes cost with no benefit.
