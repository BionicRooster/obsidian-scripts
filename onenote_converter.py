"""
onenote_converter.py

Converts a OneNote page XML string (as returned by GetPageContent with
PI_ALL) to Obsidian-flavoured Markdown.

Handles:
  - Quick-style headings (h1–h6) via QuickStyleDef declarations
  - Bullet and numbered lists with arbitrary nesting
  - Inline HTML within <one:T>: bold, italic, hyperlinks, strikethrough
  - Embedded images (base-64 → saved file → ![[embed]])
  - Attached files (copied to vault → [[wikilink]])
  - GFM pipe tables
  - OneNote checkbox tags → Markdown task items ([ ] / [x])

After calling convert(), the caller retrieves:
    converter.collected_images       — list of (filename, bytes)
    converter.collected_attachments  — list of (filename, source_path)
and passes them to ObsidianWriter for persistence.
"""

import base64
import html as html_mod
import logging
import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path

log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

ONE_NS = "http://schemas.microsoft.com/office/onenote/2013/onenote"

# Characters that are illegal in Windows filenames
_ILLEGAL_FILENAME_CHARS = re.compile(r'[<>:"/\\|?*\x00-\x1f]')

# OneNote tag type values that represent checkboxes / to-do items.
# Type "1" is the standard To Do checkbox; type "3" is a variant.
_TODO_TAG_TYPES = {"1", "3"}


# ---------------------------------------------------------------------------
# Module-level helpers
# ---------------------------------------------------------------------------

def _onetag(local: str) -> str:
    """Return Clark-notation '{namespace}local' for ElementTree searches."""
    return f"{{{ONE_NS}}}{local}"


def _safe_filename(name: str, max_len: int = 50) -> str:
    """
    Replace Windows-illegal filename characters with underscores and
    strip leading/trailing dots and spaces.

    name    : the raw string to sanitise (e.g. a page title)
    max_len : truncate to this many characters to keep filenames short
    """
    cleaned = _ILLEGAL_FILENAME_CHARS.sub("_", name)   # replace illegal chars
    cleaned = cleaned.strip(". ")                       # strip edge dots/spaces
    return cleaned[:max_len]                            # enforce length limit


def _strip_html_tags(html_str: str) -> str:
    """Remove every HTML tag from *html_str*, leaving only text content."""
    return re.sub(r"<[^>]+>", "", html_str)


# ---------------------------------------------------------------------------
# ContentConverter
# ---------------------------------------------------------------------------

