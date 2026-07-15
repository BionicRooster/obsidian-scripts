Write a complete soccer box score (MLS or USMNT/USWNT) and save it as an Obsidian vault note.

## Parameters

`$ARGUMENTS` — specify teams and date in any of these forms:
- `/box-score Austin FC vs Portland 2026-06-01`
- `/box-score Austin FC vs Portland on June 1`
- `/box-score Austin FC vs Portland` (omit date → assume most recent match)
- `/box-score USMNT vs Mexico 2026-03-25`
- `/box-score USWNT vs Canada 2026-04-10`
- `/box-score` with no args → prompt: "Which match? (Team A vs Team B, YYYY-MM-DD)"

Parse from `$ARGUMENTS`:
- **Team A** — first team named (typically home team, or USMNT/USWNT for national team matches)
- **Team B** — team after "vs" or "at"
- **Date** — YYYY-MM-DD if provided; otherwise search for the most recent completed match between the two teams
- **Competition type** — MLS (default) or international (USMNT/USWNT/Gold Cup/World Cup Qualifying/CONCACAF Nations League/Friendly)

---

## Output

- **File:** `C:\Users\awt\Sync\Obsidian\YYYY-MM-DD - {Team A} vs {Team B} Box Score.md`
- **Template:** `C:\Users\awt\Sync\Obsidian\05 - Templates\Soccer Template.md` — read this first and use it as the base structure

---

## Step 1 — Pre-flight: Clippings → FBref Live Scrape

