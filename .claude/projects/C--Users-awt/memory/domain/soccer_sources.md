---
name: Soccer Box Score Source Reliability
description: Ranked reliability of sources used in MLS soccer box score workflow — updated from session experience
type: project
originSessionId: 2ab961bf-8cc0-491f-9e0f-1160a57b22df
---
## Source Reliability Tiers

Update this file whenever a source proves more or less reliable than documented here.

---

### Tier 1 — Primary (use first, most complete)

**FBref** — manual clipping OR Firecrawl live scrape
- Provides: complete squads (starters + bench) with jersey numbers, full event timeline (goals, subs, cards), formations, officials, managers, captains — all in one note
- **Firecrawl works reliably** with `waitFor: 8000, formats: ["markdown"], onlyMainContent: true` — confirmed 2026-06-08
- Plain WebFetch still returns HTTP 403; use Firecrawl only
- Manual clipping path: `10 - Clippings/` (check first; if present, use clipping and skip live scrape)
- Live scrape: search `site:fbref.com "{Team A}" "{Team B}" {Year} match report` to find the match URL, then scrape
- **Preferred primary source for all MLS and international matches**

**ESPN match stats page** (`espn.com/soccer/matchstats/_/gameId/{id}`)
- Provides: authoritative team statistics (possession, shots, saves, fouls, card totals, corners), attendance, final score
- Important: always fetch the `/matchstats/` URL directly — search snippet stats have been observed to differ from the actual stats page
- Does not provide: offsides, pass accuracy

**Club official match reports** (`austinfc.com`, `mnufc.com`, etc.)
- Provides: narrative detail on goals, disallowed goals, card context
- Austin FC URL pattern varies; search `site:austinfc.com match-report` to locate

---

### Tier 2 — Cross-verification

**FotMob** (`fotmob.com/match/{id}/matchfacts/`)
- Provides: substitution times, goal times, card events; sometimes card reasons in incident descriptions
- Prefer the `/match/{id}/matchfacts/` URL over the general match URL for richer data
- **Known timing artifact**: first-half card times run systematically ~7 minutes earlier than FBref/official match time (clock time vs. match time difference). Record as a single pattern note — do not create individual discrepancy entries per card. Flag only if a specific card differs by >10 min or is placed in the wrong half.
- Caution: AI-extracted player attributions have misassigned team; verify all player/team assignments against vault box score history

**CBS local affiliate** (`cbsnews.com/minnesota` for MNUFC home games)
- Provides: disallowed goal details, card incident context; useful when Austin FC report is unavailable

**OurSports Central** (`oursportscentral.com`)
- Provides: reliable MLS match narrative; good fallback for goal and sub confirmation

**Reddit r/MLS match thread**
- Provides: card reasons (observer notes), real-time substitution confirmation
- Accessibility varies; worth attempting for cards

---

### Tier 3 — Do Not Use

**Sofascore**
- Documented errors: reversed substitution In/Out columns (players labeled as entering were actually leaving), team misattribution (Austin FC players listed under Minnesota United)
- All reliable data it could provide is covered by FBref clipping + ESPN + FotMob
- **Do not fetch Sofascore for any MLS box score**

**FBref via plain WebFetch (no Firecrawl)**
- Returns HTTP 403 on every attempt; not usable programmatically via WebFetch
- Use Firecrawl instead (see Tier 1 above) — confirmed working 2026-06-08

**FBref via Playwright MCP**
- Also blocked: Cloudflare "Just a moment..." challenge, HTTP 403, does not clear even after a 6s wait — confirmed 2026-07-14
- FBref blocks browser automation generally, not just plain WebFetch — Firecrawl remains the only working method for this domain (see Tier 1)

---

## Card Reason Sources — Priority Order

Check in this order; stop when a reason is found:

1. **MLS Match Center** (`mlssoccer.com` match page) — lists bookings with brief standardized descriptions; most authoritative per-match source for card reasons
2. **MLS Disciplinary Summary page** (`mlssoccer.com` disciplinary section) — aggregates suspensions with standardized reasons ("Red Card – Serious Foul Play", "Yellow Card Accumulation"); best for red cards and multi-game bans; **only covers cards that triggered suspensions** — routine yellow cards that don't cross the accumulation threshold will never appear here
3. **FotMob `/matchfacts/`** — occasionally describes offense type ("foul", "unsporting behavior")
4. **Reddit r/MLS match thread** — observer notes often identify the reason in real time
5. **Club match reports** — contextual narrative sometimes mentions cards

If none specify the reason, write: "Reason not specified in available sources"

## MLS Standard Card Reason Categories

Defined in MLS Competition Guidelines and Send-Off Review Procedure:
- **Serious foul play** — reckless or excessive force tackle
- **Violent conduct** — deliberate act of aggression not in play
- **DOGSO** — denial of obvious goal-scoring opportunity (results in red card)
- **Handball** — deliberate handball
- **Unsporting behavior** — simulation, time-wasting, encroachment, etc.
- **Dissent** — verbal or gestural dissent toward officials
- **Yellow card accumulation** — suspension trigger after threshold (typically 5 yellows in MLS)

Use these standardized terms when recording card reasons.
