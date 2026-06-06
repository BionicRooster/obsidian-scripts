# -*- coding: utf-8 -*-
"""
General-purpose extractor for reading notes and highlights from annotated DOCX files.
Replaces the per-book scripts (extract_light_of_world.py, extract_sacred_writings_notes.py).

Output format:
  - All highlights and reading notes interleaved in document order
  - Leading paragraph number prepended if the paragraph begins with one (e.g. "94.1")
  - Source attribution (next paragraph's text) appended after each entry
  - Yellow highlights rendered with Obsidian ==...== syntax
  - Non-yellow highlights labeled with color name (e.g. [green])
  - Footnotes in a separate section (optional)

Usage:
    py -3.12 extract_docx_notes.py \\
        --docx  "C:\\path\\to\\book.docx"                         (required) \\
        --out   "D:\\Obsidian\\Main\\09 - Kindle Clippings\\x.md"  (required) \\
        --title "Book Title"                                       (required) \\
        --author "Author Name"                                     (required) \\
        --nav   "MOC - Bahá'í Faith"                               (required) \\
        --tags  "BookClippings,Bahai,AbdulBaha"                    (optional, default: BookClippings) \\
        --related "RelatedNote1,RelatedNote2"                      (optional) \\
        --no-footnotes                                             (skip footnote section) \\
        --no-highlights                                            (skip highlight extraction) \\
        --append                                                   (append mode: session divider instead of overwrite)

Examples:
    # Light of the World (has footnotes, no highlights):
    py -3.12 extract_docx_notes.py \\
        --docx "D:\\Documents\\light-of-the-world-full-diacritics.docx" \\
        --out  "D:\\Obsidian\\Main\\09 - Kindle Clippings\\AbdulBaha-Light-of-the-World.md" \\
        --title "Light of the World" --author "'Abdu'l-Bahá" \\
        --nav "MOC - Bahá'í Faith" --tags "BookClippings,Bahai,AbdulBaha" \\
        --no-highlights

    # Bahá'í Sacred Writings WT Notes R3 (has highlights, no footnotes):
    py -3.12 extract_docx_notes.py \\
        --docx "C:\\Users\\awt\\Sync\\Bahá'í\\Word\\Bahá'í Sacred Writings - WT Notes R3.docx" \\
        --out  "D:\\Obsidian\\Main\\09 - Kindle Clippings\\BahaiSacredWritings-WT-Notes.md" \\
        --title "Bahá'í Sacred Writings — Reading Notes" --author "Wayne Talbot (annotator)" \\
        --nav "MOC - Bahá'í Faith" --tags "BookClippings,Bahai,BahaiScripture" \\
        --no-footnotes
"""
import argparse
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path

# Force UTF-8 stdout so Windows cp1252 terminal does not choke on diacriticals
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# ---------------------------------------------------------------------------
# Word XML namespace
# ---------------------------------------------------------------------------
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

def wt(n):
    """Return Clark-notation tag for the Word main namespace."""
    return f"{{{W}}}{n}"


# ---------------------------------------------------------------------------
# Text cleanup — fix DOCX word-wrap concatenation artifact
# ---------------------------------------------------------------------------
def fix_missing_spaces(text):
    """
    DOCX joins adjacent <w:t> runs without spaces, producing artifacts like:
        "Bahá'u'lláh.He arrived"  →  "Bahá'u'lláh. He arrived"
    Rules:
      • Sentence-ending punctuation before uppercase → insert space
      • Comma / semicolon before any letter → insert space
    """
    text = re.sub(r'([.!?])([A-ZÀ-ɏ])', r'\1 \2', text)
    text = re.sub(r'([,;])([A-Za-zÀ-ɏ])', r'\1 \2', text)
    return text


# ---------------------------------------------------------------------------
# Extract leading paragraph number from paragraph-start text
# ---------------------------------------------------------------------------
def extract_para_prefix(text):
    """
    If the paragraph begins with a numeric reference like "94.1" or "3",
    return that string.  Otherwise return empty string.
    Matches integers and decimal references (e.g. 1.2, 94, 3.4.1).
    """
    m = re.match(r'^(\d+(?:\.\d+)*)\b', text.strip())
    return m.group(1) if m else ""


