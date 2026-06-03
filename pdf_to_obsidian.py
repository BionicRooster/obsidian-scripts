"""
pdf_to_obsidian.py

Convert PDF files into Obsidian-flavoured Markdown notes.

Features:
  - Extracts all text, preserving headings detected by font-size heuristics
  - Detects tables (drawn with vector lines) and renders them as GFM pipe tables
  - Extracts embedded images and saves them to the vault's image folder
  - Handles two-column layouts (newsletters, academic papers)
  - Generates YAML frontmatter from PDF document metadata
  - Default mode: event-driven daemon that watches the vault root for new PDFs
  - Avoids overwriting existing notes (appends _2, _3, etc.)
  - Moves converted source PDFs to 09 - Attachments (never deletes/overwrites)
  - AI readability polish via Claude (skipped when idle — zero idle token usage)

Usage:
    python pdf_to_obsidian.py                    # WATCH MODE (default): daemon, drop PDFs in
    python pdf_to_obsidian.py --once             # scan vault root once and exit
    python pdf_to_obsidian.py --clippings        # output to 10 - Clippings instead
    python pdf_to_obsidian.py --file report.pdf  # single file (exits after)
    python pdf_to_obsidian.py --overwrite        # replace existing .md files

Watch mode log: C:\\Users\\awt\\pdf_watcher.log

Coding conventions (from CLAUDE.md):
  - Verbose commenting: every non-trivial variable is explained
  - UTF-8 encoding throughout; diacritical characters preserved
  - Smart apostrophes converted to straight in filenames
"""

import argparse        # command-line interface
import logging         # structured logging throughout the pipeline
import queue           # thread-safe queue for passing PDF paths from watcher thread to main thread
import re              # regular expressions for filename sanitisation
import shutil          # shutil.move() for relocating source PDFs
import statistics      # median() for body-font detection
import subprocess      # pip install call in _ensure_dependencies
import sys             # sys.exit, sys.executable
import time            # time.sleep() for file-settle delay and polling fallback
from pathlib import Path  # modern cross-platform path handling


# ---------------------------------------------------------------------------
# Logging — configured first so all downstream code shares the same format
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)

# log: module-level logger; child loggers for PageProcessor use __name__
log = logging.getLogger("pdf_to_obsidian")


# ---------------------------------------------------------------------------
# Vault / directory constants
# ---------------------------------------------------------------------------

# VAULT_ROOT: absolute path to the Obsidian vault
VAULT_ROOT = Path(r"D:\Obsidian\Main")

# IMAGES_DIR: where extracted images are saved (Obsidian resolves by filename)
IMAGES_DIR = VAULT_ROOT / "00 - Images"

# CLIPPINGS_DIR: optional output folder when --clippings flag is used
CLIPPINGS_DIR = VAULT_ROOT / "10 - Clippings"

# ATTACHMENTS_DIR: where source PDFs are moved after successful conversion
# The source file is never deleted or overwritten — it is relocated here
ATTACHMENTS_DIR = VAULT_ROOT / "09 - Attachments"

# SCAN_DIR: the directory scanned for PDFs in default (non-file) mode
# Only the root is scanned — subfolders are NOT traversed recursively
SCAN_DIR = VAULT_ROOT

# MIN_IMAGE_PX: images smaller than this in both dimensions are decorative
# (bullets, separator lines, etc.) and are skipped
MIN_IMAGE_PX = 32

# HEADING_RATIO_H1: font-size / body-font-size threshold for H1 detection
HEADING_RATIO_H1 = 1.6

# HEADING_RATIO_H2: threshold for H2
HEADING_RATIO_H2 = 1.3

# HEADING_RATIO_H3: threshold for H3
HEADING_RATIO_H3 = 1.1

# ---------------------------------------------------------------------------
# Watch-mode constants
# ---------------------------------------------------------------------------

# WATCH_LOG_FILE: dedicated log file written when running as a daemon
# Mirrors the pattern used by watch_prn_files.ps1 (prn_watcher.log)
WATCH_LOG_FILE = Path(r"C:\Users\awt\pdf_watcher.log")

# WATCH_STABLE_SECS: seconds to wait after a Created event before processing
# Gives Windows time to finish writing the file before we open it
WATCH_STABLE_SECS = 1.0

# WATCH_POLL_SECS: fallback polling interval used when watchdog is unavailable
# The main loop sleeps this long between directory scans
WATCH_POLL_SECS = 5

# PDF_DATE_RE: matches PDF metadata date strings like D:20240115120000+00'00'
PDF_DATE_RE = re.compile(r"D:(\d{4})(\d{2})(\d{2})")

# SMART_APOSTROPHE_RE: matches curly/smart apostrophes (plan requirement)
SMART_APOSTROPHE_RE = re.compile(r"[\u2018\u2019\u201a\u201b]")

# ILLEGAL_WIN_CHARS_RE: characters forbidden in Windows file names
ILLEGAL_WIN_CHARS_RE = re.compile(r'[<>:"/\\|?*\x00-\x1f]')

# ---------------------------------------------------------------------------
# AI polish constants
# ---------------------------------------------------------------------------

# _polish_enabled: module-level flag set by _ensure_anthropic() during startup
_polish_enabled: bool = False

# POLISH_CHUNK_CHARS: max characters to send per API call
# At ~4 chars/token, 30 000 chars ≈ 7 500 input tokens, leaving headroom for output
POLISH_CHUNK_CHARS = 30_000

# POLISH_MODEL: Claude model used for readability polishing
POLISH_MODEL = "claude-sonnet-4-6"

# POLISH_SYSTEM_PROMPT: instructions sent to Claude as the system message
POLISH_SYSTEM_PROMPT = """\
You are a document reformatter. You receive Markdown that was machine-converted from a PDF.
PDF conversion often produces layout artifacts: broken lines, multi-column text interleaving, \
and misplaced images. Fix these issues for human readability.

Fix these problems:
1. JOIN broken lines belonging to the same paragraph into flowing prose sentences.
2. Fix MULTI-COLUMN interleaving: if text from left and right columns alternates line by line, \
   reorder so the left column text flows completely first, then the right column text.
3. REPOSITION image embeds (![[filename]]) to appear immediately after the paragraph or heading \
   they most plausibly illustrate, based on surrounding text context.
4. REMOVE isolated page numbers, running headers, or footers (lone lines that are just a number, \
   a repeated title, or a short label clearly not part of the main content).
5. JOIN headings that are split across multiple lines into a single heading line.

Hard rules — never violate these:
- Preserve every ![[image_filename]] embed exactly; never alter the text inside the brackets.
- Preserve --- page dividers exactly as-is.
- Preserve # ## ### heading markers and their hierarchy.
- Do not add any content not present in the input.
- Do not change facts, names, dates, or meaning.
- Preserve all UTF-8 characters including diacriticals (e.g. Bahá'í, Táhirih, Tabríz).
- Output ONLY the corrected Markdown. No explanation, commentary, or code fences.\
"""


# ---------------------------------------------------------------------------
# Dependency bootstrap
# ---------------------------------------------------------------------------

def _ensure_anthropic() -> bool:
    """
    Check that the anthropic SDK is installed and ANTHROPIC_API_KEY is set.

    If the SDK is missing, attempts a pip install.
    If the API key is absent, logs a warning and returns False.

    Returns True if both SDK and key are available, False otherwise.
    """
    import os

    # api_key: the Anthropic API key from the environment
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        log.warning("ANTHROPIC_API_KEY not set — AI polish step will be skipped.")
        return False

    try:
        import anthropic  # noqa: F401 — test import only
        return True
    except ImportError:
        log.info("anthropic SDK not found — attempting pip install...")
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "anthropic"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            log.warning("pip install anthropic failed — AI polish step will be skipped.")
            return False
        try:
            import anthropic  # noqa: F401
            log.info("anthropic SDK installed successfully.")
            return True
        except ImportError:
            log.warning("anthropic import still fails after install — skipping AI polish.")
            return False


def _ensure_watchdog() -> bool:
    """
    Check that the watchdog library is installed.

    watchdog provides OS-native event-driven directory watching (uses
    ReadDirectoryChangesW on Windows — the same mechanism as .NET
    FileSystemWatcher).  If missing, a pip install is attempted once.

    Returns True if watchdog is available, False otherwise.  The caller
    falls back to polling mode when this returns False.
    """
    try:
        import watchdog  # noqa: F401 — test import only
        return True
    except ImportError:
        log.info("watchdog not found — attempting pip install...")

        # result: CompletedProcess from the pip subprocess
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "watchdog"],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            log.warning(
                "pip install watchdog failed — falling back to polling mode.\n%s",
                result.stderr,
            )
            return False

        try:
            import watchdog  # noqa: F401 — verify the install worked
            log.info("watchdog installed successfully.")
            return True
        except ImportError:
            log.warning("watchdog import still fails after install — polling mode.")
            return False


def _ensure_docx_deps() -> bool:
    """
    Check that python-docx is installed.

    python-docx provides structured access to DOCX files: paragraphs,
    tables, runs, inline images, and paragraph styles.  Used by convert_docx().

    Returns True if the package is available, False otherwise.
    """
    try:
        import docx  # noqa: F401 — test import only
        return True
    except ImportError:
        log.info("python-docx not found — attempting pip install...")

        # result: CompletedProcess from the pip subprocess
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "python-docx"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            log.warning("pip install python-docx failed: %s", result.stderr)
            return False
        try:
            import docx  # noqa: F401
            log.info("python-docx installed successfully.")
            return True
        except ImportError:
            log.warning("python-docx import still fails after install.")
            return False


def _ensure_rtf_deps() -> bool:
    """
    Check that striprtf is installed (text-only RTF fallback converter).

    striprtf is used only when LibreOffice is unavailable.  It strips RTF
    control codes and returns plain text.  Embedded images cannot be extracted
    via striprtf — install LibreOffice for full image fidelity.

    Returns True if the package is available, False otherwise.
    """
    try:
        from striprtf.striprtf import rtf_to_text  # noqa: F401 — test import only
        return True
    except ImportError:
        log.info("striprtf not found — attempting pip install...")

        # result: CompletedProcess from the pip subprocess
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "striprtf"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            log.warning("pip install striprtf failed: %s", result.stderr)
            return False
        try:
            from striprtf.striprtf import rtf_to_text  # noqa: F401
            log.info("striprtf installed successfully.")
            return True
        except ImportError:
            log.warning("striprtf import still fails after install.")
            return False


