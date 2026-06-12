---
name: feedback-corrections-log
description: "Standing rule — log all user-confirmed corrections to C:\\Users\\awt\\corrections.md with date, what I wrote, what user changed it to, and category"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 981ceb4f-cfec-4ba4-8eb3-ef1c3837eca0
---

When the user corrects my output and confirms they're happy with the new version, log it in `C:\Users\awt\corrections.md`.

**Why:** User wants a running record of correction patterns to surface systematic errors over time.

**How to apply:**
1. After the user says "happy with" / "that's right" / confirms a correction, append a row to the table in `corrections.md`.
2. Record four fields: today's date | what I wrote | what they changed it to | category (see below).
3. If a nearly identical correction already exists in the table, add a tick mark ✓ to that row instead of inserting a new row.
4. Create the file if it doesn't exist (table header is in the file at `C:\Users\awt\corrections.md`).

**Categories:**
- **Real miss** — answer was in my source but I didn't use it; or I hallucinated a detail
- **Preference** — my version was factually correct; user just wanted different phrasing
- **Carryover** — wrong detail came from a past task, memory, or file — not today's source
- **Variation** — my output was right given what I had; correction came from new info I never saw
