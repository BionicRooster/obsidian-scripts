# -*- coding: utf-8 -*-
"""
Extract reading notes (comments) and footnotes from
Light of the World DOCX and write an Obsidian clippings note.

Output: D:\\Obsidian\\Main\\09 - Kindle Clippings\\AbdulBaha-Light-of-the-World.md
"""
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime

# Force UTF-8 on stdout so Windows cp1252 terminal doesn't choke on diacriticals
sys.stdout.reconfigure(encoding="utf-8", errors="replace")


# ---------------------------------------------------------------------------
# Text cleanup — fix DOCX word-wrap concatenation artifact
# ---------------------------------------------------------------------------
def fix_missing_spaces(text):
    """
    In DOCX, adjacent <w:t> runs are concatenated without spaces, so
    a sentence ending in a period can directly abut the next word:
        "Bahá'u'lláh.He arrived" → "Bahá'u'lláh. He arrived"

    Strategy: insert a space after sentence-ending punctuation (.!?)
    when followed directly by an uppercase letter (including Latin Extended
    diacriticals U+00C0–U+024F).  Uppercase-only trigger avoids false
    positives on decimal numbers (3.14), lowercase-start URLs
    (bahai-library.com), and most abbreviations.

    Also fixes comma/semicolon run-together before any letter:
        "one,two" → "one, two"
    which is safe in prose but would not affect numeric or URL content.
    """
    # Period / ! / ? immediately before an uppercase letter → insert space
    text = re.sub(r'([.!?])([A-ZÀ-ɏ])', r'\1 \2', text)
    # Comma / semicolon immediately before any letter → insert space
    text = re.sub(r'([,;])([A-Za-zÀ-ɏ])', r'\1 \2', text)
    return text


# ---------------------------------------------------------------------------
# Paths — build with chr() to avoid encoding issues in this source file
# ---------------------------------------------------------------------------
DOCX_PATH = (
    "D:\\Documents\\Baha'i\\Books 'Abdul Bah"
    + chr(0xE1)                          # á
    + "\\light-of-the-world-full-diacritics.docx"
)

# Vault clippings folder — 09 - Kindle Clippings
OUT_PATH = (
    "D:\\Obsidian\\Main\\09 - Kindle Clippings\\AbdulBah"
    + chr(0xE1)                          # á
    + "-Light-of-the-World.md"
)

# ---------------------------------------------------------------------------
# Word XML namespace constants
# ---------------------------------------------------------------------------
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

def wt(n):
    """Return Clark-notation tag for the Word main namespace."""
    return f"{{{W}}}{n}"


# ---------------------------------------------------------------------------
# Load word/comments.xml  →  dict[id → {author, date, text}]
# ---------------------------------------------------------------------------
def load_comments(z):
    with z.open("word/comments.xml") as f:
        tree = ET.parse(f)
    cmap = {}
    for c in tree.getroot().findall(wt("comment")):
        cid    = c.get(wt("id"))         # string ID
        author = c.get(wt("author"), "")
        date   = c.get(wt("date"), "")
        # Concatenate all <w:t> text runs inside the comment
        texts  = [t.text or "" for t in c.iter(wt("t"))]
        cmap[cid] = {
            "author": author,
            "date":   date,
            "text":   "".join(texts).strip(),
        }
    return cmap


# ---------------------------------------------------------------------------
# Load word/footnotes.xml  →  dict[id → text]
# ---------------------------------------------------------------------------
def load_footnotes(z):
    with z.open("word/footnotes.xml") as f:
        tree = ET.parse(f)
    # These special types are structural placeholders, not real footnotes
    skip = {"separator", "continuationSeparator", "continuationNotice"}
    fmap = {}
    for fn in tree.getroot().findall(wt("footnote")):
        if fn.get(wt("type"), "") in skip:
            continue
        fid   = fn.get(wt("id"))        # string ID
        texts = [t.text or "" for t in fn.iter(wt("t"))]
        fmap[fid] = fix_missing_spaces("".join(texts).strip())
    return fmap