def _find_libreoffice() -> "str | None":
    """
    Locate the LibreOffice soffice executable on the current system.

    Searches LIBREOFFICE_PATHS in order, then falls back to shutil.which().
    LibreOffice is the preferred converter for RTF and Apple Pages files
    because it preserves images and full formatting.

    Returns the absolute path string to soffice on success, None if not found.
    """
    import os
    import shutil as _shutil

    # Check each known install location in priority order
    for path in LIBREOFFICE_PATHS:
        if os.path.isfile(path):
            log.debug("Found LibreOffice at: %s", path)
            return path

    # Also probe PATH (covers Linux package installs and non-standard Windows setups)
    found = _shutil.which("soffice")
    if found:
        log.debug("Found LibreOffice via PATH: %s", found)
        return found

    log.debug("LibreOffice not found on this system.")
    return None


def _ensure_dependencies() -> None:
    """
    Ensure PyMuPDF (imported as 'fitz') is available.

    If the import fails, attempt a pip install and then re-import.
    Exits with an error message if pip itself fails.
    """
    try:
        import fitz  # noqa: F401 — test import only
        log.info("PyMuPDF already available.")
    except ImportError:
        log.warning("PyMuPDF not found — attempting pip install...")
        print("Installing PyMuPDF (this only happens once)...")

        # result: CompletedProcess from the pip subprocess
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "pymupdf"],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            # pip failed — print stderr so the user knows why
            print(f"ERROR: pip install failed:\n{result.stderr}")
            sys.exit(1)

        try:
            import fitz  # noqa: F401 — verify the install worked
            log.info("PyMuPDF installed successfully.")
        except ImportError:
            print("ERROR: PyMuPDF install reported success but import still fails.")
            sys.exit(1)


# ---------------------------------------------------------------------------
# Filename utilities
# ---------------------------------------------------------------------------

def sanitize_filename(name: str) -> str:
    """
    Convert an arbitrary string into a safe Windows filename.

    Steps:
      1. Replace curly/smart apostrophes with straight apostrophes
      2. Replace Windows-illegal characters with underscores
      3. Strip leading/trailing dots and spaces
      4. Truncate to 200 characters to stay well within the 260-char path limit

    name   : raw input string (e.g. a PDF title or stem)
    returns: filesystem-safe string suitable for use as a filename stem
    """
    # Step 1: normalise smart apostrophes per CLAUDE.md convention
    name = SMART_APOSTROPHE_RE.sub("'", name)

    # Step 2: remove Windows-illegal characters
    name = ILLEGAL_WIN_CHARS_RE.sub("_", name)

    # Step 3: strip boundary dots and spaces (Windows disallows trailing dots)
    name = name.strip(". ")

    # Step 4: enforce length limit
    return name[:200]


# ---------------------------------------------------------------------------
# Frontmatter builder
# ---------------------------------------------------------------------------

def build_frontmatter(pdf_path: Path, doc_meta: dict) -> str:
    """
    Generate the YAML frontmatter block for the Obsidian note.

    pdf_path : Path object pointing to the source PDF file
    doc_meta : dict returned by fitz.Document.metadata
               Common keys: title, author, creationDate, subject, keywords

    returns  : string beginning and ending with '---'
    """
    # lines: list of YAML key-value strings assembled incrementally
    lines: list[str] = ["---"]

    # --- title ---
    # Prefer the PDF's embedded title; fall back to the filename stem
    raw_title = (doc_meta.get("title") or "").strip()
    title = raw_title if raw_title else pdf_path.stem
    # Quote the title because it may contain YAML-special characters
    lines.append(f'title: "{title}"')

    # --- source_pdf ---
    # Record just the filename (not the full path) for portability
    lines.append(f'source_pdf: "{pdf_path.name}"')

    # --- author ---
    raw_author = (doc_meta.get("author") or "").strip()
    if raw_author:
        lines.append(f'author: "{raw_author}"')

    # --- created ---
    # PDF dates are stored as "D:YYYYMMDDHHmmss±HH'mm'" — parse just the date
    raw_date = (doc_meta.get("creationDate") or "").strip()
    m = PDF_DATE_RE.match(raw_date)
    if m:
        # iso_date: YYYY-MM-DD format that Obsidian understands
        iso_date = f"{m.group(1)}-{m.group(2)}-{m.group(3)}"
        lines.append(f"created: {iso_date}")

    # --- subject / keywords (optional extra metadata) ---
    subject = (doc_meta.get("subject") or "").strip()
    if subject:
        lines.append(f'subject: "{subject}"')

    # --- tags ---
    lines.append("tags:")
    lines.append("  - pdf-import")

    lines.append("---")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Page processor
# ---------------------------------------------------------------------------

