# -*- coding: utf-8 -*-
"""Peek at comments and footnotes structure to guide extractor design."""
import zipfile
import xml.etree.ElementTree as ET

path = (
    "D:\\Documents\\Baha'i\\Books 'Abdul Bah"
    + chr(0xE1)
    + "\\light-of-the-world-full-diacritics.docx"
)

W  = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W14 = "http://schemas.microsoft.com/office/word/2010/wordml"
W15 = "http://schemas.microsoft.com/office/word/2012/wordml"
W16CPR = "http://schemas.microsoft.com/office/word/2016/wordml/cid"

def wt(n): return f"{{{W}}}{n}"

with zipfile.ZipFile(path) as z:

    # --- comments.xml: show first 3 comments ---
    with z.open("word/comments.xml") as f:
        ctree = ET.parse(f)
    comments = ctree.getroot().findall(wt("comment"))
    print(f"Total comments: {len(comments)}\n")
    for c in comments[:3]:
        cid     = c.get(wt("id"))
        author  = c.get(wt("author"), "")
        date    = c.get(wt("date"), "")
        texts   = [t.text or "" for t in c.iter(wt("t"))]
        print(f"  id={cid}  author={author!r}  date={date}")
        print(f"  text: {''.join(texts)[:120]!r}")
        print()

    # --- footnotes.xml: show first 3 real footnotes ---
    with z.open("word/footnotes.xml") as f:
        ftree = ET.parse(f)
    footnotes = ftree.getroot().findall(wt("footnote"))
    print(f"Total footnote elements: {len(footnotes)}")
    real = [fn for fn in footnotes if fn.get(wt("type")) not in ("separator","continuationSeparator","continuationNotice")]
    print(f"Real footnotes: {len(real)}\n")
    for fn in real[:3]:
        fid = fn.get(wt("id"))
        texts = [t.text or "" for t in fn.iter(wt("t"))]
        print(f"  id={fid}  text: {''.join(texts)[:120]!r}")
        print()

    # --- commentsExtended.xml: peek for reply threading ---
    with z.open("word/commentsExtended.xml") as f:
        raw = f.read(500)
    print("commentsExtended snippet:")
    print(raw.decode("utf-8", errors="replace"))
