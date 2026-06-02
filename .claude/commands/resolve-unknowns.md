Search vault notes for Unknown fields and attempt to resolve them using vault-internal and web sources.

## Parameters

`$ARGUMENTS` — all optional; combine freely:
- `/resolve-unknowns` — all scopes, web permitted, no age filter
- `/resolve-unknowns older than 30 days` — only files last modified >30 days ago
- `/resolve-unknowns box scores older than 30 days` — box scores only, >30 days (monthly scheduled run)
- `/resolve-unknowns ewt vault only` — EWT project, no web fetches
- `/resolve-unknowns synthesis` — synthesis pages only, web permitted
- `/resolve-unknowns box scores ewt` — multiple scopes

**Scope values:** `box scores` · `ewt` · `people index` · `synthesis` · `all` (default)

**Source values:** `web` (default, permits WebSearch/WebFetch) · `vault only` (no web fetches)

**Age filter:** `older than N days` — skip files with `LastWriteTime` within N days

---

## Step 1 — Locate Unknown Entries

Scan by scope + age filter:

| Scope | Path | Grep terms |
|---|---|---|
| Box scores | `D:\Obsidian\Main\01\Soccer\` | `Unknown` |
| EWT project | `D:\Obsidian\Main\02 - Working Projects\Elias White Talbot - Project\` | `Unknown`, `not confirmed`, `unclear`, `unverified` |
| People Index | `D:\Obsidian\Main\People Index.md` | entries with no linked notes or explicit Unknown annotations |
| Synthesis | `D:\Obsidian\Main\30 - Synthesis\` | `Unknown`, `not yet synthesized`, `open question`, `not addressed` |

Apply age filter: `(Get-Item $file).LastWriteTime` — skip files newer than the threshold.

Collect: file name + specific Unknown fields (jersey numbers, card reasons, assist credits, dates, roles).

---

## Step 2 — Triage

For each Unknown entry, determine what source could resolve it:

| Unknown type | Sources to check |
|---|---|
| Jersey numbers | MLS squad pages · updated vault roster note (`20 - Permanent Notes\2026 Austin FC Roster...`) · prior vault box scores |
| Card reasons | MLS Match Center · FotMob `/matchfacts/` · Reddit r/MLS match thread |
| Goal assists | Club match reports · FotMob · OurSports Central |
| EWT dates/records | Find a Grave · Ancestry · Yale catalog · newspaper archives |
| People Index roles | Vault notes ingested since the entry was created |
| Synthesis gaps | Vault notes ingested since the synthesis page was last updated |

---

## Step 3 — Resolve

1. Check vault-internal sources first: grep box scores, People Index, synthesis pages for the same entity
2. If `web` permitted and vault insufficient, fetch the appropriate external source
3. Apply the **3× rule without exception**: the source must *confirm* the fact across 3 independent references, not merely suggest it
4. If best evidence remains inferential: entry stays Unknown; note as `"re-checked [YYYY-MM-DD] — still unconfirmed"`

Document the resolution source inline, e.g.: `"confirmed via MLS squad page 2026-05-24"`

---

## Step 4 — Update Files

| Scope | Update method |
|---|---|
| Box scores | Update table cell; add footnote if source differs from original match-day sources; note that confirmation came after original write |
| EWT wiki | Update field and note evidence source |
| People Index | Add confirmed detail as a note on the entry line |
| Synthesis | Update claim; increment `source_count` in frontmatter only if a genuinely new source was consulted |

---

## Step 5 — Report

Summary table — separate resolved from "still Unknown":

| File | Field | Was | Now | Source |
|---|---|---|---|---|
| 2026-03-01 Austin FC vs DC United | Bell, Jon — jersey | Unknown | #13 | MLS squad page |
| EWT wiki-index | Death date of Elias Sr. | Unknown | re-checked 2026-05-24 — still unconfirmed | Find a Grave |

Both resolved and "re-checked still Unknown" are valid outcomes — document both.

---

## Step 6 — Log

Append to `D:\Obsidian\Main\01\PKM\Claude Action Log.md` with `[RESOLVE]` prefix:

```
[RESOLVE] 2026-03-01 Austin FC box score — 2 jersey numbers confirmed; 1 still unknown after web check
```

---

## Key Rules

- The 3× standard applies to resolutions exactly as to original entries — do not loosen it
- "Re-checked and still Unknown" is a valid and useful outcome; recording the date prevents redundant re-checks
- Do not update synthesis `source_count` unless a genuinely new source was consulted
- Box score footnotes for post-match resolutions must note that confirmation came after the original match-day write
- **Do not use Sofascore** — documented reversed substitution columns and team misattribution errors
