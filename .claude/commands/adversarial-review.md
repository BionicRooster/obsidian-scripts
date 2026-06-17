Stress-test a scholarly or technical vault note by spawning an adversarial critic, independently verifying disputed claims before touching the file, then applying only the corrections that survive verification.

## Parameters

`[file]` — path to the note to review. If omitted, ask which file.

## When to use

Notes with verifiable factual/technical content: scholarly summaries, historical claims, technical/scientific explanations, citations. Not for recipes, journal entries, or trip logs — there's no factual risk worth the cost.

---

## Step 1 — Spawn the critic

Use the Agent tool (general-purpose), passing the file path and this prompt:

> Review `[file]` adversarially. You are trying to find what's wrong with it, not to validate it. Check each of:
> - Factual errors — claims that are simply false
> - Misattribution — ideas credited to the wrong person or wrong date
> - Oversimplification — true claims stated as more settled/complete than they were
> - Missing nuance — a real complication the note glosses over
> - Characterization/framing errors — loaded words that bias the reader, where neutral framing is more accurate
> - Chronological errors — claims about what came before/after what
> - Genuinely good aspects — what's accurate and well-framed, so corrections don't overcorrect it
>
> For each issue: quote the exact passage, state the problem, state what you believe the correction should be, and rate your confidence (high/medium/low). Report everything — do not pre-filter to "the important ones."

Request the full list back, not a summary.

---

## Step 2 — Triage before editing

Walk the critic's list and bucket each item. Do this before opening the file for edits:

- **Accept as-is** — clearly correct, no judgment call needed.
- **Accept but verify first** — anything involving logic, math, scope/quantifier relations, dates, or a named citation. Re-derive or check the claim independently. Confidence reported by the critic is its self-report, not evidence — a "high confidence" flag can still be wrong.
- **Reject** — note the one-line reason so the decision is auditable later.

---

## Step 3 — Apply accepted corrections

Edit section by section. Read enough surrounding text in each section to edit accurately rather than pattern-matching an isolated snippet pulled from the critique.

---

## Step 4 — Report

Give the user the full triage, not just a diff summary:
- What was flagged
- What was applied, with the substance of the change (not "fixed citation" — what changed and why)
- What was rejected and why
- Any rejection itself worth flagging as uncertain, so the user can weigh in

Do not log to Claude Action Log unless the note itself is being newly classified/moved as part of the same session.
