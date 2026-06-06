Extract synthesized knowledge from any source and file it as a permanent vault note. Never saves verbatim content — output is always distilled key points, concepts, and people only.

## Parameters

`$ARGUMENTS` — the source to ingest:
- `/ingest-resource https://example.com/article` — web article
- `/ingest-resource https://youtube.com/watch?v=...` — YouTube video (transcript via yt-dlp or auto-captions)
- `/ingest-resource C:\path\to\file.pdf` — local PDF
- `/ingest-resource C:\path\to\file.docx` — local Word document
- `/ingest-resource C:\path\to\transcript.vtt` — local transcript file
- `/ingest-resource` with no args → prompt: "Paste text, give a URL, or a file path?"

---

## Step 1 — Detect Source Type

Parse `$ARGUMENTS` and classify:

| Input pattern | Source type | Fetch method |
|---|---|---|
| `youtube.com/` or `youtu.be/` | YouTube | yt-dlp transcript (see `workflow_video_processing.md`); fall back to WebFetch auto-captions |
| `http://` or `https://` (non-YouTube) | Web article | Apply Global Web Fetch Routing Rule: plain WebFetch for static pages; note if JS-heavy domain |
| Path ending `.pdf` | PDF | Run `pdf_to_obsidian.py`; move original to `09 - Attachments\` after extraction |
| Path ending `.docx` or `.rtf` | Document | Convert via LibreOffice at `C:\Program Files\LibreOffice\program\soffice.exe`; move original to `09 - Attachments\` |
| Path ending `.vtt`, `.srt`, `.txt`, `.md` | Local file | Read directly |
| No URL or path — raw text | Pasted text | Use content as-is |
| No args | Unknown | Prompt the user |

If the source is behind a login wall or returns a bot-block (403/429): stop and report — do not guess at content.

---

## Step 2 — Extract Knowledge

Read or fetch the full source content, then synthesize. **Do not copy verbatim passages into the output.** Produce:

### Summary
2–4 sentences: what this source is, who produced it, and its central argument or purpose.

### Key Points
5–10 bullets — the most transferable, actionable, or intellectually significant ideas. Write each in your own words. Ask: "What would a knowledgeable reader want to remember from this in two years?"

### Key Concepts
Named frameworks, theories, terms, or models introduced or used. One line each: name + brief definition as used in this source.

### Key People
Every person named or centrally relevant. For each: name + role/context as they appear in the source.

### Quotations
Short verbatim excerpts — only when a direct quote materially supports a key point and cannot be adequately paraphrased. Maximum 2–3 quotes per source; each must be anchored to a specific key point by reference (e.g., "re: Key Point 3"). Omit this section if no quote clears that bar.

### Open Questions
Claims that are unverified, assertions that warrant follow-up, or questions the source raises but does not answer. Omit this section if none.

---

## Step 3 — Build Frontmatter

```yaml
---
title: {Title — descriptive, not the source's headline verbatim}
source: {URL | file path | "pasted text"}
source_type: {article | youtube | transcript | pdf | docx | note | text}
author: {Author name if known | Unknown}
date_published: {YYYY-MM-DD if known | Unknown}
date_ingested: {YYYY-MM-DD}
key_people:
  - {Name}
key_concepts:
  - {Concept}
tags:
  - {TopicTag}
related_mocs:
  - "[[MOC - X]]"
nav: "[[Master MOC Index]]"
---
```

Tag rules:
- Use `Bahai` (no diacriticals) for Bahá'í-related content
- Add `BahaiScripture` if source is attributed to Bahá'u'lláh, The Báb, or 'Abdu'l-Bahá
- Do NOT add a `Clipping` tag — this is a synthesized note, not a clipping
- Add `JapanTrip` if content relates to the 2026 Japan trip
- Derive other tags from topic domain (PKM, AI, History, Travel, Soccer, etc.)

---

## Step 4 — Route to Correct Folder

Apply in order — first match wins:

| Condition | Destination |
|---|---|
| Tagged `#JapanTrip` | `02 - Working Projects\2026 Japan Trip\` |
| Tagged `#2024-WashingtonTrip` or Travel + Megaflood/Washington | `03 - Completed Projects\2024 Columbia River Trip\` |
| Elias White Talbot / EWT genealogy content | `02 - Working Projects\Elias White Talbot - Project\` |
| Bahá'í scripture or core Faith content | `01\Bahai\` |
| Recipe | `01\Recipes\` |
| Soccer / MLS / USMNT / USWNT | `01\Soccer\` |
| FOL (Friends of Georgetown Public Library) | `01\FOL\` |
| PKM / Obsidian / note-taking methodology | `01\PKM\` |
| AI / machine learning / LLMs | `01\AI\` |
| Georgetown TX local content | `01\Georgetown\` |
| Travel (general, non-project) | `01\Travel\` |
| History (general) | `01\History\` |
| Health / wellness | `01\Health\` |
| No clear match | `01\` + create a new subfolder named after the primary topic |

**Folder creation:** Before writing, check `Test-Path` on the target folder. If it does not exist, create it:
```powershell
New-Item -ItemType Directory -Path $targetFolder -Force
```
Log inline: `[Created folder: 01\NewTopic\]`

**File name:** Title Case, no date prefix unless the source is a news item or time-stamped event. Use the synthesized title from frontmatter, not the source headline.

---

## Step 5 — Write the Output File

Structure:

```markdown
---
[frontmatter]
---

## Summary

{2–4 sentences}

## Key Points

- {Point}
- {Point}
...

## Key Concepts

- **{Concept}** — {definition as used in this source}
...

## Key People

- **{Name}** — {role/context}
...

## Quotations

> "{quote}" — {Name}  ← only if it materially supports a key point; omit section entirely if none

## Open Questions

- {Question}        ← omit section entirely if none

## Related Notes

- [[Note A]]
- [[Note B]]
```

---

## Step 6 — Update People Index

For every person listed under Key People:

1. Read `D:\Obsidian\Main\People Index.md`
2. Determine the correct alphabetical letter section (People Index is organized by last name initial)
3. **If the person is missing:**
   - Locate the correct letter section (e.g., `## T` for Talbot)
   - Find the correct alphabetical insertion point within that section — insert the new entry IN PLACE, do not append to the end of the file or the end of the section
   - Insert using Edit, targeting the line just before the next name that sorts after this one
   - Format:
     ```
     ### Last, First
     - [[{ingested note title}]]
     ```
   - No blank lines between `### Name` entries within a section (per `feedback_people_index_format.md`)
4. **If the person already has an entry:**
   - Add the ingested note as an additional link under their existing entry:
     ```
     - [[{ingested note title}]]
     ```
   - Insert after their existing links, not at the end of the file
5. Do NOT create biography stub files in `15 - People\` — People Index only

---

## Step 7 — Crosslink

1. Grep vault for notes sharing key concepts or key people names
2. Add the top 3–5 most relevant matches to `## Related Notes` in the new note
3. Patch each matched note to add a reciprocal link in their own `## Related Notes` section
4. Identify the correct MOC and subsection — add the new note's wikilink there
5. Check `30 - Synthesis\` — does this source support, contradict, or extend an existing synthesis page? If yes, note it in Open Questions or flag it for the user

---

## Step 8 — Log

Append to `D:\Obsidian\Main\01\PKM\Claude Action Log.md`:

```
[INGEST] {filename} → {folder} | source: {source_type} — {URL or filename} | {N} crosslinks | {N} People Index entries added/updated
```

---

## Step 9 — Decision Log

After the log entry, report a **Decisions** section covering judgment calls made during this ingest:

- **Routing:** which folder was chosen and why, if more than one could have applied
- **Tags:** list tags applied; flag any variant or duplicate encountered (name both; mark the one applied)
- **MOC subsection:** which subsection was chosen if the note could fit multiple
- **Any ambiguity** where the existing rules didn't clearly resolve the choice — describe what was decided and why
- If a decision revealed a missing or ambiguous rule, write it to memory immediately and mark *(memorized)*
- Mark unresolved questions *(flag for user)*

**Format:**
```
**Decisions this ingest:**
- Routed to `{folder}` over `{alternative}` because {reason}
- Tag `{variant}` encountered; applied `{canonical}` *(flag: confirm canonical?)*
- MOC subsection: {subsection} chosen over {alternative} because {reason}
```

Omit this section if all routing was unambiguous and matched existing rules without judgment.

---

## Key Rules

- **Never save verbatim source content** — summary, key points, concepts, and people only
- **Never route to `10 - Clippings\`** — this skill produces synthesized notes, not clippings
- **Never create biography stub files** — People Index entries only
- **Source files** (PDF, DOCX, RTF) move to `09 - Attachments\` after extraction — do not delete
- **Diacriticals:** Preserve Bahá'í, Bahá'u'lláh, 'Abdu'l-Bahá, Riḍván exactly — never simplify
- **UTF-8:** All file reads and writes use UTF-8 encoding — never re-encode
- **Login walls / bot-blocks:** Report and stop — do not infer or fabricate content
- **Curly apostrophes in filenames:** Normalize before any file operation (`$name -replace [char]0x2019, "'"`)
