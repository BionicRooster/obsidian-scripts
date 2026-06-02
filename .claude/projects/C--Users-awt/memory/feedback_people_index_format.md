---
name: People Index — Formatting Rules
description: Internal formatting conventions for People Index.md to prevent double-blank-line accumulation
type: feedback
originSessionId: f2c229e5-bd10-4e40-b472-28911306b580
---
**No blank lines between `### Name` entries** within a letter section. Blank lines are kept only around `## Letter` headings and `---` section separators.

**Why:** Automated workflows tend to add blank lines between person entries, causing the file to grow unnecessarily and look uneven.

**How to apply:** When adding entries to the People Index, never insert blank lines between consecutive `### Name` entries. To fix accumulated double-blank-lines in the file:
```powershell
$text -replace '(?m)\r?\n\r?\n(### )', "`n`$1"
```
