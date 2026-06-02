---
name: workflow-soccer-box-score
description: "Full MLS soccer box score procedure — sources, content rules, event format, cross-verification, discrepancy handling"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Trigger
"write a box score for [Team A] vs [Team B] on [date]" or "soccer box score [Team A] vs [Team B] [date]"

**Also read:** `domain/soccer_sources.md` for source reliability tiers before starting.

---

## Output & Template
- Output file: `D:\Obsidian\Main\YYYY-MM-DD - {Team A} vs {Team B} Box Score.md` (vault root)
- Template: `D:\Obsidian\Main\05 - Templates\Soccer Template.md`

## Step 1 — Pre-flight: Search Clippings
Grep `D:\Obsidian\Main\10 - Clippings\` for a note matching both team names and/or the match date. If found:
- Read it immediately as the **primary source** for all match facts (score, goals, assists, lineups, substitutions, cards)
- Use web fetches (step 2) only to fill gaps or cross-verify disputed facts
- Note the clipping note filename in the source discrepancy table as the first footnote
- **After the box score is complete, delete the clipping note** from `10 - Clippings\`
- **Preferred clip source: FBref** — provides complete squads with jersey numbers, full event timeline, formations, officials, managers, captains; FBref cannot be fetched via WebFetch (HTTP 403) — must be clipped by user before the session

## Step 2 — Web Sources (fetch in parallel; skip if already confirmed by clipping)
- WebSearch for the match to locate primary sources
- Fetch in parallel:
  - ESPN or MLS match page (goals, score, cards, stats)
  - **Austin FC official post-match report** (`site:austinfc.com match-report`)
  - **MNUFC or opponent official post-match report** (`site:mnufc.com` or `site:{club}.com`)
  - **MLS Match Center** (`mlssoccer.com` match page) — bookings with brief descriptions; primary card reason source
  - **MLS Disciplinary Summary page** (`mlssoccer.com` disciplinary) — red cards and accumulation suspensions
  - FotMob match page — prefer `/match/{id}/matchfacts/` URL for richer incident detail
  - **CBS Sports local affiliate** (e.g., `cbsnews.com/minnesota` for MNUFC home games)
  - **OurSports Central** match report
  - Pre-match lineup article (e.g., Sportsgambler) for starting XI confirmation
  - Official player availability reports (Austin FC publishes these; check both clubs)
  - Vault Austin FC roster note: `D:\Obsidian\Main\20 - Permanent Notes\2026 Austin FC Roster as of 2026-04-18 Status.md` — primary jersey number source
- Reddit MLS match thread: useful for card reasons and substitution confirmation
- **Journalist/fan match reports** — search `"[Team A]" "[Team B]" "[date]"` broadly (Oak Tree Times substack for Austin FC; Waking the Red for Toronto FC; equivalent fan outlets for other opponents) — best source for incident descriptions on notable cards
- **Do not use Sofascore** — documented reversed substitution columns and team misattribution errors

## Step 3 — Content Rules (strictly enforced)
- **Never guess.** It is three times worse to assert an incorrect fact than to write "Unknown"
- Only mark a player Available in roster tables if they appeared in the match; otherwise Unknown (unless official availability report confirms)
- Note source discrepancies inline in plain English in the detail column — do not silently pick one
- Cite sources only at the section level (intro sentence), never inside table cells
- Footnote reference list stays at the bottom; inline [^n] markers go only in section intros

## Step 4 — Key Data to Cross-Verify
- Goal times: FotMob sometimes differs from official match reports — note discrepancy if >2 min
- Goal assists: FotMob vs. club match report often disagree — flag disputed assists
- Substitutions: FotMob is most complete; Reddit match thread confirms many; cross-check both
- Yellow/red cards: ESPN match stats page is authoritative for card totals; FotMob first-half card times run systematically ~7 min earlier than FBref/official match time — record as single pattern note, not per-card entries; flag specific card only if >10 min difference or wrong half
- Jersey numbers: use vault Austin FC roster note as primary; fall back to prior vault box scores in `D:\Obsidian\Main\01\Soccer\`; note fallback explicitly
- **Always verify player team assignments** — FotMob AI extractions sometimes mis-attribute players to wrong team

## Step 5 — Box Score Event Format
- Columns: section | row_type | time | period | team | player | action | detail
- Substitution player format: `+{No} – {Name In} / −{No} – {Name Out}`
- Goal assist format in detail column: `Assisted by {No} – {Name}`
- section values: meta | goal | sub | card | note
- row_type values: kickoff | goal | substitution | caution | dismissal | state
- **YAML frontmatter `source` field**: set to primary stats page URL (ESPN or FotMob — whichever has more complete team stats)
- **Team statistics section**: add after box score table; include Possession, Shots, Shots on Target, Saves, Corner Kicks, Fouls, Offsides, Yellow Cards, Red Cards, Pass Accuracy; cite source with footnote

## Card Reason Priority Order
1. MLS Match Center match page — brief standardized descriptions ("serious foul play," "handball")
2. MLS Disciplinary Summary page — standardized reasons for red cards and accumulation suspensions; only covers cards that triggered suspensions — routine yellows won't appear here
3. FotMob `/matchfacts/` incidents tab — sometimes lists offense type
4. Reddit r/MLS match thread — observer notes often identify reason
5. Club match reports — contextual narrative
6. Journalist/fan match reports — best for red card and VAR incident descriptions
- MLS standard categories: serious foul play, violent conduct, DOGSO, handball, unsporting behavior, dissent, yellow card accumulation
- If no source specifies reason: "Reason not specified in available sources"

## Jersey Number Fallback Rule
If a player's jersey number is not in the current squad page or vault roster note, grep prior vault box scores in `D:\Obsidian\Main\01\Soccer\` for the player name. Use that number and note it as "prior box score fallback — not in current roster file".

## Output
Completed vault file + summary of key source discrepancies found.