class PageProcessor:
    """
    Converts a single PDF page into a Markdown string fragment.

    Each PageProcessor instance handles one page.  It:
      1. Detects tables and records their bounding boxes
      2. Extracts images, saves them to IMAGES_DIR, records their positions
      3. Extracts text blocks, skipping regions covered by tables/images
      4. Classifies text blocks as headings, paragraphs, or bullet items
      5. Handles two-column layouts by clustering blocks into columns
      6. Assembles everything sorted by vertical position on the page

    Parameters
    ----------
    page        : fitz.Page object for this page
    doc         : fitz.Document (parent) — needed for image extraction
    pdf_stem    : filename stem of the source PDF (used in image filenames)
    page_idx    : 0-based page index (used in image filenames and log messages)
    seen_xrefs  : set shared across all pages to deduplicate image saves
    """

    def __init__(self, page, doc, pdf_stem: str, page_idx: int, seen_xrefs: set):
        # page: the fitz.Page being processed
        self._page = page

        # doc: the parent fitz.Document (for extract_image)
        self._doc = doc

        # pdf_stem: sanitised source filename stem for asset naming
        self._pdf_stem = pdf_stem

        # page_idx: 0-based index, converted to 1-based for filenames/logs
        self._page_idx = page_idx

        # seen_xrefs: mutable set shared with caller; prevents duplicate saves
        self._seen_xrefs = seen_xrefs

        # _table_rects: list of fitz.Rect covering each detected table region
        self._table_rects: list = []

        # _table_md_by_y: dict mapping table top-y → GFM markdown string
        self._table_md_by_y: dict[float, str] = {}

        # _image_md_by_y: dict mapping image top-y → Obsidian embed string
        self._image_md_by_y: dict[float, str] = {}

        # _text_elements: list of (y0, markdown_line) from text extraction
        self._text_elements: list[tuple[float, str]] = []

    # -----------------------------------------------------------------------
    # Public entry point
    # -----------------------------------------------------------------------

    def process(self) -> str:
        """
        Run the full pipeline for this page and return the Markdown fragment.

        Calls internal helpers in order: tables → images → text → assemble.
        """
        self._extract_tables()
        self._extract_images()
        self._extract_text()
        return self._assemble()

    # -----------------------------------------------------------------------
    # Step 1: Table detection
    # -----------------------------------------------------------------------

    def _extract_tables(self) -> None:
        """
        Detect tables drawn with vector lines and convert to GFM format.

        Uses fitz.Page.find_tables() which identifies grid-line structures.
        Stores each table's bounding rect (to exclude from text extraction)
        and its GFM markdown string (to insert at the correct vertical position).
        """
        try:
            # tabs: TableFinder result — iterable of Table objects
            tabs = self._page.find_tables()
        except Exception as exc:
            # Table detection is non-critical; log and continue without tables
            log.warning("Page %d: table detection failed: %s", self._page_idx + 1, exc)
            return

        for table in tabs:
            try:
                # rect: fitz.Rect giving the table's position on the page
                rect = table.bbox  # (x0, y0, x1, y1) in page units

                # Store the rect so text blocks inside it can be skipped
                self._table_rects.append(rect)

                # gfm: pipe-table string from PyMuPDF's built-in converter
                gfm = table.to_markdown()

                # Trim whitespace; ensure leading/trailing blank lines for MD
                gfm = gfm.strip()

                # Key by y0 so we can sort by vertical position later
                y0 = rect[1]
                self._table_md_by_y[y0] = gfm

                log.debug(
                    "Page %d: table detected at y=%.1f (%.0f×%.0f px)",
                    self._page_idx + 1, y0,
                    rect[2] - rect[0], rect[3] - rect[1],
                )
            except Exception as exc:
                log.warning(
                    "Page %d: could not convert table to markdown: %s",
                    self._page_idx + 1, exc,
                )
                # Remove the rect we stored so text isn't incorrectly excluded
                if self._table_rects:
                    self._table_rects.pop()

    # -----------------------------------------------------------------------
    # Step 2: Image extraction
    # -----------------------------------------------------------------------

    def _extract_images(self) -> None:
        """
        Extract embedded images, save them to IMAGES_DIR, and record embeds.

        Skips:
          - Images smaller than MIN_IMAGE_PX in either dimension (decorative)
          - xrefs already saved by a previous page (deduplication)

        Image filenames: {pdf_stem}_p{page_num:03d}_{xref:04d}.{ext}
        Obsidian embeds: ![[filename.ext]]
        """
        # image_list: list of (xref, smask, w, h, bpc, colorspace, …) tuples
        image_list = self._page.get_images(full=True)

        for img_info in image_list:
            # xref: cross-reference number uniquely identifying this image
            xref = img_info[0]

            # w, h: image width and height in pixels (indices 2 and 3)
            w = img_info[2]
            h = img_info[3]

            # Skip tiny decorative images
            if w < MIN_IMAGE_PX or h < MIN_IMAGE_PX:
                log.debug("Page %d: skipping small image xref=%d (%dx%d)", self._page_idx + 1, xref, w, h)
                continue

            # Skip images we already extracted on a previous page
            if xref in self._seen_xrefs:
                log.debug("Page %d: image xref=%d already saved, re-embedding", self._page_idx + 1, xref)
                # We still need to embed it — look up the previously used filename
                # We reconstruct it using the same naming scheme but page_idx from first encounter
                # Actually we need to find the filename. Let's store it differently.
                # Handled below by checking seen_xrefs after the save attempt.
                pass

            # Build the filename regardless of deduplication — we need it for embedding
            # page_num: 1-based page number for readability
            page_num = self._page_idx + 1
            # ext: format extension (png, jpeg, etc.) from fitz
            # We'll get this after extracting, but we need a placeholder for now.
            # Actual filename built after extraction below.

            if xref not in self._seen_xrefs:
                # Extract the raw image data from the PDF
                try:
                    # img_dict: dict with keys 'image', 'ext', 'width', 'height', etc.
                    img_dict = self._doc.extract_image(xref)
                except Exception as exc:
                    log.warning(
                        "Page %d: image extraction failed (xref %d): %s",
                        self._page_idx + 1, xref, exc,
                    )
                    # Insert a comment placeholder so the reader knows an image was here
                    # We'll find the y-position from get_image_rects below
                    y0 = self._get_image_y(xref)
                    self._image_md_by_y[y0] = (
                        f"<!-- image extraction failed (xref {xref}) -->"
                    )
                    continue

                # img_bytes: the raw binary image data
                img_bytes: bytes = img_dict["image"]

                # ext: format string like 'png', 'jpeg', 'jp2', etc.
                ext: str = img_dict.get("ext", "png")

                # Build the unique filename for this image
                img_filename = f"{self._pdf_stem}_p{page_num:03d}_{xref:04d}.{ext}"

                # dest_path: full path where the image will be written
                dest_path = IMAGES_DIR / img_filename

                try:
                    dest_path.write_bytes(img_bytes)
                    log.info("Saved image: %s (%d bytes)", dest_path, len(img_bytes))
                except Exception as exc:
                    log.warning("Page %d: could not write image %s: %s", page_num, img_filename, exc)
                    continue

                # Mark this xref as saved so we don't save it again on later pages
                self._seen_xrefs.add(xref)

                # Store filename keyed by xref for later embed lookup
                self._seen_xrefs_to_filename = getattr(self, "_seen_xrefs_to_filename", {})
                self._seen_xrefs_to_filename[xref] = img_filename

            # Retrieve the filename (whether just saved or from a previous page)
            xref_map = getattr(self, "_seen_xrefs_to_filename", {})
            if xref not in xref_map:
                # Filename not recorded — image was saved by a prior PageProcessor instance
                # Reconstruct the filename using a glob-like search is complex,
                # so we embed a comment noting the image exists
                y0 = self._get_image_y(xref)
                self._image_md_by_y[y0] = (
                    f"<!-- image xref {xref} (saved on earlier page) -->"
                )
                continue

            img_filename = xref_map[xref]

            # Determine the image's vertical position on the page for ordering
            y0 = self._get_image_y(xref)

            # embed: Obsidian wikilink embed syntax (filename only — vault-wide resolution)
            embed = f"![[{img_filename}]]"
            self._image_md_by_y[y0] = embed

    def _get_image_y(self, xref: int) -> float:
        """
        Return the top-y coordinate of an image on this page.

        Uses get_image_rects() to find the image's bounding box.
        Falls back to a large number so unpositioned images go to the end.

        xref : image cross-reference number
        """
        try:
            # rects: list of fitz.Rect objects (usually just one)
            rects = self._page.get_image_rects(xref)
            if rects:
                # y0 is the second element of the Rect tuple (x0, y0, x1, y1)
                return rects[0].y0
        except Exception:
            pass
        # Default: push to end if position unknown
        return 9999.0

    # -----------------------------------------------------------------------
    # Step 3: Text extraction
    # -----------------------------------------------------------------------

    def _extract_text(self) -> None:
        """
        Extract text blocks from the page, skipping table and image regions.

        Uses page.get_text("dict") for structured output with per-span font
        metadata (size, flags, bbox).

        The method:
          1. Computes the median font size across all spans (= body font size)
          2. Detects two-column layouts and re-orders blocks left-then-right
          3. For each span, applies font-size / bold / italic / mono heuristics
          4. Groups spans into lines, lines into blocks, classifying each block
        """
        import fitz  # local import — guaranteed available after _ensure_dependencies

        # page_dict: the structured text dict from PyMuPDF
        # Structure: {blocks: [{type, bbox, lines: [{spans: [{text, size, flags, bbox}]}]}]}
        page_dict = self._page.get_text("dict")

        # blocks: list of block dicts; type 0 = text, type 1 = image (handled separately)
        blocks = page_dict.get("blocks", [])

        # Collect all span font sizes to compute the median (body font size)
        all_sizes: list[float] = []
        for block in blocks:
            if block.get("type") != 0:
                continue  # skip image blocks
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    sz = span.get("size", 0)
                    if sz > 0:
                        all_sizes.append(sz)

        # body_size: median span size across the whole page; used as the baseline
        body_size = statistics.median(all_sizes) if all_sizes else 12.0

        # Separate text blocks into left and right columns if layout is two-column
        # A block's x-centroid determines its column assignment
        page_width = self._page.rect.width
        # half_width: the dividing x-coordinate between columns
        half_width = page_width / 2

        # left_blocks / right_blocks: blocks whose horizontal centre falls left/right
        left_blocks = []
        right_blocks = []

        for block in blocks:
            if block.get("type") != 0:
                continue  # skip embedded-image blocks (handled by _extract_images)

            # bbox: (x0, y0, x1, y1) bounding box of the entire block
            bbox = block.get("bbox", (0, 0, 0, 0))
            x0, y0, x1, y1 = bbox

            # Skip blocks inside a table region to avoid double-rendering
            if self._rect_in_table(x0, y0, x1, y1):
                continue

            # x_mid: horizontal centre of the block
            x_mid = (x0 + x1) / 2
            if x_mid < half_width:
                left_blocks.append(block)
            else:
                right_blocks.append(block)

        # Determine if this is truly a two-column layout:
        # Both columns must have blocks, and neither should dominate (> 90%)
        total = len(left_blocks) + len(right_blocks)
        is_two_column = (
            total > 4
            and len(left_blocks) > 0
            and len(right_blocks) > 0
            and len(left_blocks) / total < 0.90
            and len(right_blocks) / total < 0.90
        )

        if is_two_column:
            # Sort each column by vertical position, then concatenate left→right
            left_blocks.sort(key=lambda b: b["bbox"][1])
            right_blocks.sort(key=lambda b: b["bbox"][1])
            ordered_blocks = left_blocks + right_blocks
        else:
            # Single-column: merge all blocks and sort by vertical position
            all_blocks = left_blocks + right_blocks
            all_blocks.sort(key=lambda b: b["bbox"][1])
            ordered_blocks = all_blocks

        # Process each block, converting its spans to Markdown
        for block in ordered_blocks:
            # block_y0: top of this block — used as sort key in _assemble()
            block_y0 = block["bbox"][1]

            # md_lines: Markdown lines accumulated for this block
            md_lines: list[str] = []

            for line in block.get("lines", []):
                # line_text: concatenated plain text from all spans in this line
                # We build the formatted version alongside
                line_md_parts: list[str] = []

                for span in line.get("spans", []):
                    raw_text = span.get("text", "").strip()
                    if not raw_text:
                        continue

                    # size: font size of this span
                    size = span.get("size", body_size)

                    # flags: bitmask — bit 1=italic, bit 4=bold, bit 3=mono
                    flags = span.get("flags", 0)

                    # ratio: how much larger this span is vs the body font
                    ratio = size / body_size if body_size > 0 else 1.0

                    # Apply inline formatting only at body size (headings handled at block level)
                    if ratio < HEADING_RATIO_H3:
                        is_bold   = bool(flags & 16)  # bit 4 (value 16) = bold
                        is_italic = bool(flags & 2)   # bit 1 (value 2) = italic
                        is_mono   = bool(flags & 8)   # bit 3 (value 8) = monospace

                        if is_mono:
                            raw_text = f"`{raw_text}`"
                        elif is_bold and is_italic:
                            raw_text = f"***{raw_text}***"
                        elif is_bold:
                            raw_text = f"**{raw_text}**"
                        elif is_italic:
                            raw_text = f"*{raw_text}*"

                    line_md_parts.append(raw_text)

                # assembled_line: the joined content of all spans on this line
                assembled_line = " ".join(line_md_parts)
                if assembled_line:
                    md_lines.append(assembled_line)

            if not md_lines:
                continue  # empty block — skip

            # block_text: all lines of this block joined into one string for heading check
            block_text = "\n".join(md_lines)

            # heading_size: largest span size in this block (first span of first line)
            heading_size = (
                block["lines"][0]["spans"][0].get("size", body_size)
                if block.get("lines") and block["lines"][0].get("spans")
                else body_size
            )
            h_ratio = heading_size / body_size if body_size > 0 else 1.0

            # Classify the block and emit the appropriate Markdown prefix
            if h_ratio >= HEADING_RATIO_H1:
                md_block = f"# {block_text}"
            elif h_ratio >= HEADING_RATIO_H2:
                md_block = f"## {block_text}"
            elif h_ratio >= HEADING_RATIO_H3:
                md_block = f"### {block_text}"
            else:
                # Normal paragraph or bullet — use as-is
                md_block = block_text

            self._text_elements.append((block_y0, md_block))

    def _rect_in_table(self, x0: float, y0: float, x1: float, y1: float) -> bool:
        """
        Return True if the given bounding box overlaps a detected table region.

        Any overlap (not just containment) disqualifies the block from text
        processing, preventing double-rendering of table cell content.

        x0, y0, x1, y1 : bounding box coordinates of the text block
        """
        for t_rect in self._table_rects:
            # t_rect is a fitz.Rect or a (x0, y0, x1, y1) tuple
            tx0, ty0, tx1, ty1 = t_rect[0], t_rect[1], t_rect[2], t_rect[3]

            # Overlap check: two rects overlap unless one is entirely to the side
            no_overlap = (x1 <= tx0 or x0 >= tx1 or y1 <= ty0 or y0 >= ty1)
            if not no_overlap:
                return True
        return False

    # -----------------------------------------------------------------------
    # Step 4: Assembly
    # -----------------------------------------------------------------------

    def _assemble(self) -> str:
        """
        Merge text blocks, tables, and image embeds sorted by vertical position.

        All three element types are stored with a y0 key.  We combine them
        into a single list, sort by y0, and join with blank lines.

        Returns the complete Markdown fragment for this page.
        """
        # elements: list of (y0, markdown_string) from all sources
        elements: list[tuple[float, str]] = []

        # Add text blocks
        elements.extend(self._text_elements)

        # Add tables (keyed by their top-y from _extract_tables)
        for y0, gfm in self._table_md_by_y.items():
            elements.append((y0, gfm))

        # Add images (keyed by their top-y from _extract_images)
        for y0, embed in self._image_md_by_y.items():
            elements.append((y0, embed))

        # Sort everything by vertical position (top of element on page)
        elements.sort(key=lambda t: t[0])

        # Join with blank lines between elements for clean Markdown formatting
        return "\n\n".join(md for _, md in elements)


# ---------------------------------------------------------------------------
# Per-PDF conversion
# ---------------------------------------------------------------------------