**1a. Check clippings folder first.**
Grep `C:\Users\awt\Sync\Obsidian\10 - Clippings\` for any note matching both team names and/or the match date.

**If a clipping is found:**
- Read it immediately — it is the **primary source** for all match facts (score, goals, assists, lineups, substitutions, cards)
- Use web fetches (Step 2) only to fill gaps or cross-verify disputed facts
- Note the clipping filename as the first footnote in the source table
- **After the box score is complete, delete the clipping note from `10 - Clippings\`**
- Skip to Step 3.

**1b. If no clipping found — attempt FBref live scrape via Firecrawl.**

FBref is the gold-standard source (complete squads with jersey numbers, full event timeline, formations, officials, managers, captains). It blocks plain WebFetch (HTTP 403) but **Firecrawl can fetch it reliably** with `waitFor: 8000`.

Procedure:
1. Search for the FBref match URL: use `firecrawl_search` with query `site:fbref.com "{Team A}" "{Team B}" {Year} match report`
2. From results, find the URL matching the pattern `fbref.com/en/matches/{id}/...`
3. For MLS: the URL ends in `-Major-League-Soccer`; for international: ends in the competition name (e.g., `-CONCACAF-Nations-League`, `-FIFA-World-Cup-Qualifying`, `-Friendlies-Mens`)
4. Scrape with `firecrawl_scrape`: `url={match_url}`, `formats=["markdown"]`, `waitFor=8000`, `onlyMainContent=true`
5. If scrape returns > 200 words of content, treat it as the **primary source** — same authority as a manual clipping. Skip to Step 3.
6. If scrape fails or returns thin content, proceed to Step 2.

---

## Step 2 — Web Sources

Fetch in parallel (skip any already confirmed by clipping or FBref scrape):

### MLS matches

| Source | What it provides |
|---|---|
| ESPN match stats page (`espn.com/soccer/matchstats/_/gameId/{id}`) | Authoritative team stats, card totals, attendance — always fetch the `/matchstats/` URL directly |
| Austin FC official post-match report (`site:austinfc.com match-report`) | Narrative detail on goals, disallowed goals, card context |
| Opponent official post-match report (`site:{club}.com match-report`) | Opponent perspective on same events |
| MLS Match Center (`mlssoccer.com` match page) | Bookings with brief standardized descriptions — **primary card reason source** |
| MLS Disciplinary Summary (`mlssoccer.com` disciplinary) | Red cards and accumulation suspensions; covers only suspension-triggering cards |
| FotMob (`fotmob.com/match/{id}/matchfacts/`) | Substitution times, goal times, card events; prefer `/matchfacts/` URL |
| CBS local affiliate (e.g., `cbsnews.com/minnesota` for MNUFC home games) | Disallowed goal details, card incident context |
| OurSports Central | Reliable MLS match narrative; good fallback for goal/sub confirmation |
| Reddit r/MLS match thread | Card reasons (observer notes), real-time sub confirmation |
| Journalist/fan outlet (Oak Tree Times for Austin FC; Waking the Red for Toronto FC; etc.) | Best for red card and VAR incident descriptions |

**Do NOT use Sofascore** — documented reversed substitution columns and team misattribution errors.

Also read the vault Austin FC roster note as the **primary jersey number source:**
`C:\Users\awt\Sync\Obsidian\20 - Permanent Notes\2026 Austin FC Roster as of 2026-04-18 Status.md`

### USMNT / USWNT matches

Use the same source priority order. Swap MLS-specific sources for these international equivalents:

| Source | What it provides |
|---|---|
| FBref (via Firecrawl — Step 1b above) | Complete lineups with jersey numbers, formations, officials, full event timeline — **primary source** |
| ESPN match stats (`espn.com/soccer/matchstats/_/gameId/{id}`) | Team stats, attendance, card totals |
| US Soccer official match report (`site:ussoccer.com`) | Narrative detail, disallowed goals, official lineup confirmation |
| Opponent federation site | Opponent-side perspective on key events |
| FotMob (`fotmob.com/match/{id}/matchfacts/`) | Event timeline, substitution times, card events — same timing artifacts as MLS |
| Reddit r/soccer or r/ussoccer match thread | Card reasons, VAR incident details, real-time sub confirmation |
| Major sports outlet (Guardian, NYT, Athletic, ESPN) | Red card and VAR incident descriptions; useful for controversial calls |

**Jersey numbers for USMNT/USWNT:** National team squads change per camp — FBref lineup (Step 1b) is the most reliable per-match number source. No standing vault roster note; fall back to prior national team box scores in `C:\Users\awt\Sync\Obsidian\01\Soccer\`.

**Competition tags for YAML frontmatter:** Use the actual competition name — `Gold Cup`, `CONCACAF Nations League`, `FIFA World Cup Qualifying`, `International Friendly` — not just "International".

---

## Step 3 — Content Rules

- **Never guess.** It is three times worse to assert an incorrect fact than to write "Unknown"
- Only mark a player Available in roster tables if they appeared in the match; otherwise Unknown (unless an official availability report confirms)
- Note source discrepancies inline in plain English in the detail column — do not silently pick one
- Cite sources only at the section level (intro sentence), never inside table cells
- Footnote reference list at the bottom; inline `[^n]` markers go only in section intros

---

## Step 4 — Cross-Verification Checklist

| Data point | Rule |
|---|---|
| Goal times | FotMob sometimes differs from official reports — note discrepancy if >2 min |
| Goal assists | FotMob vs. club report often disagree — flag disputed assists |
| Substitutions | FotMob most complete; Reddit match thread confirms many; cross-check both |
| Yellow/red card times | FotMob first-half times run ~7 min earlier than FBref/official (clock vs. match time) — record as a single pattern note, not per-card; flag specific card only if >10 min off or wrong half |
| Jersey numbers | Vault Austin FC roster note is primary; fall back to prior vault box scores in `C:\Users\awt\Sync\Obsidian\01\Soccer\`; note fallback explicitly |
| Player team assignments | FotMob AI extractions sometimes mis-attribute players — verify all against vault history |

---

## Step 5 — Box Score Event Format

**Columns:** `section | row_type | time | period | team | player | action | detail`

| Field | Values |
|---|---|
| section | `meta` `goal` `sub` `card` `note` |
| row_type | `kickoff` `goal` `substitution` `caution` `dismissal` `state` |

**Substitution player format:** `+{No} – {Name In} / −{No} – {Name Out}`

**Goal assist format** (in detail column): `Assisted by {No} – {Name}`

**YAML frontmatter `source` field:** set to the primary stats page URL (ESPN or FotMob — whichever has more complete team stats)

**Team statistics section:** add after box score table; include Possession, Shots, Shots on Target, Saves, Corner Kicks, Fouls, Offsides, Yellow Cards, Red Cards, Pass Accuracy; cite source with footnote

---

## Card Reason Priority Order

Check in this order; stop when a reason is found:

1. **MLS Match Center** (`mlssoccer.com` match page) — standardized descriptions; most authoritative per-match source
2. **MLS Disciplinary Summary** (`mlssoccer.com` disciplinary) — best for red cards and multi-game bans; only covers suspension-triggering cards
3. **FotMob `/matchfacts/`** — occasionally describes offense type
4. **Reddit r/MLS match thread** — observer notes often identify reason
5. **Club match reports** — contextual narrative
6. **Journalist/fan match reports** — best for red card and VAR incident descriptions

If no source specifies the reason: `"Reason not specified in available sources"`

**MLS standard card reason categories:** serious foul play · violent conduct · DOGSO · handball · unsporting behavior · dissent · yellow card accumulation

---

## Jersey Number Fallback Rule

If a player's jersey number is not in the current vault roster note:
1. Grep prior vault box scores in `C:\Users\awt\Sync\Obsidian\01\Soccer\` for the player name
2. Use that number and note it as: `"prior box score fallback — not in current roster file"`

---

## Output

Completed vault file written to `C:\Users\awt\Sync\Obsidian\YYYY-MM-DD - {Team A} vs {Team B} Box Score.md` + a brief summary of key source discrepancies found during research.
