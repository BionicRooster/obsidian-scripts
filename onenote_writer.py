"""
onenote_writer.py

Writes the converted OneNote content to the Obsidian vault.

Responsibilities:
  - Build YAML frontmatter from page metadata
  - Sanitise the page title for use as a filename
  - Avoid duplicate filenames by appending _2, _3, etc.
  - Save extracted images to the vault images folder
  - Copy attached files to the vault attachments folder
  - Write the final .md file with UTF-8 encoding (no BOM)
"""

import logging
import re
import shutil
from pathlib import Path

log = logging.getLogger(__name__)

# Characters that cannot appear in Windows filenames
_ILLEGAL_CHARS = re.compile(r'[<>:"/\\|?*\x00-\x1f]')


# ---------------------------------------------------------------------------
# Helpers (module-level, no class state needed)
# ---------------------------------------------------------------------------

def _safe_filename(name: str) -> str:
    """
    Convert an arbitrary string into a safe Windows filename by replacing
    illegal characters with underscores and stripping edge dots/spaces.

    name : input string (e.g. a OneNote page title)
    """
    cleaned = _ILLEGAL_CHARS.sub("_", name)   # swap illegal chars
    return cleaned.strip(". ")                # strip leading/trailing dots


def _build_frontmatter(metadata: dict) -> str:
    """
    Generate YAML frontmatter (the --- block) from a metadata dictionary.

    metadata keys used:
        title        — page title
        onenote_link — OneNote deep-link URI (used as 'source')
        notebook     — OneNote notebook name
        section      — OneNote section name
        created      — creation date string (YYYY-MM-DD)
        modified     — last-modified date string (YYYY-MM-DD)

    The 'onenote-import' tag is always added so imports are easy to find.
    """
    # lines: individual YAML lines that will be joined and wrapped in ---
    lines: list[str] = ["---"]

    # title: must be quoted in case it contains special YAML characters
    title = metadata.get("title", "Untitled")
    lines.append(f'title: "{title}"')

    # source: the OneNote deep-link URL (onenote:// URI)
    onenote_link = metadata.get("onenote_link", "")
    if onenote_link:
        lines.append(f'source: "{onenote_link}"')

    # notebook and section: the OneNote container hierarchy
    notebook = metadata.get("notebook", "")
    if notebook:
        lines.append(f'notebook: "{notebook}"')

    section = metadata.get("section", "")
    if section:
        lines.append(f'section: "{section}"')

    # created / modified: ISO dates from the hierarchy XML attributes
    created = metadata.get("created", "")
    if created:
        lines.append(f"created: {created}")

    modified = metadata.get("modified", "")
    if modified:
        lines.append(f"modified: {modified}")

    # tags: always include 'onenote-import' to mark the origin
    lines.append("tags:")
    lines.append("  - onenote-import")

    lines.append("---")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# ObsidianWriter
# ---------------------------------------------------------------------------

