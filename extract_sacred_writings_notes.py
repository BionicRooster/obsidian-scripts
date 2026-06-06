# -*- coding: utf-8 -*-
"""
Extract Wayne's reading notes and highlighted passages from
  Baha'i Sacred Writings - WT Notes R3.docx

Artifacts extracted:
  1. Reading Notes (24 Word comments by Wayne Talbot, paired with annotated text)
  2. Yellow highlights (primary key passages)
  3. Green highlights (secondary key passages)

Output: D:\\Obsidian\\Main\\09 - Kindle Clippings\\BahaiSacredWritings-WT-Notes.md
"""
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime

# Force UTF-8 on stdout so Windows cp1252 terminal does not choke on diacriticals
sys.stdout.reconfigure(encoding="utf-8", errors="replace")


# ---------------------------------------------------------------------------
# Text cleanup — fix DOCX word-wrap concatenation artifact
# ---------------------------------------------------------------------------
def fix_missing_spaces(text):
    """
    In DOCX, adjacent <w:t> runs are joined without spaces, so a sentence
    ending in a period can directly abut the next word:
        "Baha'u'llah.He arrived"  →  "Baha'u'llah. He arrived"

    Rules applied:
      • Period / ! / ? before an uppercase letter → insert space
        (avoids false positives on decimals, abbreviations, URLs)
      • Comma / semicolon before any letter → insert space
        (safe in prose context)
    """
    # Sentence-end punctuation before uppercase (including Latin Extended)
    text = re.sub(r'([.!?])([A-ZÀ-ɏ])', r'\1 \2', text)
    # Comma or semicolon before any letter
    text = re.sub(r'([,;])([A-Za-zÀ-ɏ])', r'\1 \2', text)
    return text


# ---------------------------------------------------------------------------
# Paths — build with chr() to avoid source-file encoding issues
# ---------------------------------------------------------------------------
# Standard apostrophe U+0027 is used in the filesystem folder name (confirmed by probe)
APOSTROPHE = chr(0x27)   # standard apostrophe '
ACUTE_A    = chr(0xE1)   # á
ACUTE_I    = chr(0xED)   # í
BAHAI_FS   = "Bah" + ACUTE_A + APOSTROPHE + ACUTE_I   # Bahá'í — filesystem version

# Source DOCX path
DOCX_PATH = (
    "C:\\Users\\awt\\Sync\\" + BAHAI_FS +
    "\\Word\\" + BAHAI_FS +
    " Sacred Writings - WT Notes R3.docx"
)

# Destination vault note path
OUT_PATH = (
    "D:\\Obsidian\\Main\\09 - Kindle Clippings\\"
    "BahaiSacredWritings-WT-Notes.md"
)

# ---------------------------------------------------------------------------
# Word XML namespace constant
# ---------------------------------------------------------------------------
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

def wt(n):
    """Return Clark-notation tag for the Word main namespace."""
    return f"{{{W}}}{n}"


# ---------------------------------------------------------------------------
# Load word/comments.xml  →  dict[id → {author, date, text}]
# ---------------------------------------------------------------------------
def load_comments(z):
    """
    Parse comments.xml and return a dict keyed by comment ID (string).
    Each value has: author, date, text (all <w:t> runs concatenated).
    """
    with z.open("word/comments.xml") as f:
        tree = ET.parse(f)
    cmap = {}   # dict mapping comment id string → metadata dict
    for c in tree.getroot().findall(wt("comment")):
        cid    = c.get(wt("id"))          # comment ID string
        author = c.get(wt("author"), "")  # name of commenter
        date   = c.get(wt("date"), "")    # ISO date string
        # Concatenate all <w:t> text nodes inside this comment element
        texts  = [t.text or "" for t in c.iter(wt("t"))]
        cmap[cid] = {
            "author": author,
            "date":   date,
            "text":   "".join(texts).strip(),
        }
    return cmap


