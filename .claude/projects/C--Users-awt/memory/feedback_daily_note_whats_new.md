---
name: feedback-daily-note-whats-new
description: "Daily note 'What's New' dataview query uses dur(2 days), not dur(10 days)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e9ce0d0e-af63-46d5-ad6f-1f047e237e67
---

The `## 🆕 What's New` dataview query in daily notes uses `dur(2 days)`, not `dur(10 days)`.

**Why:** The 10-day window was too broad; Wayne prefers to see only files added in the last 2 days.

**How to apply:** When creating a daily note from the template (or writing a new briefing), always set `WHERE file.ctime >= date(YYYY-MM-DD) - dur(2 days)`. The template has been updated to match — if it ever reverts to 10, fix it.