def extract_trailing_citation(text):
    """
    Extract a structured source citation from the END of a paragraph.

    In the Sacred Writings DOCX (and similar Bahá'í reference texts), each
    paragraph ends with its own citation after substantial whitespace:
        "...last word of quote.          1.2 | GL | Book - Gleanings..."

    Matches the pattern: 2+ spaces, then  N.N | XX | anything
    Returns the citation string (stripped), or "" if none found.
    """
    m = re.search(r'\s{2,}(\d+(?:\.\d+)?\s*\|\s*[A-Za-z]+\s*\|.+)$', text)
    return m.group(1).strip() if m else ""


# ---------------------------------------------------------------------------
# Load word/comments.xml  →  dict[id → {author, date, text}]
# ---------------------------------------------------------------------------
def load_comments(z):
    """
    Parse comments.xml from the DOCX zip.
    Returns dict keyed by comment ID string → {author, date, text}.
    Returns empty dict if comments.xml is absent.
    """
    if "word/comments.xml" not in z.namelist():
        return {}
    with z.open("word/comments.xml") as f:
        tree = ET.parse(f)
    cmap = {}   # maps comment id → metadata
    for c in tree.getroot().findall(wt("comment")):
        cid    = c.get(wt("id"))           # comment id string
        author = c.get(wt("author"), "")
        date   = c.get(wt("date"), "")
        texts  = [t.text or "" for t in c.iter(wt("t"))]
        cmap[cid] = {"author": author, "date": date, "text": "".join(texts).strip()}
    return cmap


# ---------------------------------------------------------------------------
# Load word/footnotes.xml  →  dict[id → text]
# ---------------------------------------------------------------------------
def load_footnotes(z):
    """
    Parse footnotes.xml from the DOCX zip.
    Returns dict keyed by footnote ID string → cleaned text.
    Returns empty dict if footnotes.xml is absent.
    Structural placeholder footnotes (separator, continuationSeparator) are skipped.
    """
    if "word/footnotes.xml" not in z.namelist():
        return {}
    with z.open("word/footnotes.xml") as f:
        tree = ET.parse(f)
    skip_types = {"separator", "continuationSeparator", "continuationNotice"}
    fmap = {}   # maps footnote id → text
    for fn in tree.getroot().findall(wt("footnote")):
        if fn.get(wt("type"), "") in skip_types:
            continue
        fid   = fn.get(wt("id"))
        texts = [t.text or "" for t in fn.iter(wt("t"))]
        fmap[fid] = fix_missing_spaces("".join(texts).strip())
    return fmap