class ContentConverter:
    """
    Converts a OneNote page XML string to Markdown.

    Parameters
    ----------
    images_dir : Path
        Directory where extracted images will be saved by the writer.
        (Needed only for filename collision awareness; actual writing
        is done by ObsidianWriter.)
    attachments_dir : Path
        Directory where attachment files will be copied by the writer.
    page_title : str
        The page title, used to generate image filenames.
    """

    def __init__(
        self,
        images_dir: Path,
        attachments_dir: Path,
        page_title: str,
    ):
        self._images_dir     = images_dir        # vault images folder
        self._attachments_dir = attachments_dir  # vault attachments folder
        self._page_title     = page_title        # used in image filenames

        # Counters for auto-numbering extracted images and attachments
        self._img_counter = 0
        self._att_counter = 0

        # Results collected during conversion — read by the caller afterward
        # Each image entry:      (dest_filename: str, image_bytes: bytes)
        self.collected_images: list[tuple[str, bytes]] = []
        # Each attachment entry: (dest_filename: str, source_path: str)
        self.collected_attachments: list[tuple[str, str]] = []

        # Maps quickStyleIndex (int) → heading level (int 1-6) or None/0
        # 0 means "skip" (page title); None means normal paragraph text.
        self._style_map: dict[int, int | None] = {}

    # -----------------------------------------------------------------------
    # Public entry point
    # -----------------------------------------------------------------------

    def convert(self, page_xml: str) -> str:
        """
        Convert the OneNote page XML string to a Markdown body string.

        page_xml : raw XML string from GetPageContent
        Returns  : Markdown string (no YAML frontmatter)
        """
        # root: the top-level <one:Page> element
        root = ET.fromstring(page_xml)

        # Build the style index → heading-level map from <one:QuickStyleDef>
        self._build_style_map(root)

        # Collect Markdown blocks from every <one:Outline> in document order
        # outlines: list of Markdown strings, one per Outline element
        outlines: list[str] = []
        for outline_el in root.findall(_onetag("Outline")):
            block = self._process_outline(outline_el)
            if block.strip():
                outlines.append(block)

        # Join outlines with a blank line between them
        return "\n\n".join(outlines).strip()

    # -----------------------------------------------------------------------
    # Style map construction
    # -----------------------------------------------------------------------

    def _build_style_map(self, root: ET.Element):
        """
        Read <one:QuickStyleDef> elements from the page root and populate
        self._style_map mapping each integer index to its heading level.

        quickStyleDef 'name' attribute values we care about:
            "PageTitle" → 0 (skip — already in frontmatter)
            "h1".."h6"  → heading levels 1–6
            "p", "cite" → None (normal text)
        """
        for qsd in root.findall(_onetag("QuickStyleDef")):
            idx  = int(qsd.get("index", -1))   # integer style index
            name = qsd.get("name", "").lower()  # e.g. "h1", "p", "pagetitle"

            if name == "pagetitle":
                self._style_map[idx] = 0      # 0 = skip in body
            elif len(name) == 2 and name[0] == "h" and name[1].isdigit():
                self._style_map[idx] = int(name[1])   # heading level 1-6
            else:
                self._style_map[idx] = None   # normal paragraph

        # Fallback: if no QuickStyleDef elements present, use positional defaults
        if not self._style_map:
            # Empirical defaults observed in OneNote 2016/2021 page exports
            self._style_map = {
                0: None,  # Normal / Body Text
                1: 0,     # Page Title — skip
                2: 1,     # Heading 1
                3: 2,     # Heading 2
                4: 3,     # Heading 3
                5: 4,     # Heading 4
                6: 5,     # Heading 5
                7: 6,     # Heading 6
            }

    # -----------------------------------------------------------------------
    # Outline processing
    # -----------------------------------------------------------------------

    def _process_outline(self, outline_el: ET.Element) -> str:
        """
        Convert one <one:Outline> element to Markdown.

        An Outline is the top-level container for content blocks on a page.
        It has a single <one:OEChildren> child holding the actual elements.

        outline_el : the <one:Outline> element
        Returns    : Markdown string for this outline block
        """
        # oe_children_el: the mandatory <one:OEChildren> wrapper element
        oe_children_el = outline_el.find(_onetag("OEChildren"))
        if oe_children_el is None:
            return ""
        return self._process_oe_children(oe_children_el, indent=0)

    def _process_oe_children(
        self,
        oe_children_el: ET.Element,
        indent: int,
    ) -> str:
        """
        Process every <one:OE> child of an <one:OEChildren> element.

        oe_children_el : the <one:OEChildren> container
        indent         : current nesting level (0 = top-level)
        Returns        : Markdown string for all child OEs joined by newlines
        """
        # parts: individual Markdown line(s) produced by each OE
        parts: list[str] = []
        for oe_el in oe_children_el.findall(_onetag("OE")):
            rendered = self._process_oe(oe_el, indent)
            if rendered:
                parts.append(rendered)
        return "\n".join(parts)

    def _process_oe(self, oe_el: ET.Element, indent: int) -> str:
        """
        Convert one <one:OE> (Outline Element) to a Markdown line or block.

        An OE can contain: text (<one:T>), an image (<one:Image>),
        a table (<one:Table>), an attached file (<one:InsertedFile>),
        a list marker (<one:List>), a tag (<one:Tag>), and/or nested
        <one:OEChildren> for sub-lists.

        oe_el  : the <one:OE> element to process
        indent : current nesting depth (used for list indentation)
        Returns: Markdown representation
        """
        # prefix: two spaces per indent level for sub-list indentation
        prefix = "  " * indent

        # ---- Determine heading level from quickStyleIndex ----
        # heading_level: int 1-6, 0 (skip), or None (normal text)
        heading_level: int | None = None
        style_idx_str = oe_el.get("quickStyleIndex")
        if style_idx_str is not None:
            style_idx    = int(style_idx_str)
            heading_level = self._style_map.get(style_idx)

        # ---- Determine list type from <one:List> child ----
        list_el   = oe_el.find(_onetag("List"))
        is_bullet   = False   # whether this OE is a bullet list item
        is_numbered = False   # whether this OE is a numbered list item
        list_number = 1       # the numeric value (for ordered lists)

        if list_el is not None:
            bullet_el = list_el.find(_onetag("Bullet"))
            number_el = list_el.find(_onetag("Number"))
            is_bullet   = bullet_el is not None
            if number_el is not None:
                is_numbered = True
                # 'text' attribute holds the numeric string ("1.", "2.", etc.)
                num_text = number_el.get("text", "1")
                try:
                    list_number = int(re.sub(r"\D", "", num_text) or "1")
                except ValueError:
                    list_number = 1

        # ---- Dispatch to the appropriate content handler ----

        img_el  = oe_el.find(_onetag("Image"))
        file_el = oe_el.find(_onetag("InsertedFile"))
        tbl_el  = oe_el.find(_onetag("Table"))

        if img_el is not None:
            # Embedded image: extract and return an Obsidian embed
            embed = self._process_image(img_el)
            result = f"{prefix}{embed}"

        elif file_el is not None:
            # Attached file: copy and return a wikilink
            link = self._process_attachment(file_el)
            result = f"{prefix}{link}"

        elif tbl_el is not None:
            # Table: convert to GFM pipe table (no indentation applied)
            result = self._process_table(tbl_el)

        else:
            # Text content (most common case)
            text = self._collect_text(oe_el)

            if heading_level == 0:
                # Page title — skip entirely (it's in the frontmatter)
                result = ""
            elif heading_level:
                # Heading 1–6
                hashes = "#" * heading_level
                result = f"{prefix}{hashes} {text}"
            elif is_bullet:
                result = f"{prefix}- {text}"
            elif is_numbered:
                result = f"{prefix}{list_number}. {text}"
            else:
                # Normal paragraph
                result = f"{prefix}{text}"

        # ---- Apply checkbox / tag formatting ----
        tag_el = oe_el.find(_onetag("Tag"))
        if tag_el is not None and result:
            result = self._apply_checkbox_tag(tag_el, result, prefix)

        # ---- Recurse into nested OEChildren (sub-lists / indented blocks) ----
        nested_el = oe_el.find(_onetag("OEChildren"))
        if nested_el is not None:
            nested_md = self._process_oe_children(nested_el, indent + 1)
            if nested_md:
                result = f"{result}\n{nested_md}"

        return result

    # -----------------------------------------------------------------------
    # Tag / checkbox
    # -----------------------------------------------------------------------

    def _apply_checkbox_tag(
        self,
        tag_el: ET.Element,
        current_line: str,
        prefix: str,
    ) -> str:
        """
        If *tag_el* is a To Do checkbox, reformat *current_line* as a
        Markdown task item:  - [ ] text  or  - [x] text.

        tag_el      : the <one:Tag> element
        current_line: the already-rendered Markdown line
        prefix      : indentation prefix (two spaces × indent level)
        Returns     : reformatted line, or original line for non-todo tags
        """
        tag_type  = tag_el.get("type", "")                          # numeric type string
        completed = tag_el.get("completed", "false").lower() == "true"

        if tag_type in _TODO_TAG_TYPES:
            check = "[x]" if completed else "[ ]"   # Obsidian task syntax
            stripped = current_line.lstrip()

            # Replace an existing "- " list marker or just prepend the task marker
            if stripped.startswith("- "):
                return f"{prefix}- {check} {stripped[2:]}"
            else:
                return f"{prefix}- {check} {stripped}"

        return current_line   # not a checkbox; return unchanged

    # -----------------------------------------------------------------------
    # Text collection and inline HTML → Markdown
    # -----------------------------------------------------------------------

    def _collect_text(self, oe_el: ET.Element) -> str:
        """
        Collect all <one:T> child text from an OE, convert inline HTML to
        Markdown, and join with a space.

        oe_el  : the <one:OE> element
        Returns: plain Markdown string for all text in the element
        """
        # text_parts: individual converted strings from each <one:T>
        text_parts: list[str] = []
        for t_el in oe_el.findall(_onetag("T")):
            raw = (t_el.text or "").strip()
            if raw:
                text_parts.append(self._html_to_markdown(raw))
        return " ".join(text_parts)

    def _html_to_markdown(self, html_str: str) -> str:
        """
        Convert OneNote inline HTML (as found inside <one:T> elements) to
        the equivalent Markdown syntax.

        OneNote uses HTML spans with inline styles for formatting, e.g.:
            <span style='font-weight:bold'>text</span>
            <a href="https://...">link text</a>

        Processing order matters: hyperlinks are converted first so that
        any formatting inside link text is handled correctly.

        html_str: raw HTML string from a <one:T> element
        Returns : Markdown string
        """
        s = html_str

        # --- 1. Hyperlinks: <a href="url">text</a> → [text](url) ---
        s = re.sub(
            r'<a\s+[^>]*href=["\']([^"\']*)["\'][^>]*>(.*?)</a>',
            lambda m: f"[{_strip_html_tags(m.group(2))}]({m.group(1)})",
            s,
            flags=re.IGNORECASE | re.DOTALL,
        )

        # --- 2. Bold via inline style (font-weight:bold) ---
        s = re.sub(
            r"<span\s+[^>]*font-weight\s*:\s*bold[^>]*>(.*?)</span>",
            lambda m: f"**{_strip_html_tags(m.group(1))}**",
            s,
            flags=re.IGNORECASE | re.DOTALL,
        )

        # --- 3. Bold via <b> or <strong> tags ---
        s = re.sub(
            r"<(?:b|strong)\b[^>]*>(.*?)</(?:b|strong)>",
            lambda m: f"**{m.group(1)}**",
            s,
            flags=re.IGNORECASE | re.DOTALL,
        )

        # --- 4. Italic via inline style (font-style:italic) ---
        s = re.sub(
            r"<span\s+[^>]*font-style\s*:\s*italic[^>]*>(.*?)</span>",
            lambda m: f"*{_strip_html_tags(m.group(1))}*",
            s,
            flags=re.IGNORECASE | re.DOTALL,
        )

        # --- 5. Italic via <i> or <em> tags ---
        s = re.sub(
            r"<(?:i|em)\b[^>]*>(.*?)</(?:i|em)>",
            lambda m: f"*{m.group(1)}*",
            s,
            flags=re.IGNORECASE | re.DOTALL,
        )

        # --- 6. Strikethrough via text-decoration:line-through ---
        s = re.sub(
            r"<span\s+[^>]*text-decoration\s*:\s*line-through[^>]*>(.*?)</span>",
            lambda m: f"~~{_strip_html_tags(m.group(1))}~~",
            s,
            flags=re.IGNORECASE | re.DOTALL,
        )

        # --- 7. Strip all remaining HTML tags ---
        s = _strip_html_tags(s)

        # --- 8. Decode HTML entities (&amp; &lt; &nbsp; etc.) ---
        s = html_mod.unescape(s)

        # --- 9. Collapse multiple spaces into one ---
        s = re.sub(r" {2,}", " ", s).strip()

        return s

    # -----------------------------------------------------------------------
    # Image handling
    # -----------------------------------------------------------------------

    def _process_image(self, img_el: ET.Element) -> str:
        """
        Extract a <one:Image> element: decode the base-64 <one:Data> content,
        record it in self.collected_images, and return an Obsidian embed.

        img_el  : the <one:Image> element
        Returns : "![[filename.ext]]" or a comment on failure
        """
        # data_el: the child element holding the base-64 image bytes
        data_el = img_el.find(_onetag("Data"))
        if data_el is None or not data_el.text:
            return "<!-- image: no data -->"

        # fmt: image format string from the 'format' attribute (default "png")
        fmt = img_el.get("format", "png").lower()
        if fmt == "jpeg":
            fmt = "jpg"   # normalise jpeg → jpg extension
        if fmt not in ("png", "jpg", "gif", "bmp", "tiff", "tif", "svg"):
            fmt = "png"   # safe fallback

        # Build a unique filename: SafePageTitle_img_NN.ext
        self._img_counter += 1
        safe_title = _safe_filename(self._page_title, max_len=40)
        filename   = f"{safe_title}_img_{self._img_counter:02d}.{fmt}"

        # Decode the base-64 string to raw bytes
        try:
            raw_b64   = data_el.text.strip()   # strip surrounding whitespace
            img_bytes = base64.b64decode(raw_b64)
        except Exception as exc:
            log.warning("Failed to decode image %s: %s", filename, exc)
            return "<!-- image: decode failed -->"

        # Record for the writer to persist
        self.collected_images.append((filename, img_bytes))
        log.info("Extracted image: %s (%d bytes)", filename, len(img_bytes))

        return f"![[{filename}]]"

    # -----------------------------------------------------------------------
    # Attachment handling
    # -----------------------------------------------------------------------

    def _process_attachment(self, file_el: ET.Element) -> str:
        """
        Handle a <one:InsertedFile> element.

        OneNote stores the local cache path of attached files in the
        'pathCache' attribute.  We record the source path and preferred
        name for the writer to copy.

        file_el : the <one:InsertedFile> element
        Returns : Obsidian wikilink "[[filename]]" or a plain-text note
        """
        # preferred_name: the display name the user gave the attachment
        preferred_name = file_el.get("preferredName", "attachment")
        # source_path: local filesystem path to the cached attachment file
        source_path    = file_el.get("pathCache", "")

        if not source_path or not os.path.exists(source_path):
            return f"📎 *Attachment: {preferred_name} (file not found on disk)*"

        self._att_counter += 1
        self.collected_attachments.append((preferred_name, source_path))
        log.info("Queued attachment: %s ← %s", preferred_name, source_path)

        return f"[[{preferred_name}]]"

    # -----------------------------------------------------------------------
    # Table handling
    # -----------------------------------------------------------------------

    def _process_table(self, table_el: ET.Element) -> str:
        """
        Convert a <one:Table> to a GFM (GitHub-Flavored Markdown) pipe table.

        The first row is treated as a header row if the table's
        'hasHeaderRow' attribute is "true"; otherwise the first data row is
        still used as the header (required by GFM syntax).

        table_el : the <one:Table> element
        Returns  : multi-line Markdown table string
        """
        # rows_md: list of rows, each a list of cell text strings
        rows_md: list[list[str]] = []

        for row_el in table_el.findall(_onetag("Row")):
            # row_cells: text content for each cell in this row
            row_cells: list[str] = []

            for cell_el in row_el.findall(_onetag("Cell")):
                # cell_parts: text from each OE inside the cell
                cell_parts: list[str] = []
                cell_children = cell_el.find(_onetag("OEChildren"))
                if cell_children is not None:
                    for oe in cell_children.findall(_onetag("OE")):
                        cell_parts.append(self._collect_text(oe))

                # Join multi-OE cells and escape pipe characters
                cell_text = " ".join(cell_parts).replace("|", "\\|")
                row_cells.append(cell_text)

            rows_md.append(row_cells)

        if not rows_md:
            return ""

        # col_count: maximum number of columns across all rows
        col_count = max(len(r) for r in rows_md)

        # Pad any shorter rows to col_count with empty strings
        for row in rows_md:
            while len(row) < col_count:
                row.append("")

        # --- Build GFM table lines ---
        def _row_str(cells: list[str]) -> str:
            """Format one table row as a pipe-delimited string."""
            return "| " + " | ".join(cells) + " |"

        # separator: the mandatory header/body divider row in GFM
        separator = "| " + " | ".join(["---"] * col_count) + " |"

        md_lines: list[str] = []
        md_lines.append(_row_str(rows_md[0]))   # first row always = header
        md_lines.append(separator)
        for data_row in rows_md[1:]:
            md_lines.append(_row_str(data_row))

        # Trailing newline ensures a blank line appears between the table and
        # the next paragraph when _process_oe_children joins parts with "\n".
        return "\n".join(md_lines) + "\n"
