# -*- coding: utf-8 -*-
"""Quick inspection of DOCX annotation parts."""
import zipfile
import sys

# Build path using char codes to avoid encoding issues in script source
path = (
    "D:\\Documents\\Baha'i\\Books 'Abdul Bah"
    + chr(0xE1)
    + "\\light-of-the-world-full-diacritics.docx"
)

with zipfile.ZipFile(path) as z:
    names = z.namelist()
    print("Word parts:")
    for n in sorted(names):
        if n.startswith("word/"):
            info = z.getinfo(n)
            print(f"  {n}  ({info.file_size:,} bytes)")