# ---------------------------------------------------------------------------
# Walk document.xml body — extract comments, highlights, para texts
# ---------------------------------------------------------------------------
def extract_from_document(body, comment_map, extract_highlights):
    """
    Recursive DFS over the DOCX body element.

    Tracks three additional pieces of state per paragraph:
      para_texts  — full text of every paragraph (used as source attribution
                    for the entry in the PRECEDING paragraph)
      para_pre_hi — text that appears before any annotation (highlight or
                    comment range) in each paragraph; used to detect a leading
                    paragraph-number prefix like "94.1"

    Returns:
        merged_comments  — list of dicts in document order, each with:
                           {id, para, commented_text, comment_text, author,
                            para_prefix, source}
        highlights       — list of dicts in document order, each with:
                           {color, text, para, para_prefix, source}
        footnote_order   — list of footnote ID strings in document order
    """
    # Comment range accumulators
    open_ids       = {}   # comment id → list[str]  accumulating text while range is open
    closed_results = {}   # comment id → {para, commented_text}
    comment_order  = []   # comment IDs in the order their ranges close
    footnote_order = []   # footnote IDs in document order

    # Paragraph counter (increments on each <w:p> entry)
    para_num = [0]

    # Highlight accumulator state (reset per paragraph)
    hi_results    = []       # all collected highlight passages
    cur_hi_color  = [None]   # color of the highlight currently being accumulated
    cur_hi_chunks = [[]]     # text chunks for current highlight run

    # Per-paragraph text tracking
    para_texts      = {}   # para_num → full text of that paragraph
    para_pre_hi     = {}   # para_num → text before first annotation in that paragraph
    cur_para_chunks = [[]] # full-paragraph text accumulator (reset each <w:p>)
    pre_hi_chunks   = [[]] # pre-annotation text accumulator (reset each <w:p>)
    pre_hi_done     = [False]  # True once an annotation has started in current para

    def save_current_para():
        """Snapshot the current paragraph's accumulated text into the lookup dicts."""
        pn = para_num[0]
        if pn > 0:   # skip the initial state before the first paragraph
            para_texts[pn]  = fix_missing_spaces("".join(cur_para_chunks[0]).strip())
            para_pre_hi[pn] = fix_missing_spaces("".join(pre_hi_chunks[0]).strip())

    def flush_highlight():
        """Save the in-progress highlight run to hi_results, then reset state."""
        if cur_hi_color[0] and cur_hi_chunks[0]:
            combined = fix_missing_spaces("".join(cur_hi_chunks[0]).strip())
            if combined:
                hi_results.append({
                    "color": cur_hi_color[0],
                    "text":  combined,
                    "para":  para_num[0],
                })
        cur_hi_color[0]  = None
        cur_hi_chunks[0] = []

    def recurse(elem):
        tag = elem.tag

        # New paragraph: snapshot previous para text, flush pending highlight,
        # increment counter, reset per-paragraph accumulators
        if tag == wt("p"):
            save_current_para()
            flush_highlight()
            para_num[0]     += 1
            cur_para_chunks[0] = []
            pre_hi_chunks[0]   = []
            pre_hi_done[0]     = False

        # Open a comment annotation range
        if tag == wt("commentRangeStart"):
            cid = elem.get(wt("id"))
            if cid is not None and cid not in open_ids:
                open_ids[cid] = []
                # A comment range starting marks the end of the pre-annotation region
                pre_hi_done[0] = True

        # Close a comment annotation range
        elif tag == wt("commentRangeEnd"):
            cid = elem.get(wt("id"))
            if cid is not None and cid in open_ids:
                commented = "".join(open_ids.pop(cid)).strip()
                closed_results[cid] = {"para": para_num[0], "commented_text": commented}
                comment_order.append(cid)

        # Footnote reference marker — record document order only
        elif tag == wt("footnoteReference"):
            fid = elem.get(wt("id"))
            if fid:
                footnote_order.append(fid)

        # Text run <w:r>
        elif tag == wt("r"):
            # Determine highlight color for this run (None if not highlighted)
            rpr        = elem.find(wt("rPr"))
            hi_elem    = rpr.find(wt("highlight")) if rpr is not None else None
            this_color = hi_elem.get(wt("val")) if hi_elem is not None else None

            # Collect all text from <w:t> children of this run
            run_text = "".join(t.text or "" for t in elem.findall(wt("t")))

            # Feed text into every open comment range accumulator
            for cid in list(open_ids.keys()):
                open_ids[cid].append(run_text)

            # Always accumulate into the full-paragraph tracker
            if run_text:
                cur_para_chunks[0].append(run_text)

            # Accumulate pre-annotation text: only while no annotation has started
            # and the run is neither highlighted nor inside a comment range
            if run_text and not pre_hi_done[0]:
                if this_color is None and not open_ids:
                    pre_hi_chunks[0].append(run_text)
                else:
                    # Annotation begins — stop collecting pre-annotation text
                    pre_hi_done[0] = True

            # Manage highlight accumulation (only when enabled)
            if extract_highlights and run_text:
                if this_color is not None:
                    if this_color == cur_hi_color[0]:
                        cur_hi_chunks[0].append(run_text)   # extend same-color run
                    else:
                        flush_highlight()                    # color changed, start new run
                        cur_hi_color[0]  = this_color
                        cur_hi_chunks[0] = [run_text]
                else:
                    flush_highlight()   # non-highlighted run ends any pending highlight

            # Do NOT recurse further into <w:r>; <w:t> already handled above
            return

        # Bare <w:t> outside a <w:r> (rare, e.g. inside hyperlinks)
        elif tag == wt("t"):
            chunk = elem.text or ""
            for cid in list(open_ids.keys()):
                open_ids[cid].append(chunk)
            if chunk:
                cur_para_chunks[0].append(chunk)
                if not pre_hi_done[0] and not open_ids:
                    pre_hi_chunks[0].append(chunk)

        # Recurse into all children in document order
        for child in elem:
            recurse(child)

    recurse(body)
    flush_highlight()
    save_current_para()   # snapshot the final paragraph

    # -------------------------------------------------------------------
    # Annotate each highlight with its paragraph prefix and source line
    # -------------------------------------------------------------------
    for h in hi_results:
        pn = h["para"]
        h["para_prefix"] = extract_para_prefix(para_pre_hi.get(pn, ""))
        h["source"]      = extract_trailing_citation(para_texts.get(pn, ""))

    # -------------------------------------------------------------------
    # Build merged comments with para_prefix and source
    # -------------------------------------------------------------------
    merged_comments = []
    for cid in comment_order:
        pos   = closed_results[cid]
        cinfo = comment_map.get(cid, {})
        pn    = pos["para"]
        merged_comments.append({
            "id":             cid,
            "para":           pn,
            "commented_text": fix_missing_spaces(pos["commented_text"]),
            "comment_text":   fix_missing_spaces(cinfo.get("text", "")),
            "author":         cinfo.get("author", ""),
            "para_prefix":    extract_para_prefix(para_pre_hi.get(pn, "")),
            "source":         extract_trailing_citation(para_texts.get(pn, "")),
        })

    # Surface point comments (commentReference only, no range)
    range_ids = set(comment_order)
    for cid, cinfo in comment_map.items():
        if cid not in range_ids:
            merged_comments.append({
                "id":             cid,
                "para":           999999,
                "commented_text": "",
                "comment_text":   fix_missing_spaces(cinfo.get("text", "")),
                "author":         cinfo.get("author", ""),
                "para_prefix":    "",
                "source":         "",
            })

    merged_comments.sort(key=lambda x: (x["para"], int(x["id"])))
    return merged_comments, hi_results, footnote_order


