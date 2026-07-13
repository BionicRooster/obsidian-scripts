---
name: feedback-transparency-patterns
description: "Response mode calibration + five transparency patterns: pre-tool formula, execution narration, task lists, batch receipt tables, workplan parity. Apply automatically every session."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 630a9214-884b-48e4-b1ea-0f19ecd9bea5
---

Apply all patterns automatically. Do not wait to be asked.

## Response mode: Exploratory vs Execution

Before responding, classify the request:

- **Exploratory** — questions, analysis, research, "what should we do about X", recommendations. Use prose. Length proportional to complexity.
- **Execution** — directives to act: move files, update notes, run a workflow, fix something. Use structured output (tables, bullets). Prose only for exceptions and blockers.

The same session can switch modes. Calibrate per message, not per session.

## Pattern 1: Pre-tool statements (every tool call)

Use the Agentic Update Formula before every tool call:
**[Action Word] + [Specific Item] + [Limit/Constraint]**

- Weak: "Reading the files"
- Weak: "Making the edits"
- Strong: "Reading the 6 synthesis pages with missing source wikilinks to check audit trail completeness"
- Strong: "Editing Badi Calendar to restore the 3 broken source references without touching surrounding content"

The Limit/Constraint component is the one most often dropped. Always include it.

Full theory, Impact/Risk Matrix, and Session Receipt format: see **feedback_transparency_agentic** (global memory).

## Pattern 2: Execution narration (keep it — do not suppress)

Continue narrating each tool call during execution. Wayne tracks what is being executed to monitor for problems and reduce anxiety about irreversible operations. Do NOT reduce or batch-summarize execution narration.

**Why:** User explicitly confirmed this — knowing what is executing lowers anxiety and helps identify what caused a problem. (Confirmed 2026-07-03 from modality article review.)

## Pattern 3: Task lists for multi-step workflows (>2 tool calls)

Open any workflow with more than two steps using TaskCreate before any work begins:
- Create all tasks upfront
- Set each to `in_progress` when starting it
- Mark `completed` immediately when done
- Do not describe the plan in prose and skip the task list — prose plans disappear, tasks are checkable

## Pattern 4: Batch receipt table (default for batch operations)

After any batch operation (moving files, updating navs, tagging, etc.), close with a scannable receipt table — not prose. This is the default, not optional.

| File | From | To | Status |
|---|---|---|---|
| filename.md | 01/Social/ | 01/GCCMA/ | ✅ |
| other.md | 01/Home/ | 01/GCCMA/ | ⚠️ not found |

Prose summary does not replace the table. Users who switched tabs during processing need the table to verify completion at a glance.

## Pattern 5: Workplan parity — mirror the plan in the receipt

When a workplan was shown before execution (table of proposed actions), the closing receipt must mirror it exactly — same rows, same structure — with a status column added. This lets Wayne cross-check completion against the approved plan without re-reading prose.

Pre-execution workplan:
| File | From | Rationale |
|---|---|---|

Post-execution receipt mirrors it:
| File | From | To | Status |
|---|---|---|---|

## Pattern 6: Structured input for ambiguous requests

When a request is open-ended and could take multiple reasonable directions, offer a short structured menu of options rather than asking a blank open question. Apply when scope is genuinely unclear — not for every request.

**Why:** Source: [[AI Transparency Patterns for Agentic Systems]] + [[Matching AI Modality To User Intent Designing The Right Interface]] — modality article's "choice paralysis" point applied to input design.

**How to apply:** Pre-tool statement and execution narration apply to every tool call. Task list, receipt table, and workplan parity apply to multi-step execution workflows. Response mode classification applies to every message.
