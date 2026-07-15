Improve the Claude Code system (memory, skills, or captured knowledge) using one of five modes. Pick the mode from context clues in the user's message; ask if unclear.

## Mode Detection

Infer the mode before starting:

| Signal words / context | Mode |
|---|---|
| "stale", "duplicate", "conflict", "out of date", "audit memory" | **Audit** |
| "improve this skill", "update the skill", "we discussed", references a named skill | **Skill Review** |
| "I learned", "we figured out", "that worked", "capture this", "remember", shares a story or win | **Experience** |
| "mine sessions", "missed learnings", "what did we miss", "historical", "past sessions" | **Historical Review** |
| "foundation", "brand", "audience", "offers", "who I serve", "missing context about me" | **Foundation** |

If no mode is clear from context, present the five options and ask the user to choose.

---

## Mode 1 — Audit

**Goal:** Find stale, conflicting, or duplicate entries across memory files and skill files.

### Step 1 — Load all memory indexes

Read both indexes:
- `C:\Users\awt\.claude\memory\memory.md` (global)
- `C:\Users\awt\.claude\projects\C--Users-awt\memory\MEMORY.md` (project)

List every linked file. Then read each file in turn.

### Step 2 — Staleness scan

Flag any memory entry that:
- References a file path that no longer exists (verify with Glob or Read)
- References a function, flag, or script name that no longer exists (verify with Grep)
- Mentions a date-bounded fact that may have changed (version numbers, model IDs, session dates, counts)
- Says "current" or "latest" without a date anchor

### Step 3 — Conflict scan

Compare all memory files. Flag pairs where:
- Two files make contradictory claims about the same fact
- A project-layer memory duplicates a global-layer memory (Cross-Memory Sync Rule violation)
- A CLAUDE.md stub describes behavior that contradicts the linked skill file

### Step 4 — Duplicate scan

Identify:
- Entries in MEMORY.md or memory.md whose descriptions are substantially identical
- Skill files that implement the same sub-task (composability overlap)
- People Index entries that appear twice under different name formats

### Step 5 — Report

Produce a findings table:

| File | Line / Entry | Issue type | Finding | Recommended action |
|---|---|---|---|---|
| path/to/file.md | entry-slug | Stale / Conflict / Duplicate | What was found | What to change |

Do NOT apply any fixes automatically. Present the table and ask the user which findings to act on.

---

## Mode 2 — Skill Review

**Goal:** Improve a named skill file based on patterns observed in recent back-and-forth.

### Step 1 — Identify the skill

If the user named a skill, read `C:\Users\awt\.claude\commands\<skill-name>.md`.
If not named, ask: "Which skill should I review?"

### Step 2 — Review recent context

Scan the current conversation (and any compacted summary) for:
- Corrections the user made while the skill was running ("no, not that", "stop doing X")
- Confirmations of non-obvious choices ("yes exactly", "keep doing that")
- Steps that had to be retried, re-explained, or debugged
- Edge cases that the skill's instructions did not cover

### Step 3 — Review existing memory for skill feedback

Grep `C:\Users\awt\.claude\projects\C--Users-awt\memory\` for the skill name to find any feedback entries already saved about it.

### Step 4 — Draft improvements

For each finding, propose a specific edit to the skill file:
- Imprecise step → tighten the instruction
- Missing edge case → add a rule or exception block
- Redundant step → remove it
- Confirmed working pattern → reinforce with explicit language

### Step 5 — Apply

Present each proposed change as a before/after diff. Apply only on user approval.

After applying, check whether any finding should also be saved as a `feedback_*.md` memory entry for future sessions.

---

## Mode 3 — Experience

**Goal:** Capture a story, win, or lesson the user just shared and persist it in the right place.

### Step 1 — Extract the insight

From the user's message, identify:
- **What happened** (the event or outcome)
- **Why it matters** (the non-obvious constraint, decision, or principle it reveals)
- **Where it applies** (which future tasks or decisions this should inform)

### Step 2 — Classify the memory type

| Insight type | Memory type | Destination |
|---|---|---|
| How to approach a task, what to avoid | `feedback` | `memory/feedback_<topic>.md` |
| Ongoing project context, deadline, decision | `project` | `memory/domain/<project>.md` |
| Personal preference, role, expertise level | `user` | `memory/user_*.md` |
| Where information lives externally | `reference` | `memory/reference_*.md` |
| Substantial synthesis (5+ facts, complex topic) | synthesis page | `C:\Users\awt\Sync\Obsidian\30 - Synthesis\<Topic>.md` |

### Step 3 — Check for an existing file to update

Before creating a new file, check whether an existing memory file already covers this topic. If so, update it with a new entry rather than creating a duplicate.

### Step 4 — Write

Write the memory file using the standard frontmatter format:

```markdown
---
name: short-kebab-slug
description: one-line summary used for relevance matching
metadata:
  type: feedback | project | user | reference