# ---------------------------------------------------------------------------
# Walk document.xml body to extract:
#   • Commented text — text bracketed by commentRangeStart / commentRangeEnd
#   • Footnote reference order — order they appear in the document
# ---------------------------------------------------------------------------
def extract_from_document(body, comment_map):
    """
    Recursive DFS over the document body element.
    Returns:
        comments_ordered — list of dicts in document order, each with:
                           {id, para, commented_text, comment_text, author}
        footnote_order   — list of footnote ID strings in document order
    """
    open_ids       = {}   # id → list[str]  text accumulator while range is open
    closed_results = {}   # id → {para, commented_text}
    comment_order  = []   # IDs appended when each range closes
    footnote_order = []   # footnote IDs in document order
    para_num       = [0]  # mutable int for nonlocal access in nested function

    def recurse(elem):
        tag = elem.tag

        # Increment paragraph counter each time we enter a new <w:p>
        if tag == wt("p"):
            para_num[0] += 1

        # Open a comment annotation range
        if tag == wt("commentRangeStart"):
            cid = elem.get(wt("id"))
            if cid is not None and cid not in open_ids:
                open_ids[cid] = []          # begin accumulating text for this comment

        # Close a comment annotation range
        elif tag == wt("commentRangeEnd"):
            cid = elem.get(wt("id"))
            if cid is not None and cid in open_ids:
                # Join all accumulated text chunks for this range
                commented = "".join(open_ids.pop(cid)).strip()
                closed_results[cid] = {
                    "para":           para_num[0],
                    "commented_text": commented,
                }
                comment_order.append(cid)

        # Collect a footnote reference marker (order matters, not content)
        elif tag == wt("footnoteReference"):
            fid = elem.get(wt("id"))
            if fid:
                footnote_order.append(fid)

        # Accumulate text into every currently open comment range
        elif tag == wt("t"):
            chunk = elem.text or ""
            for cid in list(open_ids.keys()):
                open_ids[cid].append(chunk)

        # Recurse into all children in document order
        for child in elem:
            recurse(child)

    recurse(body)

    # Merge position data with comment text from comments.xml
    # Apply fix_missing_spaces() to both fields to repair DOCX word-wrap artifacts
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

    # Also surface any comments in comment_map that never had a range
    # (point comments with no range selection — appear as commentReference only)
    range_ids = set(comment_order)
    for cid, cinfo in comment_map.items():
        if cid not in range_ids:
            merged_comments.append({
                "id":             cid,
                "para":           999999,    # sort to end; we don't know position
                "commented_text": "",
                "comment_text":   fix_missing_spaces(cinfo.get("text", "")),
                "author":         cinfo.get("author", ""),
            })

    # Sort by paragraph number (range comments already ordered; appends go last)
    merged_comments.sort(key=lambda x: (x["para"], int(x["id"])))

    return merged_comments, footnote_order