def convert_pdf(pdf_path: Path, output_dir: Path, overwrite: bool) -> Path | None:
    """
    Convert a single PDF file to an Obsidian Markdown note.

    Parameters
    ----------
    pdf_path   : absolute Path of the source PDF
    output_dir : directory where the .md file will be written
    overwrite  : if True, replace an existing .md; otherwise skip or suffix

    Returns the Path of the written .md file, or None if skipped.
    """
    import fitz  # guaranteed available after _ensure_dependencies()

    log.info("Processing: %s", pdf_path.name)
    print(f"\nProcessing: {pdf_path.name}")

    # ---- Open the PDF -------------------------------------------------------
    try:
        # doc: the fitz.Document object representing the entire PDF
        doc = fitz.open(str(pdf_path))
    except Exception as exc:
        log.warning("Cannot open PDF %s: %s — skipping", pdf_path.name, exc)
        print(f"  SKIPPED (cannot open): {exc}")
        return None

    # ---- Check for password protection ----------------------------------------
    if doc.is_encrypted:
        log.warning("PDF is password-protected: %s — skipping", pdf_path.name)
        print("  SKIPPED (password protected)")
        doc.close()
        return None

    # ---- Extract document metadata ------------------------------------------
    # doc_meta: dict with keys title, author, subject, keywords, creationDate, etc.
    doc_meta = doc.metadata or {}

    # ---- Determine output path -----------------------------------------------
    # Use the PDF's embedded title for the filename, falling back to stem
    raw_title = (doc_meta.get("title") or "").strip() or pdf_path.stem
    safe_stem = sanitize_filename(raw_title)

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Resolve the .md path, avoiding collisions
    if overwrite:
        # --overwrite: write directly to the base name (may replace existing)
        md_path = output_dir / f"{safe_stem}.md"
    else:
        # Default: find an unused filename (Title.md, Title_2.md, …)
        md_path = _resolve_collision(output_dir, safe_stem)
        if md_path is None:
            # _resolve_collision returns None only when overwrite=False and file exists
            # (not possible with current logic — placeholder for future skip-if-exists)
            log.info("Skipping %s (already exists)", safe_stem)
            print("  SKIPPED (already exists)")
            doc.close()
            return None

    # ---- Build frontmatter --------------------------------------------------
    # frontmatter: the YAML block at the top of every Obsidian note
    frontmatter = build_frontmatter(pdf_path, doc_meta)

    # ---- Process each page --------------------------------------------------
    # page_count: total pages in the document
    page_count = doc.page_count

    # seen_xrefs: shared across all pages to prevent duplicate image saves
    seen_xrefs: set = set()

    # Also share the filename map across pages
    # We'll use a dict attached to the set object (hacky but avoids a separate arg)
    xref_filename_map: dict[int, str] = {}

    # page_parts: Markdown fragment for each page
    page_parts: list[str] = []

    for page_idx in range(page_count):
        page = doc.load_page(page_idx)

        # Instantiate a processor for this page
        processor = PageProcessor(
            page=page,
            doc=doc,
            pdf_stem=sanitize_filename(pdf_path.stem),
            page_idx=page_idx,
            seen_xrefs=seen_xrefs,
        )

        # Share the filename map so later pages can embed images saved earlier
        processor._seen_xrefs_to_filename = xref_filename_map

        # md_fragment: the Markdown content for this single page
        md_fragment = processor.process()

        # After processing, merge the filename map back (processor may have added entries)
        xref_filename_map.update(getattr(processor, "_seen_xrefs_to_filename", {}))

        if md_fragment.strip():
            page_parts.append(md_fragment)

        log.debug("Page %d/%d processed", page_idx + 1, page_count)

    doc.close()

    # ---- Assemble the full document -----------------------------------------
    # page_divider: inserted between pages of a multi-page PDF
    page_divider = "\n\n---\n\n"

    # body_markdown: all pages joined; single-page PDFs get no divider
    body_markdown = page_divider.join(page_parts)

    # ---- AI readability polish ----------------------------------------------
    # If the anthropic SDK and ANTHROPIC_API_KEY are available, pass the body
    # through Claude to fix multi-column interleaving, broken lines, and
    # image placement before writing the final note.
    if _polish_enabled:
        log.info("Polishing '%s' for readability...", pdf_path.name)
        print("  Polishing for readability (AI)...")
        body_markdown, polish_report = polish_markdown_body(body_markdown, pdf_path.name)
        log.info(polish_report)
        print(f"  {polish_report}")
    else:
        log.debug("AI polish skipped (not enabled).")

    # title: the human-readable title for the H1 line
    title = (doc_meta.get("title") or "").strip() or pdf_path.stem

    # full_content: complete note text (frontmatter + H1 + body)
    full_content = (
        f"{frontmatter}\n\n"
        f"# {title}\n\n"
        f"{body_markdown}\n"
    )

    # ---- Write the note -----------------------------------------------------
    try:
        md_path.write_text(full_content, encoding="utf-8")
    except Exception as exc:
        log.error("Failed to write %s: %s", md_path, exc)
        print(f"  ERROR writing note: {exc}")
        return None

    # Log and print outside the try block so a print failure cannot mask a
    # successful write (the charmap issue that caused false SKIPPED results)
    log.info("Note written: %s", md_path)
    print(f"  -> {md_path}")
    return md_path


def _move_pdf_to_attachments(pdf_path: Path) -> Path | None:
    """
    Move the source PDF to ATTACHMENTS_DIR after successful conversion.

    The original file is preserved — it is relocated, not deleted or overwritten.
    If a file with the same name already exists in ATTACHMENTS_DIR, the moved
    file is suffixed with _2, _3, etc. (same collision strategy as notes).

    pdf_path : absolute Path of the source PDF to move
    returns  : the destination Path on success, None if the move failed
    """
    # Ensure the attachments directory exists
    ATTACHMENTS_DIR.mkdir(parents=True, exist_ok=True)

    # base_stem: the original filename stem (without .pdf extension)
    base_stem = pdf_path.stem

    # Find an unused destination path in ATTACHMENTS_DIR
    dest = ATTACHMENTS_DIR / pdf_path.name
    if dest.exists():
        # Append _2, _3, … to avoid clobbering an existing PDF
        counter = 2
        while True:
            dest = ATTACHMENTS_DIR / f"{base_stem}_{counter}.pdf"
            if not dest.exists():
                break
            counter += 1

    try:
        shutil.move(str(pdf_path), str(dest))
        log.info("Moved source PDF: %s → %s", pdf_path, dest)
        print(f"  (PDF moved -> {dest})")
        return dest
    except Exception as exc:
        log.warning("Could not move PDF %s to attachments: %s", pdf_path.name, exc)
        print(f"  WARNING: could not move source PDF: {exc}")
        return None


def _resolve_collision(output_dir: Path, stem: str) -> Path:
    """
    Find an unused .md path in output_dir for the given filename stem.

    Tries 'stem.md', then 'stem_2.md', 'stem_3.md', etc.
    Always returns a valid (non-existing) path — never returns None.

    output_dir : directory to search for existing files
    stem       : the base filename (without extension)
    """
    # First candidate: the simple stem
    candidate = output_dir / f"{stem}.md"
    if not candidate.exists():
        return candidate

    # Suffix candidates: stem_2.md, stem_3.md, …
    counter = 2
    while True:
        candidate = output_dir / f"{stem}_{counter}.md"
        if not candidate.exists():
            return candidate
        counter += 1


# ---------------------------------------------------------------------------
# Multi-format support constants
# ---------------------------------------------------------------------------

# SUPPORTED_EXTENSIONS: all file extensions that the watcher and --once /
# --file modes will process.  Add a new extension here and implement a
# corresponding converter in dispatch_convert() to extend support.
SUPPORTED_EXTENSIONS: frozenset = frozenset({".pdf", ".docx", ".rtf", ".pages"})

# LIBREOFFICE_PATHS: candidate install paths for the soffice executable.
# Searched in order by _find_libreoffice(); the first existing path wins.
# RTF and Apple Pages conversion use LibreOffice → PDF → existing PDF pipeline.
LIBREOFFICE_PATHS: list = [
    r"C:\Program Files\LibreOffice\program\soffice.exe",
    r"C:\Program Files (x86)\LibreOffice\program\soffice.exe",
    "/Applications/LibreOffice.app/Contents/MacOS/soffice",
    "/usr/bin/soffice",
    "/usr/local/bin/soffice",
]

# NS_A: DrawingML main namespace — used to locate <a:blip> image-reference elements
# inside paragraph XML when extracting inline images from DOCX files.
NS_A = "http://schemas.openxmlformats.org/drawingml/2006/main"

# NS_R: Office relationships namespace — the r:embed attribute value is the
# relationship ID (rId) that maps to the image part in the DOCX ZIP archive.
NS_R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"


# ---------------------------------------------------------------------------
# DOCX inline-image and paragraph helpers
# ---------------------------------------------------------------------------

def _get_docx_inline_image_rids(para_element) -> list:
    """
    Extract all image relationship IDs from a paragraph XML element.

    Inline images in DOCX live inside <w:drawing> elements as DrawingML
    <a:blip r:embed="rIdNN"/> nodes.  This function finds all such blip
    elements and returns their embed attribute values (the rId strings).

    para_element : lxml element for a w:p paragraph node
    returns      : list of rId strings (e.g. ['rId5', 'rId7']); empty if none
    """
    # rids: collected relationship IDs for all inline images in this paragraph
    rids: list = []

    # Namespace-qualified findall to locate every <a:blip> anywhere in the subtree
    for blip in para_element.findall(f".//{{{NS_A}}}blip"):
        # The r:embed attribute is the relationship ID linking to the image part
        rid = blip.get(f"{{{NS_R}}}embed")
        if rid:
            rids.append(rid)

    return rids