class ObsidianWriter:
    """
    Writes converted content to the Obsidian vault.

    Parameters
    ----------
    config : dict
        Must contain:
            vault_path          — absolute path to the Obsidian vault root
            import_folder       — subfolder for new notes (e.g. "10 - Clippings")
            images_folder       — subfolder for images  (e.g. "00 - Images")
            attachments_folder  — subfolder for attachments
    """

    def __init__(self, config: dict):
        # _vault: root directory of the Obsidian vault
        self._vault = Path(config["vault_path"])

        # _import_dir: destination for new Markdown notes
        self._import_dir = self._vault / config["import_folder"]

        # _images_dir: destination for extracted images
        self._images_dir = self._vault / config["images_folder"]

        # _attachments_dir: destination for attached files
        self._attachments_dir = self._vault / config.get(
            "attachments_folder", "09 - Attachments"
        )

        # Ensure all target directories exist before writing anything
        for directory in (self._import_dir, self._images_dir, self._attachments_dir):
            directory.mkdir(parents=True, exist_ok=True)

    # -----------------------------------------------------------------------
    # Properties (for ContentConverter to read)
    # -----------------------------------------------------------------------

    @property
    def images_dir(self) -> Path:
        """The resolved path to the vault images directory."""
        return self._images_dir

    @property
    def attachments_dir(self) -> Path:
        """The resolved path to the vault attachments directory."""
        return self._attachments_dir

    # -----------------------------------------------------------------------
    # Public write method
    # -----------------------------------------------------------------------

    def write(
        self,
        metadata: dict,
        body_markdown: str,
        images: list[tuple[str, bytes]],
        attachments: list[tuple[str, str]],
    ) -> Path:
        """
        Write the complete note to the vault, including all assets.

        Parameters
        ----------
        metadata        : page metadata dict (from OneNoteInterface)
        body_markdown   : converted Markdown body (from ContentConverter)
        images          : list of (filename, image_bytes) to save
        attachments     : list of (filename, source_path) to copy

        Returns the Path of the written .md file.
        """
        # 1. Save every extracted image to the images folder
        for img_filename, img_bytes in images:
            self._save_image(img_filename, img_bytes)

        # 2. Copy every attachment to the attachments folder
        for att_filename, source_path in attachments:
            self._copy_attachment(att_filename, source_path)

        # 3. Determine the output path (handles duplicates with _2, _3, ...)
        note_path = self._resolve_note_path(metadata["title"])

        # 4. Build YAML frontmatter
        frontmatter = _build_frontmatter(metadata)

        # 5. Assemble full note: frontmatter + H1 title + blank line + body
        page_title  = metadata.get("title", "Untitled")
        full_content = (
            f"{frontmatter}\n\n"
            f"# {page_title}\n\n"
            f"{body_markdown}\n"
        )

        # 6. Write with UTF-8 encoding, no BOM (Obsidian requirement)
        note_path.write_text(full_content, encoding="utf-8")
        log.info("Note written to: %s", note_path)

        return note_path

    # -----------------------------------------------------------------------
    # Asset saving helpers
    # -----------------------------------------------------------------------

    def _save_image(self, filename: str, image_bytes: bytes):
        """
        Write raw image bytes to the vault images directory.

        filename    : destination filename (e.g. "PageTitle_img_01.png")
        image_bytes : decoded binary image data
        """
        dest_path = self._images_dir / filename
        dest_path.write_bytes(image_bytes)
        log.info("Saved image: %s (%d bytes)", dest_path, len(image_bytes))

    def _copy_attachment(self, filename: str, source_path: str):
        """
        Copy an attachment from its OneNote cache location to the vault.

        filename    : destination filename in the attachments folder
        source_path : absolute path to the cached file on disk
        """
        dest_path   = self._attachments_dir / filename
        source      = Path(source_path)

        # Skip if the destination already exists and has the same size,
        # which is a quick proxy for "already copied, no change"
        if dest_path.exists() and dest_path.stat().st_size == source.stat().st_size:
            log.info("Attachment unchanged, skipping: %s", dest_path)
            return

        shutil.copy2(source_path, dest_path)
        log.info("Copied attachment: %s → %s", source_path, dest_path)

    # -----------------------------------------------------------------------
    # Filename / duplicate resolution
    # -----------------------------------------------------------------------

    def _resolve_note_path(self, title: str) -> Path:
        """
        Determine the destination .md path for a note with the given title.

        If 'Title.md' already exists, try 'Title_2.md', 'Title_3.md', etc.
        This satisfies the requirement that duplicate imports create new files
        rather than overwriting.

        title   : the page title (raw, will be sanitised)
        Returns : a Path that does not yet exist in the import folder
        """
        # base_name: filesystem-safe version of the page title
        base_name = _safe_filename(title)

        # First candidate: Title.md
        candidate = self._import_dir / f"{base_name}.md"
        if not candidate.exists():
            return candidate

        # Subsequent candidates: Title_2.md, Title_3.md, ...
        counter = 2
        while True:
            candidate = self._import_dir / f"{base_name}_{counter}.md"
            if not candidate.exists():
                return candidate
            counter += 1
