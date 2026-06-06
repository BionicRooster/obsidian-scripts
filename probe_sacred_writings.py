# -*- coding: utf-8 -*-
"""
Probe the Baha'i Sacred Writings DOCX to report what extraction artifacts are present:
  - comments.xml  (reader annotations)
  - footnotes.xml (source citations)
  - highlighted runs in document.xml (<w:highlight>)
  - tracked changes, etc.

Prints a summary so we know what to extract.
"""
import sys
import zipfile
import xml.etree.ElementTree as ET

# Force UTF-8 on stdout to handle diacritical output on Windows cp1252 terminal
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Build path using chr() to avoid encoding issues with diacriticals in source file
# Path: C:\Users\awt\Sync\Bahá'í\Word\Bahá'í Sacred Writings - WT Notes R3.docx
#   á = chr(0xE1), ' (standard apostrophe U+0027) = chr(0x27), í = chr(0xED)
BAHAI = "Bah" + chr(0xE1) + chr(0x27) + chr(0xED)   # Bahá'í with standard apostrophe
DOCX_PATH = (
    "C:\\Users\\awt\\Sync\\" + BAHAI +
    "\\Word\\" + BAHAI +
    " Sacred Writings - WT Notes R3.docx"
)

# Word XML namespace
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

def wt(n):
    """Return Clark-notation tag for the Word main namespace."""
    return f"{{{W}}}{n}"

print(f"Probing: {DOCX_PATH}")
print()

with zipfile.ZipFile(DOCX_PATH) as z:
    # List all files in the zip
    names = z.namelist()
    print("=== DOCX Contents (word/ folder) ===")
    for n in sorted(names):
        if n.startswith("word/"):
            print(f"  {n}")
    print()

    # --- Check comments.xml ---
    if "word/comments.xml" in names:
        with z.open("word/comments.xml") as f:
            tree = ET.parse(f)
        comments = tree.getroot().findall(wt("comment"))
        # Sample first 3 comments
        print(f"=== comments.xml: {len(comments)} comment(s) ===")
        for c in comments[:5]:
            cid    = c.get(wt("id"))
            author = c.get(wt("author"), "")
            texts  = [t.text or "" for t in c.iter(wt("t"))]
            text   = "".join(texts).strip()[:120]
            print(f"  [{cid}] by '{author}': {text!r}")
        print()
    else:
        print("=== NO comments.xml found ===\n")

    # --- Check footnotes.xml ---
    if "word/footnotes.xml" in names:
        with z.open("word/footnotes.xml") as f:
            tree = ET.parse(f)
        skip = {"separator", "continuationSeparator", "continuationNotice"}
        footnotes = [
            fn for fn in tree.getroot().findall(wt("footnote"))
            if fn.get(wt("type"), "") not in skip
        ]
        print(f"=== footnotes.xml: {len(footnotes)} footnote(s) ===")
        for fn in footnotes[:5]:
            fid   = fn.get(wt("id"))
            texts = [t.text or "" for t in fn.iter(wt("t"))]
            text  = "".join(texts).strip()[:120]
            print(f"  [{fid}]: {text!r}")
        print()
    else:
        print("=== NO footnotes.xml found ===\n")

    # --- Check for highlights in document.xml ---
    if "word/document.xml" in names:
        with z.open("word/document.xml") as f:
            tree = ET.parse(f)
        # Highlighted runs have <w:rPr><w:highlight w:val="..."/></w:rPr>
        highlights = tree.getroot().findall(f".//{wt('highlight')}")
        print(f"=== Highlight runs in document.xml: {len(highlights)} ===")
        if highlights:
            # Show distinct highlight colors used
            colors = set(h.get(wt("val"), "unknown") for h in highlights)
            print(f"  Colors used: {sorted(colors)}")
        print()

    # --- Count paragraphs ---
    if "word/document.xml" in names:
        paras = tree.getroot().findall(f".//{wt('p')}")
        print(f"=== Total paragraphs in document: {len(paras)} ===")