---

Lead with the rule or fact.

**Why:** The reason the user gave.

**How to apply:** When and where this guidance kicks in.
```

Then add a pointer line in the correct index (`MEMORY.md` or `memory.md`).

If the experience belongs in the vault as a synthesis update, also update `C:\Users\awt\Sync\Obsidian\30 - Synthesis\index.md`.

---

## Mode 4 — Historical Review

**Goal:** Mine recent Claude Code sessions for corrections, patterns, and wins that were never captured in memory.

### Step 1 — Locate session files

Sessions are stored as `.jsonl` files at:
`C:\Users\awt\.claude\projects\C--Users-awt\`

List all `.jsonl` files sorted by modification time (most recent first). Focus on the 5 most recent unless the user specifies otherwise.

### Step 2 — Extract signal

For each session file, read the content and scan for:

**Corrections** (high value — should become feedback memories):
- User said "no", "don't", "stop", "wrong", "not that"
- User had to re-explain something more than once
- A tool call was denied or retried

**Confirmations** (medium value — validate a non-obvious approach):
- User said "yes", "exactly", "perfect", "keep doing that"
- An unusual choice was accepted without pushback

**Unresolved issues** (medium value — may need follow-up):
- User said "we'll come back to this", "TODO", "for later"
- A task was abandoned mid-stream without a logged reason

**Patterns** (low value individually, high value in aggregate):
- The same type of error appeared in 2+ sessions
- A skill had to be re-explained in 2+ sessions

### Step 3 — Deduplicate against existing memory

For each finding, check whether it is already captured in a memory file. Skip findings that are already documented.

### Step 4 — Report

Produce a summary table:

| Session (date) | Finding type | Summary | Already in memory? | Recommended action |
|---|---|---|---|---|

Offer to apply captures from this table using **Mode 3 — Experience** for each approved finding.

---

## Mode 5 — Foundation

**Goal:** Identify and fill gaps in foundational memory — who Wayne is, who he serves, and what he creates.

### Step 1 — Read current foundation

Read these memory files (skip if they don't exist yet):
- `C:\Users\awt\.claude\memory\user_identity.md`
- `C:\Users\awt\.claude\projects\C--Users-awt\memory\user_intellectual_interests.md`
- Any other `user_*.md` files in either memory layer

### Step 2 — Audit for gaps

Check whether each of these foundational areas is covered:

| Area | What to look for |
|---|---|
| **Identity** | Full name, email, location, household |
| **Roles** | Professional roles, community roles, organizational memberships |
| **Expertise** | Domains where Wayne has deep knowledge |
| **Interests** | Active intellectual, creative, or research pursuits |
| **Projects** | Ongoing long-term projects (vault, GCCMA, EWT research, etc.) |
| **Values** | Core commitments that should shape AI collaboration |
| **Audience** | Who benefits from Wayne's work (community, students, researchers) |
| **Offers / outputs** | What Wayne produces (vault, syntheses, box scores, community docs) |

### Step 3 — Ask targeted questions

For each gap, ask one specific question at a time. Do not present a long form. Examples:
- "Your roles section doesn't mention GCCMA. How would you describe your role there?"
- "I don't have a record of your NLP practice or coaching work. Is that still active?"

### Step 4 — Write

After each answer, immediately write or update the relevant memory file. Use the standard frontmatter format. Update the index.

Do not wait until all questions are answered — capture each answer as it arrives so nothing is lost if the session ends early.
