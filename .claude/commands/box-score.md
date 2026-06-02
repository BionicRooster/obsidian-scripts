Write a complete MLS soccer box score and save it as an Obsidian vault note.

## Parameters

`$ARGUMENTS` — specify teams and date in any of these forms:
- `/box-score Austin FC vs Portland 2026-06-01`
- `/box-score Austin FC vs Portland on June 1`
- `/box-score Austin FC vs Portland` (omit date → assume most recent match)
- `/box-score` with no args → prompt: "Which match? (Team A vs Team B, YYYY-MM-DD)"

Parse from `$ARGUMENTS`:
- **Team A** — first team named (typically home team for Austin FC matches, but use order as given)
- **Team B** — team after "vs" or "at"
- **Date** — YYYY-MM-DD if provided; otherwise search for the most recent completed match between the two teams

---

## Output

- **File:** `D:\Obsidian\Main\YYYY-MM-DD - {Team A} vs {Team B} Box Score.md`
- **Template:** `D:\Obsidian\Main\05 - Templates\Soccer Template.md` — read this first and use it as the base structure

---

## Step 1 — Pre-flight: Search Clippings

Grep `D:\Obsidian\Main\10 - Clippings\` for any note matching both team names and/or the match date.

**If a clipping is found:**
- Read it immediately — it is the **primary source** for all match facts (score, goals, assists, lineups, substitutions, cards)
- Use web fetches (Step 2) only to fill gaps or cross-verify disputed facts
- Note the clipping filename as the first footnote in the source table
- **After the box score is complete, delete the clipping note from `10 - Clippings\`**
- Preferred clip source: **FBref** — provides complete squads with jersey numbers, full event timeline, formations, officials, managers, captains; FBref cannot be fetched via WebFetch (HTTP 403) — user must clip it before the session

---

## Step 2 — Web Sources

Fetch in parallel (skip any already confirmed by clipping):

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
`D:\Obsidian\Main\20 - Permanent Notes\2026 Austin FC Roster as of 2026-04-18 Status.md`

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
| Jersey numbers | Vault Austin FC roster note is primary; fall back to prior vault box scores in `D:\Obsidian\Main\01\Soccer\`; note fallback explicitly |
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
1. Grep prior vault box scores in `D:\Obsidian\Main\01\Soccer\` for the player name
2. Use that number and note it as: `"prior box score fallback — not in current roster file"`

---

## Output

Completed vault file written to `D:\Obsidian\Main\YYYY-MM-DD - {Team A} vs {Team B} Box Score.md` + a brief summary of key source discrepancies found during research.
