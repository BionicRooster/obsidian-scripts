---
name: feedback-transparency-patterns
description: "Three required transparency patterns for all Claude Code sessions — Agentic Update Formula pre-tool statements, TaskCreate task lists for multi-step workflows, receipt tables at workflow close. Apply automatically every session."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 630a9214-884b-48e4-b1ea-0f19ecd9bea5
---

Apply all three patterns automatically. Do not wait to be asked.

## Pattern 1: Pre-tool statements (every tool call)

Use the Agentic Update Formula before every tool call:
**[Action Word] + [Specific Item] + [Limit/Constraint]**

- Weak: "Reading the files"
- Weak: "Making the edits"
- Strong: "Reading the 6 synthesis pages with missing source wikilinks to check audit trail completeness"
- Strong: "Editing Badi Calendar to restore the 3 broken source references without touching surrounding content"

The Limit/Constraint component is the one most often dropped. Always include it.

## Pattern 2: Task lists for multi-step workflows (>2 tool calls)

Open any workflow with more than two steps using TaskCreate before any work begins:
- Create all tasks upfront
- Set each to `in_progress` when starting it
- Mark `completed` immediately when done
- Do not describe the plan in prose and skip the task list — prose plans disappear, tasks are checkable

## Pattern 3: Receipt table at workflow close

End every completed multi-step workflow with a structured receipt table before the final summary sentence:

| Item | Change | Status |
|---|---|---|
| filename.md | What changed | ✅ / ⚠️ |

"Workflow close" = user's request is fully addressed and no further tool calls are planned. A prose summary does not replace the table. Expert users who switched tabs during processing missed all real-time status; the receipt table is the only transparency that reaches them.

**Why:** Source: [[AI Transparency Patterns for Agentic Systems]] — Application to Claude Code Sessions section.

**How to apply:** Pre-tool statement applies to every tool call. Task list and receipt table apply whenever a workflow has more than two steps.
