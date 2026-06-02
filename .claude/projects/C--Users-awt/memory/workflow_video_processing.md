---
name: video-processing-workflow
description: "Standard process for summarizing a YouTube video and creating an Obsidian note with key points, action items, and verbatim transcript. Supports two entry paths: full workflow (Claude only) and finishing workflow (Web Clipper skeleton already created)."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 2661a7b6-1c52-4110-8a45-356269a64677
---

# Video Processing Workflow

## Entry Path Detection (always first)

Before doing anything, grep `D:\Obsidian\Main\10 - Clippings\` for a note whose `source:` frontmatter matches the YouTube URL, OR whose body contains `*Transcript pending*`.

- **If a matching note exists** → **Web Clipper path** (skeleton already created). Skip Steps 1–4 note creation. Go directly to Step 3 (transcript only) then Step 5 (finish note).
- **If no matching note exists** → **Full path** (Claude creates everything). Run all steps in order.

When user says `"finish the last YouTube clip"` with no URL: grep for the most recent file in `10 - Clippings\` containing `*Transcript pending*` and use its `source:` URL.

---

## Step 1 — Download Captions with yt-dlp

`yt-dlp` is installed under Python 3.12 at `C:\Users\awt\AppData\Roaming\Python\Python312\site-packages`. **Always invoke via `py -3.12`** — the default `python` (3.14 as of 2026-05) does not have yt-dlp and will fail:

```powershell
py -3.12 -m yt_dlp --write-auto-sub --sub-lang en --skip-download --output "C:\Users\awt\AppData\Local\Temp\yt_transcriptN" "URL"
```

- Output file: `C:\Users\awt\AppData\Local\Temp\yt_transcriptN.en.vtt`
- Increment `N` for each video in the same session to avoid overwriting
- yt-dlp may warn about missing JS runtime — ignore; it still works for subtitle extraction
- If `-Filter "*.vtt"` search returns nothing after download, read the file directly at the known path

## Step 2 — Get Video Title

`yt-dlp --get-title` sometimes returns empty. Fallback: use WebFetch on the YouTube URL with prompt "What is the exact title of this YouTube video?"

*Skip this step on the Web Clipper path — title is already in the note frontmatter.*

## Step 3 — Clean and Reassemble Transcript

YouTube auto-captions use a rolling window (each VTT block adds 1–2 words to the previous sentence), producing massive duplication. Use this Python script inline via Bash heredoc:

```python
import re

with open(r'C:\Users\awt\AppData\Local\Temp\yt_transcriptN.en.vtt', 'r', encoding='utf-8') as f:
    content = f.read()

blocks = re.split(r'\n\n+', content.strip())
entries = []
for block in blocks:
    lines = block.strip().split('\n')
    ts_line = None
    text_lines = []
    for line in lines:
        if '-->' in line:
            ts_line = line
        elif line and not line.startswith('WEBVTT') and not line.startswith('Kind:') \
             and not line.startswith('Language:') and not re.match(r'^\d+$', line):
            clean = re.sub(r'<[^>]+>', '', line).strip()
            if clean:
                text_lines.append(clean)
    if ts_line and text_lines:
        start = ts_line.split('-->')[0].strip()
        m = re.match(r'(\d+):(\d+):(\d+)\.(\d+)', start)
        if m:
            h, mi, s = int(m.group(1)), int(m.group(2)), int(m.group(3))
            total_s = h*3600 + mi*60 + s
            ts_fmt = f"{h*60+mi:02d}:{s:02d}"
            entries.append((total_s, ts_fmt, ' '.join(text_lines)))

# Deduplicate rolling window
result = []
prev_words = []
for total_s, ts, text in entries:
    words = text.split()
    if not prev_words:
        result.append((total_s, ts, words))
        prev_words = words
        continue
    max_overlap = min(len(prev_words), len(words))
    overlap = 0
    for ol in range(max_overlap, 0, -1):
        if prev_words[-ol:] == words[:ol]:
            overlap = ol
            break
    new_words = words[overlap:]
    if new_words:
        result.append((total_s, ts, new_words))
    prev_words = words