# ---------------------------------------------------------------------------
# Walk document.xml body to extract:
#   • Commented text ranges (commentRangeStart / commentRangeEnd pairs)
#   • Highlighted runs (yellow and green)
# ---------------------------------------------------------------------------
def extract_from_document(body, comment_map):
    """
    Recursive DFS over the document body element.

    Returns:
        comments_ordered — list of dicts in document order:
                           {id, para, commented_text, comment_text, author}
        highlights       — list of dicts in document order:
                           {color, text, para}
    """
    open_ids       = {}   # id → list[str]  text accumulator while comment range is open
    closed_results = {}   # id → {para, commented_text}
    comment_order  = []   # comment IDs appended when each range closes
    para_num       = [0]  # mutable paragraph counter (list so nested fn can mutate)

    # Highlight state for the current paragraph
    # We reset per paragraph to avoid merging across paragraph boundaries
    hi_results     = []   # all collected highlight passages in document order

    # Highlight accumulator state (reset on paragraph boundary)
    cur_hi_color   = [None]    # current highlight color being accumulated
    cur_hi_chunks  = [[]]      # text chunks for current highlight run

    def flush_highlight():
        """Save the current accumulated highlight run to hi_results."""
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

        # Increment paragraph counter each time we enter a new <w:p>
        # Also flush any open highlight run (highlights don't cross paragraphs)
        if tag == wt("p"):
            flush_highlight()
            para_num[0] += 1

        # Open a comment annotation range
        if tag == wt("commentRangeStart"):
            cid = elem.get(wt("id"))
            if cid is not None and cid not in open_ids:
                open_ids[cid] = []   # start accumulating text for this comment range

        # Close a comment annotation range
        elif tag == wt("commentRangeEnd"):
            cid = elem.get(wt("id"))
            if cid is not None and cid in open_ids:
                commented = "".join(open_ids.pop(cid)).strip()
                closed_results[cid] = {
                    "para":           para_num[0],
                    "commented_text": commented,
                }
                comment_order.append(cid)

        # Handle a text run <w:r> — check for highlight property
        elif tag == wt("r"):
            # Determine highlight color for this run (None if not highlighted)
            rpr         = elem.find(wt("rPr"))          # run properties element
            hi_elem     = rpr.find(wt("highlight")) if rpr is not None else None
            this_color  = hi_elem.get(wt("val")) if hi_elem is not None else None

            # Collect run text from all <w:t> children of this run
            run_text = "".join(t.text or "" for t in elem.findall(wt("t")))

            # Feed text into every currently open comment range accumulator
            for cid in list(open_ids.keys()):
                open_ids[cid].append(run_text)

            # Manage highlight accumulation
            if this_color is not None and run_text:
                if this_color == cur_hi_color[0]:
                    # Extend the current same-color highlight run
                    cur_hi_chunks[0].append(run_text)
                else:
                    # Different color — flush the previous run, start a new one
                    flush_highlight()
                    cur_hi_color[0]  = this_color
                    cur_hi_chunks[0] = [run_text]
            else:
                # Non-highlighted run — flush any pending highlight
                flush_highlight()

            # Do NOT recurse further into <w:r> — we already handled all <w:t> above
            return

        # Collect plain text runs from <w:t> only when NOT inside a <w:r>
        # (handles edge cases like hyperlinks with <w:t> outside normal <w:r>)
        elif tag == wt("t"):
            chunk = elem.text or ""
            for cid in list(open_ids.keys()):
                open_ids[cid].append(chunk)

        # Recurse into all children in document order
        for child in elem:
            recurse(child)

    recurse(body)
    flush_highlight()   # flush any trailing highlight at document end

    # Merge comment positions with comment text from comments.xml
    # Apply fix_missing_spaces() to repair word-wrap join artifacts
    merged_comments = []
    for cid in comment_order:
        pos   = closed_results[cid]
        cinfo = comment_map.get(cid, {})
        merged_comments.append({
            "id":             cid,
            "para":           pos["para"],
            "commented_text": fix_missing_spaces(pos["commented_text"]),
            "comment_text":   fix_missing_spaces(cinfo.get("text", "")),
            "author":         cinfo.get("author", ""),
        })

    # Surface any point comments (no range — just a commentReference anchor)
    range_ids = set(comment_order)
    for cid, cinfo in comment_map.items():
        if cid not in range_ids:
            merged_comments.append({
                "id":             cid,
                "para":           999999,   # sort to end; position unknown
                "commented_text": "",
                "comment_text":   fix_missing_spaces(cinfo.get("text", "")),
                "author":         cinfo.get("author", ""),
            })

    # Sort by paragraph then comment ID (numeric)
    merged_comments.sort(key=lambda x: (x["para"], int(x["id"])))

    return merged_comments, hi_results