# ---------------------------------------------------------------------------
# Format the Obsidian output note
# ---------------------------------------------------------------------------
def build_output(comments, footnote_map, footnote_order, today):
    # Build diacritic-safe strings using chr()
    ayn         = chr(0x2018)           # LEFT SINGLE QUOTATION MARK ʻ
    acute_a     = chr(0xE1)             # á
    acute_i     = chr(0xED)             # í
    rsquo       = chr(0x2019)           # '
    baha_i      = "Bah" + acute_a + rsquo + chr(0xED)  # Bahá'í
    abdul_baha  = ayn + "Abdu" + rsquo + "l-Bah" + acute_a   # 'Abdu'l-Bahá
    bahaullah   = "Bah" + acute_a + rsquo + "u" + rsquo + "ll" + acute_a + "h"

    n_comments  = len([c for c in comments if c["comment_text"]])
    n_footnotes = len(footnote_map)

    lines = []

    # --- Frontmatter ---
    lines.append("---")
    lines.append('title: "Light of the World"')
    lines.append(f'author: "{abdul_baha}"')
    lines.append("tags:")
    lines.append("  - BookClippings")
    lines.append("  - Bahai")
    lines.append("  - AbdulBaha")
    lines.append(f'nav: "[[MOC - {baha_i} Faith]]"')
    lines.append(f"created: {today}")
    lines.append("---")
    lines.append("")

    # --- Title and summary ---
    lines.append(f"# Light of the World — Reading Notes")
    lines.append("")
    lines.append(
        f"*Source: {abdul_baha}. "
        f"Extracted from annotated DOCX — "
        f"{n_comments} reading notes, {n_footnotes} footnotes.*"
    )
    lines.append("")
    lines.append("---")
    lines.append("")

    # --- Section 1: Reading Notes (comments) ---
    lines.append("## Reading Notes")
    lines.append("")

    for c in comments:
        ct = c["commented_text"]
        nt = c["comment_text"]
        if not nt:
            continue   # skip empty notes

        if ct:
            # Indent multi-line quoted text properly for Obsidian blockquote
            quoted = "\n> ".join(ct.splitlines())
            lines.append(f"> {quoted}")
            lines.append("")

        lines.append(f"**Note:** {nt}")
        lines.append("")
        lines.append("---")
        lines.append("")

    # --- Section 2: Footnotes ---
    lines.append("## Footnotes")
    lines.append("")
    lines.append(
        "*Book citations as they appear in the text. "
        "Diacritical marks preserved from source.*"
    )
    lines.append("")

    seen = set()
    n = 1
    # First, footnotes in document order
    for fid in footnote_order:
        if fid in seen or fid not in footnote_map:
            continue
        seen.add(fid)
        lines.append(f"{n}. {footnote_map[fid]}")
        n += 1

    # Any footnotes not reached by the order scan (shouldn't normally happen)
    for fid in sorted(footnote_map, key=lambda x: int(x)):
        if fid not in seen:
            lines.append(f"{n}. {footnote_map[fid]}")
            n += 1

    lines.append("")
    lines.append("## Related Notes")
    lines.append("")
    lines.append(f"- [[MOC - {baha_i} Faith]]")
    lines.append(f"- [[{abdul_baha}]]")
    lines.append("")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    today = datetime.today().strftime("%Y-%m-%d")

    print(f"Opening: {DOCX_PATH}")
    with zipfile.ZipFile(DOCX_PATH) as z:
        comment_map  = load_comments(z)
        footnote_map = load_footnotes(z)
        with z.open("word/document.xml") as f:
            doc_tree = ET.parse(f)

    print(f"  comments.xml entries : {len(comment_map)}")
    print(f"  footnotes.xml entries: {len(footnote_map)}")

    body = doc_tree.getroot().find(f".//{wt('body')}")
    comments, footnote_order = extract_from_document(body, comment_map)

    print(f"  Comments placed in doc order : {len([c for c in comments if c['para'] < 999999])}")
    print(f"  Point comments (no range)    : {len([c for c in comments if c['para'] == 999999])}")
    print(f"  Footnote refs in doc order   : {len(footnote_order)}")

    # Sample: show first 5 comments
    print("\n--- Sample comments ---")
    for c in comments[:5]:
        print(f"  [{c['id']}] para={c['para']}")
        print(f"    commented: {c['commented_text'][:70]!r}")
        print(f"    note:      {c['comment_text'][:70]!r}")

    # Build and write output
    output = build_output(comments, footnote_map, footnote_order, today)
    with open(OUT_PATH, "w", encoding="utf-8") as fh:
        fh.write(output)

    print(f"\nWritten: {OUT_PATH}")
    print(f"  Total chars: {len(output):,}")


if __name__ == "__main__":
    main()
