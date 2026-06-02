Populate today's Obsidian daily journal with a structured morning briefing covering calendar, markets, soccer, and Bahá'í news.

## Parameters

No arguments required. Always runs for today's date.

---

## Step 1 — Target File

- Target: `D:\Obsidian\Main\YYYY-MM-DD.md` using today's date
- If the file does not exist, create it from the template at `D:\Obsidian\Main\05 - Templates\Daily Notes Template.md`
- Read the live file first to confirm the current state of the `## Claude Briefing` section
- Replace **only** the content between `## Claude Briefing` and the next `##` sibling heading
- Never overwrite: `## 🆕 What's New`, `## My Notes`, `## 🗂️ Quick Links`, or `## Related Notes`

---

## Step 2 — Gather Data in Parallel

Launch all four simultaneously:

### Calendar
- Call `mcp__claude_ai_Google_Calendar__list_calendars` to get all calendar IDs
- Call `mcp__claude_ai_Google_Calendar__list_events` for today across all calendars
- Calendars to include: waynetalbot@gmail.com (personal), Bahá'í Badí Calendar – All Days, LSA of Georgetown, Friends of the Georgetown Public Library, Georgetown Bahá'í Community, jmt@2tsquared.com (Jo)

### Markets
- WebSearch: "S&P 500 Dow Nasdaq close [yesterday's date]" for prior trading day close
- Also check CALM (Cal-Maine Foods) and KQQQ (Kurv Technology Titans Select ETF) closing prices
- Calculate vs cost bases: **CALM basis = $93.87** | **KQQQ basis = $27.54**
- Check upcoming ex-dividend and pay dates for both holdings
- Use prior trading day's close (markets are closed weekends and US holidays); note the date explicitly if it is not the most recent calendar day

### Soccer
- WebSearch: Austin FC last result + next match
- WebSearch: USMNT and USWNT current news
- Note any MLS schedule pauses (international breaks, FIFA windows)

### Bahá'í
- Calculate today's Badí date (Bahá'í calendar)
- Check for upcoming Holy Days within 24–48 hours — Holy Days begin at sunset, note approximate time
- WebSearch: recent Bahá'í community news if notable items exist

---

## Step 3 — Write the Briefing

Use **exactly** this format. Do not add or remove sections.

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
[Paragraph: today's Badí date, any Holy Day context, recent global/US community news.]
```

---

## Step 4 — Write to Vault

Use `mcp__mcp-obsidian__obsidian_patch_content` targeting the `Claude Briefing` heading to replace the section content. Do not use append mode — replace.

---

## Research Rules

- Never assert a match result that has not been confirmed — write "result not yet confirmed at time of briefing" if the match is in progress or just concluded
- CALM/KQQQ: note the exact date of the last confirmed close if it is not the most recent trading day
- Do NOT log this workflow to the Claude Action Log — it is recurring housekeeping, not an ingest or synthesis operation

---

## Key Data Constants

| Item | Value |
|---|---|
| CALM cost basis | $93.87 |
| KQQQ cost basis | $27.54 |
| Austin FC vault roster | `D:\Obsidian\Main\20 - Permanent Notes\2026 Austin FC Roster as of 2026-04-18 Status.md` |
