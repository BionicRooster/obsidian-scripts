---
name: project-resolve-unknowns-schedule
description: "User wants to run \"resolve unknowns box scores\" monthly; remind if forgotten"
metadata: 
  node_type: memory
  type: project
  originSessionId: bccc7b11-2750-4e17-9a51-8891aae0db7c
---

Run `resolve unknowns box scores older than 30 days` approximately once a month.

**Why:** Soccer box scores accumulate Unknown entries that can be resolved with fresh web sources; monthly cadence keeps them clean without over-investing in research.

**How to apply:** If more than ~30 days have passed since the last resolve run and the user hasn't mentioned it, remind them: "It's been about a month since the last resolve unknowns run on box scores — want me to run one?"

Last run: 2026-06-02