def _docx_para_to_md(para, image_rel_map: dict) -> str:
    """
    Convert a python-docx Paragraph to a Markdown string.

    Handles:
      - Heading 1–4 styles → # / ## / ### / ####
      - List Bullet / List Number styles → - / 1.
      - Bold, italic, and bold-italic run formatting → ** / * / ***
      - Inline images referenced by rId → ![[filename]] Obsidian embeds

    para          : python-docx Paragraph object
    image_rel_map : dict mapping rId → saved image filename; built by convert_docx()
                    before this function is called so lookups always succeed.

    returns       : formatted Markdown string for this paragraph, or '' if empty
    """
    # style_name: the paragraph style (e.g. "Heading 1", "Normal", "List Bullet")
    style_name = (para.style.name if para.style else "") or ""

    # --- Collect inline image embeds from this paragraph's XML ---
    # inline_embeds: Obsidian ![[filename]] strings for images found in this para
    inline_embeds: list = []
    for rid in _get_docx_inline_image_rids(para._element):
        if rid in image_rel_map:
            inline_embeds.append(f"![[{image_rel_map[rid]}]]")
        else:
            # rId present in the XML but not in the saved relationships map
            inline_embeds.append(f"<!-- image rId {rid} not found in document relationships -->")

    # --- Build text content from runs ---
    # text_parts: formatted fragments from each run, joined without separator
    text_parts: list = []
    for run in para.runs:
        raw = run.text
        if not raw:
            continue

        # Apply Markdown inline formatting based on run bold/italic properties
        is_bold   = bool(run.bold)
        is_italic = bool(run.italic)

        if is_bold and is_italic:
            raw = f"***{raw}***"
        elif is_bold:
            raw = f"**{raw}**"
        elif is_italic:
            raw = f"*{raw}*"

        text_parts.append(raw)

    # assembled_text: full plain+formatted text for this paragraph
    assembled_text = "".join(text_parts).strip()

    # --- Apply heading / list Markdown prefix based on paragraph style ---
    if style_name.startswith("Heading 1"):
        text_md = f"# {assembled_text}" if assembled_text else ""
    elif style_name.startswith("Heading 2"):
        text_md = f"## {assembled_text}" if assembled_text else ""
    elif style_name.startswith("Heading 3"):
        text_md = f"### {assembled_text}" if assembled_text else ""
    elif style_name.startswith("Heading 4"):
        text_md = f"#### {assembled_text}" if assembled_text else ""
    elif style_name in ("List Bullet", "List Bullet 2", "List Bullet 3"):
        text_md = f"- {assembled_text}" if assembled_text else ""
    elif style_name in ("List Number", "List Number 2", "List Number 3"):
        text_md = f"1. {assembled_text}" if assembled_text else ""
    else:
        text_md = assembled_text

    # --- Combine text and any inline images into the final output ---
    parts: list = []
    if text_md:
        parts.append(text_md)
    parts.extend(inline_embeds)

    return "\n".join(parts)


def _docx_table_to_md(table) -> str:
    """
    Convert a python-docx Table object to a GFM pipe-table string.

    Reads all rows and cells in order, escapes pipe characters in cell text,
    and produces the standard GFM format with a dashes separator after the
    header row.

    table  : python-docx Table object
    returns: GFM pipe-table string, or '' if the table has no rows
    """
    if not table.rows:
        return ""

    # rows_data: list of lists of cell text strings, one sub-list per row
    rows_data: list = []
    for row in table.rows:
        # cell_texts: one entry per cell in this row
        cell_texts: list = []
        for cell in row.cells:
            # Concatenate all paragraph texts within the cell (multi-para cells)
            cell_content = " ".join(
                p.text for p in cell.paragraphs if p.text.strip()
            ).strip()
            # Escape pipe characters so they don't break GFM table syntax
            cell_content = cell_content.replace("|", "\\|")
            cell_texts.append(cell_content)
        rows_data.append(cell_texts)

    if not rows_data:
        return ""

    # Normalize all rows to the same column count (use the maximum across rows)
    col_count = max(len(r) for r in rows_data)
    rows_data = [r + [""] * (col_count - len(r)) for r in rows_data]

    # header_row: first data row becomes the GFM column header
    header    = "| " + " | ".join(rows_data[0]) + " |"
    # separator: GFM requires this dashes row after the header
    separator = "| " + " | ".join(["---"] * col_count) + " |"
    # data_rows: all subsequent rows as GFM pipe rows
    data_rows = ["| " + " | ".join(row) + " |" for row in rows_data[1:]]

    return "\n".join([header, separator] + data_rows)


# ---------------------------------------------------------------------------
# DOCX converter
# ---------------------------------------------------------------------------

def convert_docx(docx_path: Path, output_dir: Path, overwrite: bool) -> "Path | None":
    """
    Convert a DOCX file to an Obsidian Markdown note using python-docx.

    Features:
      - Heading styles (Heading 1–4) extracted as # / ## / ### / #### headings
      - Bold and italic run formatting extracted as ** / * inline Markdown
      - List styles (bullet and numbered) extracted with - / 1. prefixes
      - Embedded images extracted from document relationships and saved to IMAGES_DIR
      - Tables converted to GFM pipe tables
      - Paragraphs and tables interleaved in document order via direct XML iteration
      - YAML frontmatter built from core document properties (title, author, created)
      - Optional AI readability polish if _polish_enabled is True

    docx_path  : absolute Path of the source DOCX file
    output_dir : directory where the .md note will be written
    overwrite  : if True, replace existing .md; otherwise version-suffix (_2, _3, ...)

    Returns the Path of the written .md file, or None if skipped or failed.
    """
    if not _ensure_docx_deps():
        log.warning("python-docx unavailable — cannot convert %s", docx_path.name)
        print(f"  SKIPPED (python-docx not available): {docx_path.name}")
        return None

    # Deferred imports — guaranteed available after _ensure_docx_deps()
    from docx import Document          # type: ignore
    from docx.oxml.ns import qn        # type: ignore  qualified name builder

    log.info("Processing DOCX: %s", docx_path.name)
    print(f"\nProcessing: {docx_path.name}")

    try:
        # doc: the python-docx Document representing the entire DOCX file
        doc = Document(str(docx_path))
    except Exception as exc:
        log.warning("Cannot open DOCX %s: %s — skipping", docx_path.name, exc)
        print(f"  SKIPPED (cannot open): {exc}")
        return None

    # --- Document metadata from core properties ---
    # props: CoreProperties with title, author, created, etc.
    props = doc.core_properties

    # raw_title: embedded document title or filename stem as fallback
    raw_title = (props.title or "").strip() or docx_path.stem
    safe_stem = sanitize_filename(raw_title)

    # Ensure output directory and images directory exist
    output_dir.mkdir(parents=True, exist_ok=True)
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    # Resolve output path, avoiding name collisions
    if overwrite:
        md_path = output_dir / f"{safe_stem}.md"
    else:
        md_path = _resolve_collision(output_dir, safe_stem)

    # --- Extract all embedded images from document relationships ---
    # image_rel_map: maps rId string → saved image filename
    # Must be built before processing paragraphs so inline image lookups work.
    image_rel_map: dict = {}

    for rel_id, rel in doc.part.rels.items():
        # Only process image relationships (skip hyperlinks, styles, etc.)
        if "image" not in rel.reltype:
            continue
        try:
            # img_blob: raw binary image data from the DOCX ZIP part
            img_blob: bytes = rel.target_part.blob

            # content_type: MIME type string, e.g. "image/png" or "image/jpeg"
            content_type: str = rel.target_part.content_type
            # ext: file extension derived from MIME type; normalize jpeg → jpg
            ext = content_type.split("/")[-1].replace("jpeg", "jpg").split(";")[0].strip()

            # img_filename: unique asset filename for this image
            img_filename = f"{sanitize_filename(docx_path.stem)}_{rel_id}.{ext}"
            dest_path = IMAGES_DIR / img_filename

            dest_path.write_bytes(img_blob)
            image_rel_map[rel_id] = img_filename
            log.info("Saved DOCX image: %s (%d bytes)", img_filename, len(img_blob))
        except Exception as exc:
            log.warning("Could not extract DOCX image %s: %s", rel_id, exc)

    # --- Process body elements in document order ---
    # python-docx exposes paragraphs and tables as separate lists, losing
    # their interleaved order.  We iterate the XML body children directly
    # to preserve the original document sequence.
    #
    # W_P:   qualified tag name for paragraph elements (w:p)
    # W_TBL: qualified tag name for table elements (w:tbl)
    W_P   = qn("w:p")
    W_TBL = qn("w:tbl")

    # body_parts: Markdown fragments accumulated in document order
    body_parts: list = []

    for child in doc.element.body.iterchildren():
        if child.tag == W_P:
            # Paragraph — convert using _docx_para_to_md helper
            from docx.text.paragraph import Paragraph  # type: ignore
            para    = Paragraph(child, doc)
            md_line = _docx_para_to_md(para, image_rel_map)
            if md_line:
                body_parts.append(md_line)

        elif child.tag == W_TBL:
            # Table — convert to GFM pipe table
            from docx.table import Table  # type: ignore
            table = Table(child, doc)
            gfm   = _docx_table_to_md(table)
            if gfm:
                body_parts.append(gfm)
        # Other element types (w:sectPr, etc.) are layout metadata — skip them

    # body_markdown: all body fragments joined with blank lines
    body_markdown = "\n\n".join(body_parts)

    # --- AI readability polish (optional) ---
    if _polish_enabled:
        log.info("Polishing '%s' for readability...", docx_path.name)
        print("  Polishing for readability (AI)...")
        body_markdown, polish_report = polish_markdown_body(body_markdown, docx_path.name)
        log.info(polish_report)
        print(f"  {polish_report}")

    # --- Build YAML frontmatter ---
    fm_lines = [
        "---",
        f'title: "{raw_title}"',
        f'source_docx: "{docx_path.name}"',
    ]
    if props.author:
        fm_lines.append(f'author: "{props.author}"')
    if props.created:
        # props.created: Python datetime object from the DOCX core properties
        fm_lines.append(f"created: {props.created.strftime('%Y-%m-%d')}")
    fm_lines.extend(["tags:", "  - docx-import", "---"])
    frontmatter = "\n".join(fm_lines)

    # --- Assemble and write the note ---
    full_content = f"{frontmatter}\n\n# {raw_title}\n\n{body_markdown}\n"

    try:
        md_path.write_text(full_content, encoding="utf-8")
    except Exception as exc:
        log.error("Failed to write %s: %s", md_path, exc)
        print(f"  ERROR writing note: {exc}")
        return None

    log.info("DOCX note written: %s", md_path)
    print(f"  -> {md_path}")
    return md_path


# ---------------------------------------------------------------------------
# LibreOffice-based converter (RTF, Apple Pages, and other LO-supported formats)
# ---------------------------------------------------------------------------

