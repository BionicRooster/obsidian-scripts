---
name: libreoffice
description: LibreOffice install status and path on this machine — used by pdf_to_obsidian.py for RTF and .pages conversion
metadata: 
  node_type: memory
  type: project
  originSessionId: bccc7b11-2750-4e17-9a51-8891aae0db7c
---

LibreOffice is installed and active at `C:\Program Files\LibreOffice\program\soffice.exe` (confirmed 2026-05-23).

This is the first entry in `LIBREOFFICE_PATHS` (line 1158–1164 of `pdf_to_obsidian.py`), so `_find_libreoffice()` will find it automatically — no code changes required.

**Impact on conversions:**
- `.rtf` files: LibreOffice path is now taken (full fidelity, images preserved); `striprtf` text-only fallback is no longer needed
- `.pages` files: LibreOffice fallback (Strategy 2 in `convert_pages()`) is now available if a `.pages` ZIP contains no `preview.pdf`
- No configuration changes needed in `pdf_to_obsidian.py`

**Why:** User confirmed installation 2026-05-23; previously the watcher had to fall back to striprtf for RTF files and could not convert Pages files without an embedded preview PDF.