# ---------------------------------------------------------------------------
# Merge comments and highlights into one document-order list
# ---------------------------------------------------------------------------
def merge_entries(comments, highlights):
    """
    Combine comment and highlight entries into a single list sorted by
    document order (para, then comment id as tiebreaker).

    Each entry in the returned list has:
        type        — 'highlight' or 'comment'
        para        — paragraph index from document walk
        para_prefix — leading paragraph number string, or ""
        source      — attribution text from next paragraph, or ""
        text        — highlighted text or annotated passage (may be "")
        note        — reading note text (comments only, may be None)
        color       — 'yellow', 'green', etc. (highlights only, None for comments)
        sort_id     — numeric tiebreaker (comment id int; 0 for highlights)
    """
    unified = []   # combined list of all annotation entries

    for h in highlights:
        unified.append({
            "type":       "highlight",
            "para":       h["para"],
            "para_prefix": h["para_prefix"],
            "source":     h["source"],
            "text":       h["text"],
            "note":       None,
            "color":      h["color"],
            "sort_id":    0,   # highlights sort before comments at the same para
        })

    for c in comments:
        if not c["comment_text"]:
            continue   # skip entries with no note text
        unified.append({
            "type":       "comment",
            "para":       c["para"],
            "para_prefix": c["para_prefix"],
            "source":     c["source"],
            "text":       c["commented_text"],
            "note":       c["comment_text"],
            "color":      None,
            "sort_id":    int(c["id"]),
        })

    unified.sort(key=lambda x: (x["para"], x["sort_id"]))
    return unified


# ---------------------------------------------------------------------------
# Render one entry to markdown lines
# ---------------------------------------------------------------------------
def render_entry(entry):
    """
    Return a list of markdown lines for one unified entry.

    Highlights:
        > ==prefix text==          (yellow — Obsidian native highlight)
        > [green] prefix text      (non-yellow — labeled with color name)
        *source*                   (if source text exists)

    Comments:
        > prefix annotated text    (if there is an annotated passage)
        **Note:** note text
        *source*                   (if source text exists)
    """
    lines = []   # output lines for this single entry

    prefix_str = f"{entry['para_prefix']} " if entry["para_prefix"] else ""
    text       = entry["text"]
    note       = entry["note"]
    color      = entry["color"]
    source     = entry["source"]
    etype      = entry["type"]

    if etype == "highlight":
        if color == "yellow":
            # Obsidian renders ==...== as a yellow highlight
            lines.append(f"> =={prefix_str}{text}==")
        else:
            # No markdown color syntax — label with the color name
            lines.append(f"> [{color}] {prefix_str}{text}")

    else:   # comment / reading note
        if text:
            # The annotated passage shown as a blockquote
            quoted = "\n> ".join(text.splitlines())
            lines.append(f"> {prefix_str}{quoted}")
            lines.append("")
        if note:
            lines.append(f"**Note:** {note}")

    if source:
        lines.append(f"*{source}*")

    return lines


