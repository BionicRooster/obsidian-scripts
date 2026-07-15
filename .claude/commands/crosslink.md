Find vault notes that bridge multiple topic areas and add wikilinks between them in their Related Notes sections.

## Parameters

No arguments. Operates across all content folders in `C:\Users\awt\Sync\Obsidian\01\`.

---

## Step 1 — Identify Cross-Topic Candidates

Scan notes in `C:\Users\awt\Sync\Obsidian\01\` for content that meaningfully connects to another topic area. Use the patterns below as a guide, but apply judgment — the goal is genuine intellectual connection, not forced association.

**Cross-topic connection patterns:**

| Note type | Likely connects to |
|---|---|
| Cognitive science / memory / learning | Health & Nutrition (brain health); NLP & Psychology (behavior); PKM (spaced repetition) |
| Race / social justice | Bahá'í unity teachings; Psychology (trauma, implicit bias) |
| PKM / Obsidian / productivity | Psychology (habit formation, cognition); NLP (mental models) |
| Maker / tech projects | Social development; Science & Nature (engineering) |
| Religious / spiritual (non-Bahá'í) | Social Issues > Religion & Society; Bahá'í comparative themes |
| Science / nature / ecology | Indigenous knowledge; Health & Nutrition (food systems) |
| Books that reference each other | Each other directly |

**Known high-value links (check these explicitly):**
- Dyslexia and reading difficulty articles → each other + learning/cognitive notes
- *The Sum of Us* and *My Grandmother's Hands* → Bahá'í race unity teachings
- Kahneman's *Thinking, Fast and Slow* → Dunning-Kruger notes, cognitive bias, productivity
- *The Boy Who Harnessed the Wind* → maker/engineering projects, sustainability
- Any note on implicit bias → notes on justice, psychology of prejudice

---

## Step 2 — Locate Existing Related Notes Sections

For each candidate note:
1. Read the file
2. Find the `## Related Notes` section (it will be near the bottom, before `---`)
3. Collect what links are already present — do not add duplicates

---

## Step 3 — Add Links

For each cross-topic connection identified:

1. Open both files
2. In File A's `## Related Notes`, add `[[File B]]` if not already present
3. In File B's `## Related Notes`, add `[[File A]]` if not already present (bidirectional)

**Rules:**
- Only link to **content notes** — never link to MOC files (`*MOC*.md`)
- Do NOT modify any file in `09 - Kindle Clippings\` — these are read-only; other files CAN link to them, but do not edit the clipping file itself
- Do not add links that are already present (check both the wikilink `[[Note Name]]` and any path variant)
- Do not invent connections — if the link requires explanation to justify, it is probably too weak to add
- Add at most 3–5 new links per file per session; avoid overwhelming the Related Notes section

---

## Step 4 — Preserve Structure

The `## Related Notes` section uses this format:

```markdown
## Related Notes
- [[Note Title]]
- [[Another Note Title]]
```

Append new links at the end of the existing list. Do not reorder existing links. Preserve UTF-8 encoding.

---

## Step 5 — Report

Summary table of all links added:

| File A | File B | Connection type |
|---|---|---|
| Dunning-Kruger Effect.md | Thinking Fast and Slow.md | Cognitive bias ↔ behavioral economics |

Also report total: N files updated · N links added.

Do not log to Claude Action Log — this is housekeeping.
