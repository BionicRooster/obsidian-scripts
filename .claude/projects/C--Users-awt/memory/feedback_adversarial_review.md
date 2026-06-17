---
name: feedback-adversarial-review
description: "Adversarial-review pattern confirmed effective: spawn a critic, but independently verify disputed claims before applying any correction"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f02a90cc-9d15-4338-82e5-a52ced02233a
---

When validating a scholarly/technical vault note, spawning an adversarial critic subagent and then independently verifying each flagged item before editing — rather than applying every suggested correction — produces a real quality improvement and catches the critic's own errors.

**Why:** Used on [[Chomsky 1970 - Extended Standard Theory (Foundational Papers)]]. The critic flagged a quantifier-scope claim as "backwards" with high stated confidence; independent re-derivation showed the original text was already correct, so it was left unchanged. Wayne confirmed the overall approach improved the note ("the validation you just did seems to have improved the quality of the output") and approved formalizing it as a skill.

**How to apply:** Use the `/adversarial-review` skill (`~/.claude/commands/adversarial-review.md`) for scholarly/technical notes with verifiable factual content. Triage every flagged item into accept / verify-then-accept / reject before touching the file. Never apply a correction solely because the critic reported high confidence — confidence is a self-report, not evidence. Report the full triage back, including rejections and why.