# ---------------------------------------------------------------------------
# Build the Obsidian output note
# ---------------------------------------------------------------------------
def build_output(comments, highlights, footnote_map, footnote_order,
                 title, author, tags_list, nav, related_list, today,
                 include_footnotes, include_highlights):
    """
    Render the full Obsidian markdown note from the extracted artifacts.

    Sections:
      1. Frontmatter + MOC backlink + title
      2. ## Highlights and Notes  (unified, interleaved, document order)
      3. ## Footnotes             (optional, only if include_footnotes and footnotes exist)
      4. ## Related Notes
    """
    unified = merge_entries(comments, highlights if include_highlights else [])

    n_comments  = len([c for c in comments if c["comment_text"]])
    n_footnotes = len(footnote_map)
    n_yellow    = len([h for h in highlights if h["color"] == "yellow"])
    n_green     = len([h for h in highlights if h["color"] == "green"])

    lines = []

    # --- Frontmatter ---
    lines.append("---")
    lines.append(f'title: "{title}"')
    lines.append(f'author: "{author}"')
    lines.append("tags:")
    for tag in tags_list:
        lines.append(f"  - {tag.strip()}")
    lines.append(f'nav: "[[{nav}]]"')
    lines.append(f"created: {today}")
    lines.append("---")
    lines.append("")

    # --- MOC backlink ---
    lines.append(f"[[{nav}]]")
    lines.append("")

    # --- Title and summary ---
    lines.append(f"# {title}")
    lines.append("")
    summary_parts = [f"{n_comments} reading notes"]
    if include_footnotes and n_footnotes:
        summary_parts.append(f"{n_footnotes} footnotes")
    if include_highlights:
        summary_parts.append(f"{n_yellow} yellow highlights, {n_green} green highlights")
    lines.append(f"*Extracted from annotated DOCX — {', '.join(summary_parts)}.*")
    lines.append("")
    lines.append("---")
    lines.append("")

    # -----------------------------------------------------------------------
    # Unified section: highlights and notes interleaved in document order
    # -----------------------------------------------------------------------
    lines.append("## Highlights and Notes")
    lines.append("")
    lines.append("*All highlights and reading notes in document order.*")
    lines.append("")

    for entry in unified:
        lines.extend(render_entry(entry))
        lines.append("")
        lines.append("---")
        lines.append("")

    # -----------------------------------------------------------------------
    # Footnotes (optional)
    # -----------------------------------------------------------------------
    if include_footnotes and footnote_map:
        lines.append("## Footnotes")
        lines.append("")
        lines.append(
            "*Book citations as they appear in the text. "
            "Diacritical marks preserved from source.*"
        )
        lines.append("")
        seen = set()   # footnotes already written (avoid duplicates)
        n = 1
        for fid in footnote_order:
            if fid in seen or fid not in footnote_map:
                continue
            seen.add(fid)
            lines.append(f"{n}. {footnote_map[fid]}")
            n += 1
        for fid in sorted(footnote_map, key=lambda x: int(x)):
            if fid not in seen:
                lines.append(f"{n}. {footnote_map[fid]}")
                n += 1
        lines.append("")

    # -----------------------------------------------------------------------
    # Related Notes
    # -----------------------------------------------------------------------
    lines.append("## Related Notes")
    lines.append("")
    lines.append(f"- [[{nav}]]")
    for related in related_list:
        r = related.strip()
        if r:
            lines.append(f"- [[{r}]]")
    lines.append("")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Session divider for append mode