def convert_via_libreoffice(
    source_path: Path,
    output_dir: Path,
    overwrite: bool,
    target_format: str = "pdf",
) -> "Path | None":
    """
    Convert a document to PDF via LibreOffice headless, then through convert_pdf().

    This is the conversion path for formats python-docx cannot handle natively:
    RTF and Apple Pages.  LibreOffice supports both.

    Workflow:
      1. Run: soffice --headless --convert-to pdf --outdir <tempdir> <source>
      2. LibreOffice writes a <stem>.pdf file in the temp directory
      3. Feed that PDF to convert_pdf() — which handles text, tables, and images
      4. The temporary PDF is automatically removed when the temp dir is cleaned up

    source_path   : absolute Path to the source document (RTF, Pages, etc.)
    output_dir    : directory where the .md note will be written
    overwrite     : if True, replace existing .md; otherwise version-suffix
    target_format : LibreOffice --convert-to format string (default: 'pdf')

    Returns the Path of the written .md file, or None on failure.
    """
    import tempfile  # standard library — always available

    # Locate LibreOffice on this system (checks LIBREOFFICE_PATHS then PATH)
    soffice = _find_libreoffice()
    if soffice is None:
        log.warning(
            "LibreOffice not found — cannot convert %s. "
            "Install from https://www.libreoffice.org/ to enable RTF and Pages conversion.",
            source_path.name,
        )
        print(
            f"  SKIPPED (LibreOffice not installed): {source_path.name}\n"
            f"  Install LibreOffice to convert RTF and Apple Pages files."
        )
        return None

    log.info("LibreOffice converting: %s", source_path.name)
    print(f"\nProcessing: {source_path.name}")
    print(f"  (via LibreOffice headless)")

    # Use a TemporaryDirectory so LO's output file is isolated and auto-cleaned
    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_dir_path = Path(tmp_dir)

        # Run LibreOffice headless conversion.
        # --norestore prevents crash-recovery dialogs in headless mode.
        # --nofirststartwizard skips the first-run setup wizard.
        try:
            result = subprocess.run(
                [
                    soffice,
                    "--headless",
                    "--norestore",
                    "--nofirststartwizard",
                    "--convert-to", target_format,
                    "--outdir", str(tmp_dir_path),
                    str(source_path),
                ],
                capture_output=True,
                text=True,
                timeout=120,  # 2-minute timeout; large documents can be slow
            )
        except subprocess.TimeoutExpired:
            log.warning("LibreOffice timed out for: %s", source_path.name)
            print(f"  SKIPPED (LibreOffice timed out): {source_path.name}")
            return None
        except Exception as exc:
            log.warning("LibreOffice failed for %s: %s", source_path.name, exc)
            print(f"  SKIPPED (LibreOffice error): {exc}")
            return None

        if result.returncode != 0:
            log.warning(
                "LibreOffice non-zero exit for %s: %s",
                source_path.name, result.stderr,
            )
            print(f"  SKIPPED (LibreOffice conversion error): {source_path.name}")
            return None

        # Expected output: <stem>.<target_format> in the temp dir
        tmp_output = tmp_dir_path / f"{source_path.stem}.{target_format}"

        if not tmp_output.exists():
            # LibreOffice occasionally uses a different stem; fall back to a glob search
            candidates = list(tmp_dir_path.glob(f"*.{target_format}"))
            if candidates:
                tmp_output = candidates[0]
                log.debug("LibreOffice output found at: %s", tmp_output)
            else:
                log.warning(
                    "LibreOffice ran but produced no %s output for: %s",
                    target_format, source_path.name,
                )
                print(f"  SKIPPED (no output from LibreOffice): {source_path.name}")
                return None

        log.info(
            "LibreOffice output: %s (%d bytes)",
            tmp_output.name, tmp_output.stat().st_size,
        )

        # Feed the temporary PDF through the existing PDF pipeline.
        # convert_pdf() uses the PDF metadata title or the file stem as fallback.
        # The LO-produced stem matches the source file stem, giving a sensible note title.
        md_path = convert_pdf(tmp_output, output_dir, overwrite)

    # TemporaryDirectory context exits here; tmp_output is automatically deleted.

    if md_path is not None:
        log.info(
            "LibreOffice conversion complete: %s -> %s",
            source_path.name, md_path.name,
        )
    return md_path


def convert_pages(pages_path: Path, output_dir: Path, overwrite: bool) -> "Path | None":
    """
    Convert an Apple Pages file (.pages) to an Obsidian Markdown note.

    Strategy (tried in order):
      1. Extract the embedded preview.pdf from the .pages ZIP archive.
         Apple Pages always embeds a PDF preview for sharing purposes.
         This avoids requiring LibreOffice for most Pages files.
      2. Fall back to LibreOffice headless if no preview.pdf is found.

    .pages files are ZIP archives.  The preview PDF lives at 'preview.pdf'
    in the archive root.  All modern Pages versions include it.

    pages_path : absolute Path to the source .pages file
    output_dir : directory where the .md note will be written
    overwrite  : if True, replace existing .md; otherwise version-suffix

    Returns the Path of the written .md file, or None on failure.
    """
    import zipfile  # standard library — always available
    import tempfile

    log.info("Processing Pages: %s", pages_path.name)
    print(f"\nProcessing: {pages_path.name}")

    # --- Strategy 1: extract the embedded PDF preview from the ZIP ---
    try:
        with zipfile.ZipFile(str(pages_path), "r") as zf:
            # zip_names: list of all file paths inside the .pages archive
            zip_names = zf.namelist()

            if "preview.pdf" in zip_names:
                log.info("Found preview.pdf inside %s", pages_path.name)
                print("  (using embedded PDF preview)")

                # Write the preview PDF to a temp file named after the source document
                # so that convert_pdf() uses the correct stem as the title fallback.
                # Name: {stem}_preview.pdf — avoids collisions in ATTACHMENTS_DIR later.
                tmp_pdf_path = Path(tempfile.gettempdir()) / f"{pages_path.stem}_preview.pdf"
                try:
                    tmp_pdf_path.write_bytes(zf.read("preview.pdf"))
                    log.info(
                        "Extracted preview.pdf (%d bytes)",
                        tmp_pdf_path.stat().st_size,
                    )
                    # convert_pdf() will treat {stem}_preview as the filename stem
                    # if no embedded title is found in the PDF metadata.
                    md_path = convert_pdf(tmp_pdf_path, output_dir, overwrite)
                    return md_path
                finally:
                    # Always clean up the temp file, even if convert_pdf() failed
                    if tmp_pdf_path.exists():
                        tmp_pdf_path.unlink(missing_ok=True)

    except zipfile.BadZipFile:
        log.warning(
            "%s does not appear to be a valid ZIP/Pages archive — trying LibreOffice",
            pages_path.name,
        )
    except Exception as exc:
        log.warning(
            "Could not read %s as a ZIP archive: %s — trying LibreOffice",
            pages_path.name, exc,
        )

    # --- Strategy 2: fall back to LibreOffice ---
    log.info("Falling back to LibreOffice for: %s", pages_path.name)
    return convert_via_libreoffice(pages_path, output_dir, overwrite)


def convert_rtf(rtf_path: Path, output_dir: Path, overwrite: bool) -> "Path | None":
    """
    Convert an RTF file to an Obsidian Markdown note.

    Strategy (tried in order):
      1. LibreOffice headless conversion — full fidelity; preserves images and tables.
      2. striprtf text-only fallback — used when LibreOffice is not installed.
         NOTE: embedded images cannot be extracted via striprtf.  A warning
         is embedded in the output note when this fallback is used.

    rtf_path   : absolute Path to the source .rtf file
    output_dir : directory where the .md note will be written
    overwrite  : if True, replace existing .md; otherwise version-suffix

    Returns the Path of the written .md file, or None on failure.
    """
    log.info("Processing RTF: %s", rtf_path.name)
    print(f"\nProcessing: {rtf_path.name}")

    # --- Strategy 1: LibreOffice (preferred — preserves images and formatting) ---
    if _find_libreoffice() is not None:
        log.info("Using LibreOffice for RTF: %s", rtf_path.name)
        return convert_via_libreoffice(rtf_path, output_dir, overwrite)

    # --- Strategy 2: striprtf text-only fallback ---
    log.info(
        "LibreOffice not found — attempting striprtf text-only fallback for: %s",
        rtf_path.name,
    )
    if not _ensure_rtf_deps():
        log.warning(
            "Neither LibreOffice nor striprtf available — cannot convert %s",
            rtf_path.name,
        )
        print(
            f"  SKIPPED (no RTF converter available): {rtf_path.name}\n"
            f"  Install LibreOffice for full fidelity, or:\n"
            f"    pip install striprtf   (text-only, no images)"
        )
        return None

    # striprtf is available — do a text-only conversion
    from striprtf.striprtf import rtf_to_text  # type: ignore

    try:
        # RTF files use 8-bit Latin-1 encoding per the RTF specification;
        # use errors='replace' so malformed bytes don't abort the conversion
        rtf_source = rtf_path.read_text(encoding="latin-1", errors="replace")
        # plain_text: all RTF control codes stripped, plain Unicode text remaining
        plain_text = rtf_to_text(rtf_source)
    except Exception as exc:
        log.warning("Could not parse RTF %s: %s", rtf_path.name, exc)
        print(f"  SKIPPED (RTF parse error): {exc}")
        return None

    # Resolve output path
    safe_stem = sanitize_filename(rtf_path.stem)
    output_dir.mkdir(parents=True, exist_ok=True)
    if overwrite:
        md_path = output_dir / f"{safe_stem}.md"
    else:
        md_path = _resolve_collision(output_dir, safe_stem)

    # Build minimal frontmatter (RTF carries very little embedded metadata)
    fm_lines = [
        "---",
        f'title: "{rtf_path.stem}"',
        f'source_rtf: "{rtf_path.name}"',
        "tags:",
        "  - rtf-import",
        "  - text-only-conversion",
        "---",
    ]
    frontmatter = "\n".join(fm_lines)

    # image_warning: reminder note embedded in the output since images were skipped
    image_warning = (
        "\n> **Note:** This RTF was converted without LibreOffice. "
        "Embedded images were **not** extracted. "
        "Install LibreOffice and re-run for full fidelity.\n"
    )

    # ---- AI readability polish ----------------------------------------------
    if _polish_enabled:
        log.info("Polishing '%s' for readability...", rtf_path.name)
        print("  Polishing for readability (AI)...")
        plain_text, polish_report = polish_markdown_body(plain_text, rtf_path.name)
        log.info(polish_report)
        print(f"  {polish_report}")
    else:
        log.debug("AI polish skipped (not enabled).")

    full_content = (
        f"{frontmatter}\n\n"
        f"# {rtf_path.stem}\n\n"
        f"{image_warning}\n"
        f"{plain_text}\n"
    )

    try:
        md_path.write_text(full_content, encoding="utf-8")
    except Exception as exc:
        log.error("Failed to write %s: %s", md_path, exc)
        print(f"  ERROR writing note: {exc}")
        return None

    log.info("RTF note written (text only): %s", md_path)
    print(f"  -> {md_path}")
    return md_path