# Merge into ~10-second windows
merged = []
window_s = 10
current_start_s = current_ts = None
current_words = []
for ts_s, ts, words in result:
    if current_start_s is None:
        current_start_s, current_ts, current_words = ts_s, ts, list(words)
    elif ts_s - current_start_s < window_s:
        current_words.extend(words)
    else:
        merged.append((current_ts, ' '.join(current_words)))
        current_start_s, current_ts, current_words = ts_s, ts, list(words)
if current_words:
    merged.append((current_ts, ' '.join(current_words)))

for ts, text in merged:
    print(f"[{ts}] {text}")
print(f"\n--- Total segments: {len(merged)} ---")
```

Output is large — it will be persisted to a tool-results file. Read it from there.

## Step 4 — Write or Finish the Obsidian Note

**Location:** `D:\Obsidian\Main\10 - Clippings\<Sanitized Title>.md`

### Full path (no existing note)

Write the complete note using this structure:

```markdown
---
title: "Full video title"
source: "https://www.youtube.com/watch?v=..."
created: YYYY-MM-DD
type: video
speakers:           # omit if narrator-only video
  - "Name, Role, Organization"
tags:
  - [topic tags]
  - clipping
  - video
nav: "[[MOC - Relevant MOC]]"
---

[[MOC - Relevant MOC]]

**Speakers:** ...   # omit if narrator-only

---

## Summary

One paragraph covering the video's main argument and scope.

---

## Key Points

- **Topic:** detail, specific numbers/formulas/cautions where given

---

## Action Items

- [ ] #task (specific actionable step)

---

## Transcript

[MM:SS] Natural paragraph grouped by topic shift or speaker turn. First timestamp of each paragraph only.

---

## Related Notes

- [[MOC - Primary MOC]]
- [[MOC - Secondary MOC if applicable]]
```

### Web Clipper path (existing note — finish only)

The Web Clipper has already created the note with frontmatter, Summary, Key Points, Action Items, and Speakers sections. Do the following:

1. **Replace transcript placeholder** — Edit the file to replace `*Transcript pending — run Claude video workflow to add deduplicated timestamped transcript.*` with the full cleaned transcript text (topic-grouped paragraphs, first timestamp per paragraph only)
2. **Add `nav` frontmatter field** — add `nav: "[[MOC - Relevant MOC]]"` to frontmatter
3. **Add `speakers` frontmatter field** if the video has identified speakers (parse from the `## Speakers` section the Interpreter wrote, or from transcript)
4. **Add `[[MOC - Relevant MOC]]` backlink** as first line after the closing `---` of frontmatter
5. **Do NOT rewrite** Summary, Key Points, or Action Items if the Interpreter already populated them — only fill them if they are blank

## Step 5 — Link in MOC

Add the note to the appropriate MOC subsection. Classify by content:
- Gardening/nature → MOC - Science & Nature > Gardening & Botany
- Nonprofit/fundraising → MOC - Friends of the Georgetown Public Library (if FOL-relevant) or appropriate MOC
- Tech/AI → MOC - Technology & Computers
- Health → MOC - Health & Nutrition
- etc.

## Step 6 — Log to Claude Action Log

Append a bullet to `D:\Obsidian\Main\01\PKM\Claude Action Log.md` under today's `## YYYY-MM-DD` section (create it if it doesn't exist).

Format: `[INGEST] <Title> — video clipping created, linked to <MOC subsection>`

For Web Clipper path: `[INGEST] <Title> — Web Clipper skeleton finished (transcript added), linked to <MOC subsection>`

## Notes

- WebFetch on YouTube URLs only returns footer HTML — always use yt-dlp for transcripts
- `yt-dlp --get-title` sometimes returns empty; use WebFetch as fallback for the title
- Transcript output will exceed context limits when printed — save to `/tmp/` or rely on persisted tool-results file
- Group transcript into natural paragraphs (topic shifts, speaker turns) — do NOT follow the 10-second mechanical windows as paragraph breaks; those are just the raw input
- Web Clipper template trigger: fires automatically on `https://www.youtube.com/watch?v=` URLs
- Web Clipper template file (for re-import): `C:\Users\awt\Desktop\youtube-video-wayne.json`