# ---------------------------------------------------------------------------
def make_session_divider(today, n_comments, n_yellow, n_green):
    """
    Return the markdown session divider to prepend when appending to an existing note.
    """
    parts = [f"{n_comments} reading notes"]
    if n_yellow:
        parts.append(f"{n_yellow} yellow highlights")
    if n_green:
        parts.append(f"{n_green} green highlights")
    return f"\n---\n*Session {today} — {', '.join(parts)}*\n---\n\n"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Extract reading notes and highlights from an annotated DOCX to an Obsidian note."
    )
    parser.add_argument("--docx",   required=True,  help="Path to the source DOCX file")
    parser.add_argument("--out",    required=True,  help="Path for the output .md file")
    parser.add_argument("--title",  required=True,  help="Book/document title for frontmatter and heading")
    parser.add_argument("--author", required=True,  help="Author name for frontmatter")
    parser.add_argument("--nav",    required=True,  help="MOC name for nav property (without [[ ]])")
    parser.add_argument("--tags",    default="BookClippings",
                        help="Comma-separated tags (default: BookClippings)")
    parser.add_argument("--related", default="",
                        help="Comma-separated related note names for Related Notes section")
    parser.add_argument("--no-footnotes",  action="store_true",
                        help="Skip the footnotes section even if footnotes.xml is present")
    parser.add_argument("--no-highlights", action="store_true",
                        help="Skip highlight extraction")
    parser.add_argument("--append", action="store_true",
                        help="Append to existing note with session divider instead of overwriting")
    args = parser.parse_args()

    tags_list    = [t.strip() for t in args.tags.split(",")    if t.strip()]
    related_list = [r.strip() for r in args.related.split(",") if r.strip()]
    include_footnotes  = not args.no_footnotes
    include_highlights = not args.no_highlights
    today = datetime.today().strftime("%Y-%m-%d")

    print(f"Opening: {args.docx}")
    with zipfile.ZipFile(args.docx) as z:
        comment_map  = load_comments(z)
        footnote_map = load_footnotes(z) if include_footnotes else {}
        with z.open("word/document.xml") as f:
            doc_tree = ET.parse(f)

    print(f"  Comments loaded  : {len(comment_map)}")
    print(f"  Footnotes loaded : {len(footnote_map)}")

    body = doc_tree.getroot().find(f".//{wt('body')}")
    comments, highlights, footnote_order = extract_from_document(
        body, comment_map, extract_highlights=include_highlights
    )

    n_yellow = len([h for h in highlights if h["color"] == "yellow"])
    n_green  = len([h for h in highlights if h["color"] == "green"])
    n_notes  = len([c for c in comments if c["comment_text"]])
    print(f"  Reading notes    : {n_notes}")
    print(f"  Yellow highlights: {n_yellow}")
    print(f"  Green highlights : {n_green}")

    # Preview first 3 unified entries to confirm structure
    print("\n--- Sample (first 3 unified entries) ---")
    unified_preview = merge_entries(comments, highlights if include_highlights else [])
    for e in unified_preview[:3]:
        print(f"  [{e['type']:9}] para={e['para']:4d}  prefix={e['para_prefix']!r:8}")
        print(f"    text  : {e['text'][:70]!r}")
        print(f"    source: {e['source'][:70]!r}")

    output = build_output(
        comments, highlights, footnote_map, footnote_order,
        title=args.title, author=args.author,
        tags_list=tags_list, nav=args.nav, related_list=related_list,
        today=today,
        include_footnotes=include_footnotes,
        include_highlights=include_highlights,
    )

    out_path = Path(args.out)
    if args.append and out_path.exists():
        existing   = out_path.read_text(encoding="utf-8")
        divider    = make_session_divider(today, n_notes, n_yellow, n_green)
        body_start = output.find("## Highlights and Notes")
        if body_start == -1:
            body_start = 0
        session_body = divider + output[body_start:]
        out_path.write_text(existing.rstrip() + "\n\n" + session_body, encoding="utf-8")
        print(f"\nAppended session to: {args.out}")
    else:
        out_path.write_text(output, encoding="utf-8")
        print(f"\nWritten: {args.out}")

    print(f"  Total chars: {len(output):,}")


if __name__ == "__main__":
    main()