# ---------------------------------------------------------------------------
# Universal dispatch: route by file extension to the appropriate converter
# ---------------------------------------------------------------------------

def dispatch_convert(file_path: Path, output_dir: Path, overwrite: bool) -> "Path | None":
    """
    Route a document to the correct converter based on its file extension.

    Supported extensions and their converters:
      .pdf   -> convert_pdf()          (PyMuPDF; text, tables, images)
      .docx  -> convert_docx()         (python-docx; native structured extraction)
      .rtf   -> convert_rtf()          (LibreOffice preferred; striprtf fallback)
      .pages -> convert_pages()        (ZIP preview.pdf extraction; LO fallback)

    file_path  : absolute Path to the source document
    output_dir : directory where the .md note will be written
    overwrite  : if True, replace existing .md; otherwise version-suffix

    Returns the Path of the written .md file, or None if unsupported or failed.
    """
    # ext: lowercase extension used as the dispatch key
    ext = file_path.suffix.lower()

    if ext == ".pdf":
        return convert_pdf(file_path, output_dir, overwrite)
    elif ext == ".docx":
        return convert_docx(file_path, output_dir, overwrite)
    elif ext == ".rtf":
        return convert_rtf(file_path, output_dir, overwrite)
    elif ext == ".pages":
        return convert_pages(file_path, output_dir, overwrite)
    else:
        log.warning(
            "dispatch_convert: unsupported format '%s' for: %s",
            ext, file_path.name,
        )
        return None


# ---------------------------------------------------------------------------
# Generic source-file mover (generalises _move_pdf_to_attachments)
# ---------------------------------------------------------------------------

def _move_source_to_attachments(file_path: Path) -> "Path | None":
    """
    Move a source document to ATTACHMENTS_DIR after successful conversion.

    Generalises _move_pdf_to_attachments() to handle DOCX, RTF, Pages, and any
    other format.  The original file is relocated, never deleted or overwritten.
    If a file with the same name already exists in ATTACHMENTS_DIR, the moved
    file receives a numeric suffix (_2, _3, …) to avoid collision.

    file_path : absolute Path to the source document to move
    returns   : destination Path on success, None if the move failed
    """
    ATTACHMENTS_DIR.mkdir(parents=True, exist_ok=True)

    # Skip the move if the file is already inside ATTACHMENTS_DIR (e.g. when
    # re-running --file on an attachment to regenerate the .md with AI polish).
    try:
        file_path.relative_to(ATTACHMENTS_DIR)
        log.info("Source already in attachments — move skipped: %s", file_path.name)
        return file_path
    except ValueError:
        pass  # file_path is not under ATTACHMENTS_DIR; proceed with move

    # base_stem: filename without extension, used to construct collision-free names
    base_stem = file_path.stem
    # suffix: the original file extension (e.g. ".docx", ".rtf", ".pages")
    suffix = file_path.suffix

    # Find an unused destination path in ATTACHMENTS_DIR
    dest = ATTACHMENTS_DIR / file_path.name
    if dest.exists():
        counter = 2
        while True:
            dest = ATTACHMENTS_DIR / f"{base_stem}_{counter}{suffix}"
            if not dest.exists():
                break
            counter += 1

    try:
        shutil.move(str(file_path), str(dest))
        log.info("Moved source document: %s -> %s", file_path, dest)
        print(f"  (moved to attachments: {dest})")
        return dest
    except Exception as exc:
        log.warning("Could not move %s to attachments: %s", file_path.name, exc)
        print(f"  WARNING: could not move source document: {exc}")
        return None


# ---------------------------------------------------------------------------
# AI readability polish
# ---------------------------------------------------------------------------

def polish_markdown_body(body: str, source_filename: str) -> tuple[str, str]:
    """
    Send the converted Markdown body through Claude to improve readability.

    Fixes multi-column text interleaving, broken paragraph lines, image
    repositioning, and page artifact removal (headers/footers/page numbers).

    For documents larger than POLISH_CHUNK_CHARS, each page section (separated
    by --- dividers) is polished independently to stay within API limits.

    body            : Markdown body text (no frontmatter)
    source_filename : source PDF filename, passed to the model for context

    Returns (polished_body, report_string).
    report_string is a one-line summary of the API call result for logging.
    """
    import anthropic

    # client: the Anthropic API client (reads ANTHROPIC_API_KEY from environment)
    client = anthropic.Anthropic()

    # PAGE_DIV: the exact string used between page sections in the converted output
    PAGE_DIV = "\n\n---\n\n"

    # Split the document into page sections so we can chunk large documents
    pages = body.split(PAGE_DIV)

    # Choose single-call vs per-page chunking based on total document length
    if len(body) <= POLISH_CHUNK_CHARS:
        # Small enough to polish in one API call
        chunks_to_process = [body]
        single_chunk_mode = True
    else:
        # Process each page section separately
        chunks_to_process = pages
        single_chunk_mode = False

    # polished_pieces: the reformatted content for each chunk (in order)
    polished_pieces: list[str] = []

    # Counters for the summary report
    total_in_chars  = 0   # total characters sent to the API
    total_out_chars = 0   # total characters received from the API
    failed_chunks   = 0   # number of chunks where the API call failed

    for chunk_idx, chunk in enumerate(chunks_to_process):
        # Skip empty chunks (e.g. from trailing page dividers)
        if not chunk.strip():
            polished_pieces.append(chunk)
            continue

        total_in_chars += len(chunk)

        # user_message: the full prompt body sent to the model
        user_message = (
            f"Source PDF: {source_filename}\n\n"
            f"---BEGIN CONVERTED MARKDOWN---\n{chunk}\n---END CONVERTED MARKDOWN---"
        )

        try:
            # response: the API response containing the polished markdown
            response = client.messages.create(
                model=POLISH_MODEL,
                max_tokens=8192,
                system=POLISH_SYSTEM_PROMPT,
                messages=[{"role": "user", "content": user_message}],
            )

            # polished_chunk: the reformatted text returned by the model
            polished_chunk = response.content[0].text.strip()

            # Safety check: if the model returned nothing, fall back to original
            if not polished_chunk:
                log.warning(
                    "AI polish chunk %d returned empty output — keeping original text",
                    chunk_idx + 1,
                )
                polished_chunk = chunk

            total_out_chars += len(polished_chunk)
            polished_pieces.append(polished_chunk)

            log.debug(
                "Polish chunk %d/%d: %d -> %d chars",
                chunk_idx + 1, len(chunks_to_process),
                len(chunk), len(polished_chunk),
            )

        except Exception as exc:
            # API call failed — log a warning and keep the raw text for this chunk
            log.warning(
                "AI polish failed for chunk %d of '%s': %s — keeping raw text",
                chunk_idx + 1, source_filename, exc,
            )
            polished_pieces.append(chunk)
            failed_chunks   += 1
            total_out_chars += len(chunk)

    # Reassemble the document from polished pieces
    if single_chunk_mode:
        # Single-chunk mode: the one polished piece is the full document
        polished_body = polished_pieces[0] if polished_pieces else body
    else:
        # Multi-chunk mode: rejoin page sections with the page divider
        polished_body = PAGE_DIV.join(polished_pieces)

    # Build a one-line summary for logging
    delta = total_out_chars - total_in_chars
    sign  = "+" if delta >= 0 else ""
    report = (
        f"AI polish: {len(chunks_to_process)} chunk(s), "
        f"{total_in_chars:,} -> {total_out_chars:,} chars ({sign}{delta:,})"
    )
    if failed_chunks:
        report += f", {failed_chunks} chunk(s) failed (raw text kept)"

    return polished_body, report


# ---------------------------------------------------------------------------
# Watch-mode daemon
# ---------------------------------------------------------------------------