# ---------------------------------------------------------------------------
# Format the Obsidian output note
# ---------------------------------------------------------------------------
def build_output(comments, highlights, today):
    """
    Render the full Obsidian markdown note.

    Sections:
      1. Frontmatter
      2. ## Reading Notes  (comments paired with annotated text)
      3. ## Highlighted Passages — Yellow
      4. ## Highlighted Passages — Green
    """
    # Build diacritic-safe display strings using chr()
    rsquo      = chr(0x2019)                              # RIGHT SINGLE QUOTATION MARK
    acute_a    = chr(0xE1)                                # á
    acute_i    = chr(0xED)                                # í
    baha_i     = "Bah" + acute_a + rsquo + acute_i       # Bahá'í (display, curly quote)
    bahaullah  = "Bah" + acute_a + rsquo + "u" + rsquo + "ll" + acute_a + "h"  # Bahá'u'lláh

    # Statistics
    n_comments  = len([c for c in comments if c["comment_text"]])
    n_yellow    = len([h for h in highlights if h["color"] == "yellow"])
    n_green     = len([h for h in highlights if h["color"] == "green"])

    lines = []

    # --- Frontmatter ---
    lines.append("---")
    lines.append(f'title: "{baha_i} Sacred Writings — Reading Notes"')
    lines.append('author: "Wayne Talbot (annotator)"')
    lines.append("tags:")
    lines.append("  - BookClippings")
    lines.append("  - Bahai")
    lines.append("  - BahaiScripture")
    lines.append(f'nav: "[[MOC - {baha_i} Faith]]"')
    lines.append(f"created: {today}")
    lines.append("---")
    lines.append("")

    # --- Backlink ---
    lines.append(f"[[MOC - {baha_i} Faith]]")
    lines.append("")

    # --- Title and summary ---
    lines.append(f"# {baha_i} Sacred Writings — Reading Notes")
    lines.append("")
    lines.append(
        f"*Extracted from annotated DOCX (WT Notes R3) — "
        f"{n_comments} reading notes, "
        f"{n_yellow} yellow highlights, "
        f"{n_green} green highlights.*"
    )
    lines.append("")
    lines.append("---")
    lines.append("")

    # -----------------------------------------------------------------------
    # Section 1: Reading Notes (comments)
    # -----------------------------------------------------------------------
    lines.append("## Reading Notes")
    lines.append("")
    lines.append("*Wayne's marginal notes, each paired with the passage it annotates.*")
    lines.append("")

    for c in comments:
        ct = c["commented_text"]   # the text Wayne highlighted/annotated in the document
        nt = c["comment_text"]     # Wayne's note about that text
        if not nt:
            continue   # skip entries with no note text

        if ct:
            # Render annotated passage as a blockquote (handle multi-line)
            quoted = "\n> ".join(ct.splitlines())
            lines.append(f"> {quoted}")
            lines.append("")

        lines.append(f"**Note:** {nt}")
        lines.append("")
        lines.append("---")
        lines.append("")

    # -----------------------------------------------------------------------
    # Section 2: Yellow Highlights
    # -----------------------------------------------------------------------
    lines.append("## Highlighted Passages — Yellow")
    lines.append("")
    lines.append(
        "*Primary highlights — key passages marked in yellow.*"
    )
    lines.append("")

    for h in highlights:
        if h["color"] != "yellow":
            continue
        quoted = "\n> ".join(h["text"].splitlines())
        lines.append(f"> {quoted}")
        lines.append("")

    # -----------------------------------------------------------------------
    # Section 3: Green Highlights
    # -----------------------------------------------------------------------
    lines.append("## Highlighted Passages — Green")
    lines.append("")
    lines.append(
        "*Secondary highlights — passages marked in green.*"
    )
    lines.append("")

    for h in highlights:
        if h["color"] != "green":
            continue
        quoted = "\n> ".join(h["text"].splitlines())
        lines.append(f"> {quoted}")
        lines.append("")

    # -----------------------------------------------------------------------
    # Related Notes
    # -----------------------------------------------------------------------
    lines.append("## Related Notes")
    lines.append("")
    lines.append(f"- [[MOC - {baha_i} Faith]]")
    lines.append(f"- [[{baha_i} Sacred Writings - {baha_i} Reference Library]]")
    lines.append("")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    today = datetime.today().strftime("%Y-%m-%d")

    print(f"Opening: {DOCX_PATH}")
    with zipfile.ZipFile(DOCX_PATH) as z:
        comment_map = load_comments(z)

        with z.open("word/document.xml") as f:
            doc_tree = ET.parse(f)

    print(f"  comments.xml entries : {len(comment_map)}")

    body = doc_tree.getroot().find(f".//{wt('body')}")
    comments, highlights = extract_from_document(body, comment_map)

    # Summarise what was extracted
    n_yellow = len([h for h in highlights if h["color"] == "yellow"])
    n_green  = len([h for h in highlights if h["color"] == "green"])
    print(f"  Reading notes placed : {len([c for c in comments if c['para'] < 999999])}")
    print(f"  Point comments       : {len([c for c in comments if c['para'] == 999999])}")
    print(f"  Yellow highlights    : {n_yellow}")
    print(f"  Green highlights     : {n_green}")

    # Sample: first 3 reading notes
    print("\n--- Sample reading notes ---")
    for c in [c for c in comments if c["comment_text"]][:3]:
        print(f"  [{c['id']}] para={c['para']}")
        print(f"    annotated: {c['commented_text'][:70]!r}")
        print(f"    note:      {c['comment_text'][:70]!r}")

    # Sample: first 3 yellow highlights
    print("\n--- Sample yellow highlights ---")
    for h in [h for h in highlights if h["color"] == "yellow"][:3]:
        print(f"  para={h['para']}: {h['text'][:80]!r}")

    # Build and write the output note
    output = build_output(comments, highlights, today)
    with open(OUT_PATH, "w", encoding="utf-8") as fh:
        fh.write(output)

    print(f"\nWritten: {OUT_PATH}")
    print(f"  Total chars: {len(output):,}")


if __name__ == "__main__":
    main()
