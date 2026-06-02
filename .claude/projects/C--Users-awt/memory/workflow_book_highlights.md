---
name: workflow-book-highlights
description: "Book highlights extraction — 5 extraction paths (photos, PDF, pasted text, vault .md, annotated DOCX); incremental append mode for multi-session books"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 25cd8f74-266b-4ab4-bc6b-d782d79b35c6
---

## Trigger
"extract highlights from [book]", "create clippings for [book]", or user points at a source for highlight extraction.

---

## Step 1 — Identify the Path
- **Path A (phone photos / scans):** User photographs highlighted pages and saves as JPG/PNG to a local folder; Claude reads each image file with the Read tool (multimodal), extracts highlighted text, flags low-confidence pages
- **Path B (PDF with embedded annotations):** User points at a PDF; Claude writes and runs a Python script using PyMuPDF (`fitz`) to extract highlight annotation text programmatically
- **Path C (pasted raw text):** User pastes or types the passages directly; Claude formats and structures them
- **Path D (existing vault markdown note):** User points at a `.md` file already in the vault; Claude reads it, detects the highlight markup convention, and extracts marked passages
- **Path E (annotated DOCX / Word document):** User points at a `.docx` file; Claude writes and runs a Python script using stdlib `zipfile` + `xml.etree.ElementTree` (no third-party packages needed) to parse `word/comments.xml` (reader annotations with their associated text) and `word/footnotes.xml` (book citations). Extracts 3 artifacts: (1) each Word comment paired with the text it annotates, in document order; (2) footnotes in document order; (3) any highlighted text runs (via `<w:highlight>` in run properties). Reference extraction script: `C:\Users\awt\extract_light_of_world.py`. Key technique: build DOCX path with `chr(0xNNNN)` for diacriticals; set `sys.stdout.reconfigure(encoding="utf-8")` to avoid Windows cp1252 crash on diacritical output. Always apply a post-processing `fix_missing_spaces()` step to all extracted text fields: `re.sub(r'([.!?])([A-ZÀ-ɏ])', r'\1 \2', text)` repairs the DOCX word-wrap artifact where adjacent `<w:t>` runs are joined without a space.

## Step 2 — Markup Detection for Path D
Check in this order:
- `==passage==` — Obsidian highlight syntax; grep for `==`
- `> passage` — blockquote lines; grep for `^>`
- `**passage**` — bold spans; grep for `\*\*`
- `> [!highlight]` — callout block; grep for `\[!highlight\]`
- No markup — read full file and use judgment to identify key passages

## Step 3 — Output Note Format
- **Destination:** `09 - Kindle Clippings/` for highlights/clippings from any source; complete books go in `09 - eBooks/`
- **Filename:** `{Author Last Name}-{Short Title}.md` matching Kindle clipping naming convention
- **Frontmatter:** `title`, `author`, `tags: [BookClippings]`, `nav` pointing to relevant MOC
- **Body:** `## Highlights` section; each passage as a blockquote; page/location reference appended if available

## Step 4 — Workflow Steps
1. Confirm path and get file path / image folder / source
2. Check whether a clippings note for this book already exists (search `09 - Kindle Clippings/` by author/title)
3. **If existing note found → Incremental/append mode** (see Step 6 below)
4. **If no existing note → First session:** extract all passages, write new note with full frontmatter, link in MOC
5. Deduplicate and order by page number where discernible
6. Check synthesis layer — if the book touches an existing synthesis page, update it with new evidence; offer to create a new synthesis page if the book warrants one
7. Run People Index check on extracted passages; add any new names

## Step 5 — Output
Report total passages extracted, source pages covered, any low-confidence extractions flagged, MOC link added, synthesis updates made.

## Step 6 — Incremental / Append Mode (multi-session books)
- Read the existing clippings note and find the **last page/location reference** in `## Highlights` (patterns: `p. NNN`, `Page NNN`, `loc. NNNN`, or the book's own citation convention)
- That value is the **resume point** — skip all content at or before it; extract only content after it
- Append new highlights to the existing `## Highlights` section (do not recreate the note)
- Insert a dated session divider before the new batch:
  ```
  ---
  *Session YYYY-MM-DD — pp. NNN–NNN*
  ---
  ```
- Per-path resume strategy:
  - **Path A (photos):** User provides images from the resume point forward; read visible page numbers in images to confirm
  - **Path B (PDF):** Resume from the page after the last annotated page already in the note
  - **Path C (pasted text):** User pastes the new section; append directly
  - **Path D (vault .md):** Scan markup from after the last extracted passage
  - **Path E (DOCX):** Track by comment index — note the last comment number processed in the session divider; start from the next index on resume
- At session start, confirm the resume point with the user ("Last extracted: p. 47 — continuing from p. 48. Does that match?")
- Do NOT re-link in MOC or re-run synthesis check unless meaningful new content warrants a synthesis update