def _run_watch_mode(output_dir: Path, overwrite: bool) -> None:
    """
    Run as an event-driven daemon that converts PDFs dropped into SCAN_DIR.

    Architecture (mirrors watch_prn_files.ps1):
      - A watchdog FileSystemEventHandler fires on every Created event in SCAN_DIR
      - The handler filters to *.pdf files only and enqueues the path
      - The main thread blocks on the queue; idle = zero CPU, zero API tokens
      - On dequeue, wait WATCH_STABLE_SECS for the file to finish writing,
        then call convert_pdf() followed by _move_pdf_to_attachments()
      - Claude polish (tokens) is called only inside convert_pdf() — never while idle

    Falls back to polling SCAN_DIR every WATCH_POLL_SECS if watchdog is unavailable.

    output_dir : where .md notes are written (VAULT_ROOT or CLIPPINGS_DIR)
    overwrite  : if True, replace existing .md files; otherwise version them
    """
    # ---- Set up a file handler so watch activity is logged to pdf_watcher.log ----
    # file_handler: writes timestamped log entries to WATCH_LOG_FILE
    file_handler = logging.FileHandler(WATCH_LOG_FILE, encoding="utf-8")
    file_handler.setFormatter(
        logging.Formatter("%(asctime)s  %(levelname)-8s  %(message)s",
                          datefmt="%Y-%m-%d %H:%M:%S")
    )
    log.addHandler(file_handler)

    log.info("==========================================")
    log.info("Document File Watcher started (PDF, DOCX, RTF, Pages)")
    log.info("Monitoring : %s", SCAN_DIR)
    log.info("Output     : %s", output_dir)
    log.info("AI polish  : %s", "enabled" if _polish_enabled else "disabled")
    log.info("==========================================")

    # pdf_queue: thread-safe queue; the watchdog callback enqueues paths here
    # and the main thread dequeues them for processing.  This keeps all
    # file-system and API work on the main thread (no locking needed).
    pdf_queue: queue.Queue = queue.Queue()

    # ---- Attempt event-driven mode (watchdog) --------------------------------
    use_watchdog = _ensure_watchdog()

    if use_watchdog:
        # Import watchdog here (after ensuring it is installed)
        from watchdog.observers import Observer  # type: ignore
        from watchdog.events import FileSystemEventHandler  # type: ignore

        class _PdfDropHandler(FileSystemEventHandler):
            """Watchdog handler: queues newly created PDF files for conversion."""

            def on_created(self, event) -> None:  # type: ignore[override]
                # event.is_directory: True when a folder (not file) was created
                if event.is_directory:
                    return

                # created_path: the full Path of the newly created file
                created_path = Path(event.src_path)

                # Only react to .pdf files dropped directly into SCAN_DIR
                # (not in subdirectories — recursive=False on the observer handles
                # this for watchdog, but we double-check just in case)
                if (created_path.suffix.lower() in SUPPORTED_EXTENSIONS
                        and created_path.parent.resolve() == SCAN_DIR.resolve()):
                    log.info("Watcher: detected %s", created_path.name)
                    pdf_queue.put(created_path)

        # observer: the watchdog thread that calls ReadDirectoryChangesW
        observer = Observer()
        # schedule(): tell the observer which directory to watch and which handler
        # recursive=False — only SCAN_DIR root, not its subdirectories
        observer.schedule(_PdfDropHandler(), str(SCAN_DIR), recursive=False)
        observer.start()
        log.info("Event-driven watcher active (watchdog / ReadDirectoryChangesW).")
    else:
        # ---- Fallback: polling mode -----------------------------------------
        # seen_paths: set of paths already processed in this session
        # Prevents re-processing files that existed before the watcher started
        seen_paths: set = set()
        for _ext in SUPPORTED_EXTENSIONS:
            seen_paths.update(SCAN_DIR.glob(f"*{_ext}"))
        log.info(
            "Polling mode active (watchdog unavailable). "
            "Interval: %ds. Pre-existing documents ignored: %d",
            WATCH_POLL_SECS, len(seen_paths)
        )

    print(f"[Doc Watcher] Monitoring {SCAN_DIR}")
    print(f"[Doc Watcher] Output  -> {output_dir}")
    print(f"[Doc Watcher] Formats: {', '.join(sorted(SUPPORTED_EXTENSIONS))}")
    print(f"[Doc Watcher] Press Ctrl+C to stop.")
    log.info("Watcher active. Press Ctrl+C to stop.")

    # ---- Main processing loop -----------------------------------------------
    try:
        while True:
            if use_watchdog:
                # Block for up to 1 second; if no new PDF arrives, loop again.
                # While blocking here: no CPU spin, no API calls — truly idle.
                try:
                    # new_pdf: path dequeued from the event handler's put() call
                    new_pdf = pdf_queue.get(timeout=1.0)
                except queue.Empty:
                    # No PDF arrived in this 1-second window — stay idle
                    continue
            else:
                # Polling fallback: sleep, then diff SCAN_DIR against seen_paths
                time.sleep(WATCH_POLL_SECS)

                # current_docs: all supported-format files currently in SCAN_DIR
                current_docs: set = set()
                for _ext in SUPPORTED_EXTENSIONS:
                    current_docs.update(SCAN_DIR.glob(f"*{_ext}"))

                # new_arrivals: files present now that weren't seen before
                new_arrivals = current_docs - seen_paths

                if not new_arrivals:
                    # Nothing new — back to sleep, still idle
                    continue

                # Process the first new arrival; the rest will be caught next loop
                new_pdf = next(iter(new_arrivals))
                seen_paths.add(new_pdf)

            # ---- We have a new PDF to process --------------------------------

            # Allow a short settle time so Windows finishes writing the file
            # before we open it with PyMuPDF (avoids partial-read errors)
            log.info("Settling %s for %.1fs...", new_pdf.name, WATCH_STABLE_SECS)
            time.sleep(WATCH_STABLE_SECS)

            # Re-check existence: the file might have been moved/deleted while
            # we were sleeping (e.g. user changed their mind)
            if not new_pdf.exists():
                log.warning("File vanished before processing: %s", new_pdf.name)
                continue

            # Convert the document — dispatch by file extension to the appropriate converter
            log.info("Converting: %s", new_pdf.name)
            print(f"\n[Doc Watcher] Converting: {new_pdf.name}")

            # md_path: the written .md note path, or None on failure/skip
            md_path = dispatch_convert(new_pdf, output_dir, overwrite)

            if md_path is not None:
                # Move the source document to 09 - Attachments so it doesn't
                # trigger the watcher again on next startup
                _move_source_to_attachments(new_pdf)
                log.info("Done: %s -> %s", new_pdf.name, md_path.name)
                print(f"[Doc Watcher] Done: {md_path.name}")
            else:
                log.warning("Conversion skipped or failed: %s", new_pdf.name)

    except KeyboardInterrupt:
        log.info("PDF watcher stopped by user (Ctrl+C).")
        print("\n[PDF Watcher] Stopped.")
    finally:
        # Clean up watchdog observer thread so the process exits cleanly
        if use_watchdog:
            observer.stop()   # signals the observer thread to stop
            observer.join()   # waits for the thread to finish
        log.info("PDF watcher shut down.")


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def main() -> int:
    """
    Parse arguments and dispatch to the appropriate mode:

      Watch mode (default): daemon that waits for new PDFs and converts them.
        Claude API is called only when a PDF arrives — never while idle.

      Once mode (--once): scan SCAN_DIR for existing PDFs, convert all, exit.

      File mode (--file): convert exactly one PDF, then exit.

    Returns 0 on success, 1 on error or if no PDFs were found in --once mode.
    """
    # ---- Argument parsing ---------------------------------------------------
    # parser: the ArgumentParser that defines the CLI surface
    parser = argparse.ArgumentParser(
        description="Convert PDF files in the Obsidian vault to Markdown notes.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python pdf_to_obsidian.py                    Watch mode (default) — daemon
  python pdf_to_obsidian.py --once             Scan vault root once and exit
  python pdf_to_obsidian.py --clippings        Output to 10 - Clippings
  python pdf_to_obsidian.py --file report.pdf  Single file, then exit
  python pdf_to_obsidian.py --overwrite        Replace existing .md files
        """,
    )

    # --once: one-shot scan of SCAN_DIR, then exit (the old default behaviour)
    parser.add_argument(
        "--once",
        action="store_true",
        help=(
            "Scan the vault root for existing PDFs, convert them all, then exit. "
            "Without this flag the script runs as a daemon (watch mode)."
        ),
    )

    # --file: process exactly one PDF (accepts relative or absolute path)
    parser.add_argument(
        "--file",
        metavar="PDF",
        help="Convert a single PDF file and exit (implies --once behaviour).",
    )

    # --clippings: route output to 10 - Clippings rather than the vault root
    parser.add_argument(
        "--clippings",
        action="store_true",
        help=f"Write notes to {CLIPPINGS_DIR} instead of the vault root.",
    )

    # --overwrite: replace existing .md files instead of versioning them
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing Markdown files. Default: create Title_2.md etc.",
    )

    # args: the parsed Namespace
    args = parser.parse_args()

    # ---- Ensure dependencies ------------------------------------------------
    _ensure_dependencies()

    # ---- Check AI polish availability --------------------------------------
    # Sets the module-level _polish_enabled flag used inside convert_pdf()
    # This is called once at startup regardless of mode — the flag then
    # controls whether polish runs inside convert_pdf() on a per-file basis.
    global _polish_enabled
    _polish_enabled = _ensure_anthropic()
    if _polish_enabled:
        log.info("AI readability polish enabled (model: %s)", POLISH_MODEL)
    else:
        log.info("AI readability polish disabled.")

    # Ensure the images directory exists before any conversion writes images
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    # output_dir: where .md notes land (same in all modes)
    output_dir = CLIPPINGS_DIR if args.clippings else VAULT_ROOT

    # ---- Route to the appropriate mode -------------------------------------

    if args.file:
        # ----------------------------------------------------------------
        # FILE MODE — convert a single PDF and exit
        # ----------------------------------------------------------------
        # single_path: resolved absolute path to the requested PDF
        single_path = Path(args.file)
        if not single_path.is_absolute():
            single_path = Path.cwd() / single_path
        if not single_path.exists():
            print(f"ERROR: File not found: {single_path}")
            return 1

        # md_path: the written .md note, or None if skipped / failed
        if single_path.suffix.lower() not in SUPPORTED_EXTENSIONS:
            print(
                f"ERROR: Unsupported format '{single_path.suffix}'. "
                f"Supported: {', '.join(sorted(SUPPORTED_EXTENSIONS))}"
            )
            return 1
        md_path = dispatch_convert(single_path, output_dir, args.overwrite)
        if md_path is not None:
            _move_source_to_attachments(single_path)
        return 0 if md_path is not None else 1

    if args.once:
        # ----------------------------------------------------------------
        # ONCE MODE — scan SCAN_DIR, convert all PDFs found, then exit
        # ----------------------------------------------------------------
        # doc_files: all supported-format files directly in SCAN_DIR (non-recursive)
        doc_files: list = []
        for _ext in SUPPORTED_EXTENSIONS:
            doc_files.extend(SCAN_DIR.glob(f"*{_ext}"))
        doc_files = sorted(doc_files)
        if not doc_files:
            print(f"No supported documents found in {SCAN_DIR}")
            print(f"  Supported extensions: {', '.join(sorted(SUPPORTED_EXTENSIONS))}")
            return 1
        print(f"Found {len(doc_files)} document(s) in {SCAN_DIR}")

        # results: list of (source_path, note_path_or_None) for the summary
        results: list[tuple[Path, Path | None]] = []

        for doc_path in doc_files:
            # md_path: the written .md note path, or None on failure/skip
            md_path = dispatch_convert(doc_path, output_dir, args.overwrite)
            results.append((doc_path, md_path))

            # Move the source document only when conversion succeeded
            if md_path is not None:
                _move_source_to_attachments(doc_path)

        # ---- Print summary -----------------------------------------------
        # success_count: PDFs that produced a note
        success_count = sum(1 for _, p in results if p is not None)
        # skip_count: PDFs that were skipped (already converted, or failed)
        skip_count = len(results) - success_count

        print(f"\n{'='*60}")
        print(f"Summary: {success_count} converted, {skip_count} skipped")
        print(f"{'='*60}")

        for pdf_path, md_path in results:
            status = "OK" if md_path else "SKIPPED"
            dest   = str(md_path) if md_path else "-"
            print(f"  [{status}]  {pdf_path.name}")
            if md_path:
                print(f"          -> {dest}")

        return 0

    # ----------------------------------------------------------------
    # WATCH MODE (default) — event-driven daemon; runs until Ctrl+C
    # Claude tokens are spent only when a PDF arrives; idle = no cost.
    # ----------------------------------------------------------------
    _run_watch_mode(output_dir, args.overwrite)
    return 0


# ---------------------------------------------------------------------------
# Entry point guard
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    sys.exit(main())
