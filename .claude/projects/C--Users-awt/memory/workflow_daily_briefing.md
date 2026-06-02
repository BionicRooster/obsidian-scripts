---
name: workflow-daily-briefing
description: "Daily journal briefing procedure — calendar, markets (CALM/KQQQ), Austin FC + USMNT/USWNT, Bahá'í Badí date and news"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Trigger
"daily journal", "briefing", "update today's note", "morning briefing", or asks to populate today's daily note.

**Do NOT log this workflow to the Claude Action Log** — it is recurring housekeeping, not an ingest or synthesis operation.

---

## Step 1 — Target File
- Target: `D:\Obsidian\Main\YYYY-MM-DD.md` (today's date)
- If the file doesn't exist, create it from `D:\Obsidian\Main\05 - Templates\Daily Notes Template.md`
- Always read the live file first to confirm the current state of `## Claude Briefing`
- Replace only the content between `## Claude Briefing` and the next `##` sibling heading — never overwrite `## 🆕 What's New`, `## My Notes`, `## 🗂️ Quick Links`, or `## Related Notes`

## Step 2 — Gather Data in Parallel (all four simultaneously)
- **Calendar:** Use `mcp__claude_ai_Google_Calendar__list_calendars` then `mcp__claude_ai_Google_Calendar__list_events` for today across all calendars. Calendars include: waynetalbot@gmail.com (personal), Bahá'í Badí Calendar – All Days, LSA of Georgetown, Friends of the Georgetown Public Library, Georgetown Bahá'í Community, jmt@2tsquared.com (Jo)
- **Markets:** WebSearch for "S&P 500 Dow Nasdaq close [yesterday's date]" for prior trading day. Also check CALM (Cal-Maine Foods) and KQQQ (Kurv Technology Titans Select ETF) closing prices. Calculate vs. cost bases: CALM basis = $93.87; KQQQ basis = $27.54. Check upcoming ex-dividend dates and pay dates for both.
- **Soccer:** WebSearch for Austin FC last result + next match; USMNT and USWNT current news. Note MLS schedule windows (international breaks, FIFA windows).
- **Bahá'í:** Calculate today's Badí date (Bahá'í calendar). Check for any upcoming Holy Days within 24–48 hours — Holy Days begin at sunset, so note the approximate time. WebSearch for recent Bahá'í community news if any notable items.

## Step 3 — Briefing Format (exact format required)

```markdown
*Generated [Weekday], [Month DD, YYYY] at [Time] CT*

### 📅 Today's Schedule
- 🌟 **All day** — [Bahá'í Badí date: D Month NNN B.E.] *(Bahá'í Badí Calendar – All Days)*
- **H:MM AM/PM – H:MM AM/PM** — [Event title] *([Calendar name])*

[If a Holy Day begins tonight]: ⚠️ **Tonight (~[time] after sunset):** [Holy Day name] begins — a Bahá'í Holy Day on which work is suspended.

[If no other events]: No LSA, FOL, or Georgetown Bahá'í Community events on the calendar today.

---

### 📈 Markets — Close, [Weekday, Month DD, YYYY]
- **S&P 500**: [price] ([±%])
- **Dow Jones**: [price] ([±%])
- **Nasdaq**: [price] ([±%])
- **CALM**: $[price] as of [date] ([±$] / [±%] vs. $93.87 basis) | Ex-div: [date] · Pay: [date] ([$amount])
- **KQQQ**: $[price] as of [date] ([±$] / [±%] vs. $27.54 basis) | Ex-div: [date] · Pay: [date] ([$amount per month])

[1–2 sentence market narrative.]

---

### ⚽ Soccer

**Austin FC** *(all competitions)*
- [Recent result or upcoming match with date, time CT, opponent, competition, broadcast]
- [Form notes, standings context]
- [Any schedule pauses — MLS international windows, FIFA World Cup break, etc.]

**USMNT**
- [Current roster/tournament news, upcoming matches, injury watch]

**USWNT**
- [Upcoming friendlies, roster/injury news, tournament schedule]

---

### ☀️ Bahá'í News
[Paragraph: today's Badí date, any Holy Day context, recent global/US community news from May–present.]
```

## Step 4 — Write the Briefing
Use `mcp__mcp-obsidian__obsidian_patch_content` to replace the `## Claude Briefing` section content. Use heading mode targeting `Claude Briefing`.

## Key Data Constants (update when these change)
- CALM cost basis: $93.87
- KQQQ cost basis: $27.54
- Austin FC vault roster: `D:\Obsidian\Main\20 - Permanent Notes\2026 Austin FC Roster as of 2026-04-18 Status.md`

## Research Rules
- Never assert a match result that hasn't been confirmed — write "result not yet confirmed at time of briefing" if the match is in progress or just concluded
- CALM/KQQQ: note the exact date of the last confirmed close if it's not the most recent trading day
- Market data: use prior trading day's close (markets are closed weekends and US holidays)
