---
name: Bahai spelling — tags vs. content
description: In tags the only correct form is "Bahai"; everywhere else (body text, nav, wikilinks, headings) it is always "Bahá'í" with full diacriticals
type: feedback
originSessionId: a9854956-2f96-4d74-893d-bb40aff6db38
---
**Rule:** `Bahai` (no diacriticals, no apostrophe) is the **only** acceptable form inside YAML tags. Outside of tags — body text, headings, nav fields, wikilinks, YAML string values — it is always `Bahá'í` (á = U+00E1, ' = U+2019, í = U+00ED).

**Why:** Obsidian tag names do not support diacriticals or apostrophes; `Bahá'í` as a tag is invalid and will not be indexed. All other contexts must preserve the correct transliteration per CLAUDE.md ("never simplify or replace diacritical characters").

**How to apply:** Any time a tag containing `Bahá'í` or `bahai` is written or generated, normalize to `Bahai`. Any time `Bahai` appears outside a tag context (prose, link, nav), correct it to `Bahá'í`.

---

When converting YAML tags across the vault (e.g., `Bahá'í` → `Bahai`), the regex pattern MUST be line-anchored.

**Why:** An unanchored pattern like `(-\s+)Bahá'í` matches any occurrence of `- Bahá'í` anywhere in the file — including inside wikilinks (`[[MOC - Bahá'í Faith]]`) and YAML string values (`nav: "[[MOC - Bahá'í Faith]]"`). This turns `[[MOC - Bahá'í Faith]]` into `[[MOC - Bahai Faith]]`, breaking wikilinks to the MOC file.

**How to apply:** Always use `(?m)^(\s*-\s+)TAG\s*$` for tag-line replacements:
- `(?m)` = multiline so `^` matches line start
- `\s*$` = end of line with no trailing content (ensures it's a standalone tag value, not mid-string)

Also: In the restore/repair pass, do NOT use `\s+` to mean "space on same line" — use `[^\S\n]+` or `[ \t]+` instead, because `\s+` matches newlines and will accidentally match across lines (e.g., `- Bahai\n  - LSA` looks like `- Bahai <whitespace> -LSA` to `\s+\S`).

**Incident:** 2026-05-03 — `Bahá'í`→`Bahai` tag pass incorrectly changed 272 nav fields and 23 body bullets; required a 3-pass fix (convert, repair collateral, re-convert with anchored pattern).
