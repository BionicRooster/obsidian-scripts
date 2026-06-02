---
name: workflow-resolve-unknowns
description: "Resolve Unknowns workflow — parameters (age filter, scope, sources), 6-step procedure, 3× rule, re-check convention"
metadata:
  node_type: memory
  type: reference
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Trigger
"resolve unknowns", "check unknowns", or "update unknowns [parameters]"

---

## Parameters (all optional — defaults apply if omitted)
- **Age filter**: `older than N days` — only examine Unknown entries in files last modified more than N days ago (default: no age filter)
- **Scope**: one or more of `box scores`, `ewt`, `people index`, `synthesis`, `all` (default: `all`)
- **Sources**: `vault only` — skip web fetches; `web` — permit WebSearch/WebFetch (default: `web`)

Examples:
- `resolve unknowns older than 20 days` — all scopes, web, files >20 days old
- `resolve unknowns box scores older than 30 days` — box scores only, web, >30 days
- `check unknowns ewt vault only` — EWT project, vault only, no age filter
- `resolve unknowns synthesis` — synthesis pages, web, no age filter

---

## Step 1 — Locate Unknown entries (by scope + age filter)
- **Box scores** (`01\Soccer\`): grep for `Unknown`; collect file names + specific Unknown fields (jersey numbers, card reasons, assist credits)
- **EWT project** (`02 - Working Projects\Elias White Talbot - Project\`): grep for `Unknown`, `not confirmed`, `unclear`, `unverified`
- **People Index** (`People Index.md`): grep for entries with no linked notes or explicit "Unknown" role/date annotations
- **Synthesis pages** (`30 - Synthesis\`): grep for `Unknown`, `not yet synthesized`, `open question`, `not addressed`
- Apply age filter: use `(Get-Item $file).LastWriteTime` to skip files newer than threshold

## Step 2 — Triage
For each Unknown entry, determine what source could resolve it:
- Jersey numbers → MLS squad pages, updated vault roster note, prior box scores
- Card reasons → MLS Match Center, FotMob, Reddit match thread
- EWT dates/records → Find a Grave, Ancestry, Yale catalog, newspaper archives
- People Index roles → vault notes ingested since the entry was created
- Synthesis gaps → vault notes ingested since the synthesis page was last updated

## Step 3 — Resolve
- Check vault-internal sources first (grep box scores, People Index, synthesis pages for same entity)
- If `web` permitted and vault insufficient, fetch the appropriate external source
- Apply the **3× rule without exception**: source must *confirm* the fact, not merely suggest it
- If best evidence is still inferential: entry stays Unknown, noted as "re-checked [date] — still unconfirmed"
- Document resolution source inline (e.g., "confirmed via MLS squad page 2026-05-24")

## Step 4 — Update files
- Box scores: update table cell; add footnote if source differs from original match-day sources
- EWT wiki: update field and note evidence source
- People Index: add confirmed detail as note on the entry line
- Synthesis: update claim and increment `source_count` if a new source was used

## Step 5 — Report (summary table)

| File | Field | Was | Now | Source |
|------|-------|-----|-----|--------|
| 2026-03-01 Austin FC vs DC United | Bell, Jon — jersey | Unknown | #13 | MLS squad page |
| EWT wiki-index | Death date of Elias Sr. | Unknown | confirmed still Unknown | Find a Grave re-checked 2026-05-24 |

Separate resolved from "re-checked and still Unknown" — both are useful outcomes.

## Step 6 — Log
Log to Claude Action Log with prefix `[RESOLVE]`:
- `[RESOLVE] 2026-03-01 Austin FC box score — 2 jersey numbers confirmed; 1 still unknown after web check`

---

## Key Rules
- 3× standard applies to resolutions exactly as to original entries — do not loosen it
- "Re-checked and still Unknown" is a valid outcome; note the date so future passes know it was examined
- Do not update synthesis `source_count` unless a genuinely new source was consulted
- Box score footnotes for post-match resolutions must note that confirmation came after the original match-day write
