"""
onenote_to_obsidian.py

Main entry point for the OneNote → Obsidian exporter.

Orchestrates the full export pipeline:
    1. Load configuration from onenote_config.json
    2. Connect to OneNote and retrieve the currently focused page
    3. Convert the OneNote XML to Markdown
    4. Write the Markdown note (plus images and attachments) to the vault
    5. Notify the user via a Windows toast notification
    6. Open the new note in Obsidian

Usage:
    python onenote_to_obsidian.py
    — or double-click run_onenote_export.bat —
"""

import json
import logging
import os
import sys
import urllib.parse
from pathlib import Path

# ---------------------------------------------------------------------------
# Logging setup
# Must be configured before importing the other modules so their loggers
# inherit the same handler and formatter.
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)

# module-level logger for this file
log = logging.getLogger("onenote_to_obsidian")

# ---------------------------------------------------------------------------
# Local module imports
# ---------------------------------------------------------------------------

# OneNoteInterface — connects to the OneNote COM server and reads the page
from onenote_interface import OneNoteInterface

# ContentConverter — converts OneNote XML to Markdown
from onenote_converter import ContentConverter

# ObsidianWriter — writes the Markdown note and assets to the vault
from onenote_writer import ObsidianWriter


# ---------------------------------------------------------------------------
# Configuration loader
# ---------------------------------------------------------------------------

def _load_config(config_path: Path) -> dict:
    """
    Read the JSON configuration file and return it as a dict.

    config_path : absolute path to onenote_config.json

    Raises FileNotFoundError if the file is missing.
    Raises ValueError if the JSON is malformed.
    """
    if not config_path.exists():
        raise FileNotFoundError(
            f"Configuration file not found: {config_path}\n"
            "Make sure onenote_config.json is in the same folder as this script."
        )

    # raw_text: entire JSON file as a string
    raw_text = config_path.read_text(encoding="utf-8")

    try:
        config = json.loads(raw_text)
    except json.JSONDecodeError as exc:
        raise ValueError(
            f"onenote_config.json contains invalid JSON: {exc}"
        ) from exc

    # Validate required keys
    required_keys = ["vault_path", "vault_name", "import_folder", "images_folder"]
    for key in required_keys:
        if key not in config:
            raise ValueError(
                f"onenote_config.json is missing required key: '{key}'"
            )

    log.info("Configuration loaded from %s", config_path)
    return config


# ---------------------------------------------------------------------------
# Notification helper
# ---------------------------------------------------------------------------

def _notify(title: str, message: str):
    """
    Display a Windows toast notification.

    Falls back to a simple print if win10toast is not installed or fails.

    title   : notification title line
    message : notification body text
    """
    try:
        from win10toast import ToastNotifier

        # notifier: singleton ToastNotifier; threaded=False blocks until done
        notifier = ToastNotifier()
        notifier.show_toast(
            title,
            message,
            duration=6,       # seconds the toast stays visible
            threaded=True,    # non-blocking so we can open Obsidian immediately
        )
        log.info("Toast notification sent: %r", title)

    except Exception as exc:
        # Notification is non-critical; log the failure and carry on
        log.warning("Could not show toast notification: %s", exc)
        print(f"\n[Notification] {title}\n  {message}\n")


# ---------------------------------------------------------------------------
# Obsidian opener
# ---------------------------------------------------------------------------

def _open_in_obsidian(config: dict, note_path: Path):
    """
    Launch Obsidian and navigate to the newly created note.

    Uses the obsidian:// URI protocol which is registered by the Obsidian
    desktop application on installation.

    config    : the loaded configuration dict (needs 'vault_name')
    note_path : absolute Path of the written .md file
    """
    if not config.get("open_after_export", True):
        # User has opted out of auto-opening; skip silently
        log.info("open_after_export is False; skipping Obsidian launch.")
        return

    # vault_name: the Obsidian vault name (used in the URI)
    vault_name = config["vault_name"]

    # vault_root: the vault base directory as a Path
    vault_root = Path(config["vault_path"])

    # relative_path: path of the note relative to the vault root
    # Obsidian expects forward slashes and no leading slash
    try:
        relative_path = note_path.relative_to(vault_root)
    except ValueError:
        log.warning(
            "Note path %s is not inside vault %s; cannot build Obsidian URI.",
            note_path, vault_root,
        )
        return

    # file_param: URL-encoded relative path without the .md extension
    # Obsidian resolves links by note name, not full path, but using the
    # full relative path avoids ambiguity when multiple notes share a name.
    path_without_ext = relative_path.with_suffix("")
    file_param = urllib.parse.quote(str(path_without_ext).replace("\\", "/"))

    # obsidian_uri: the protocol URI that Obsidian registers on install
    obsidian_uri = f"obsidian://open?vault={urllib.parse.quote(vault_name)}&file={file_param}"

    log.info("Opening Obsidian with URI: %s", obsidian_uri)

    try:
        # os.startfile delegates to the Windows shell, which routes
        # obsidian:// URIs to the Obsidian application.
        os.startfile(obsidian_uri)
    except Exception as exc:
        log.warning("Could not open Obsidian automatically: %s", exc)
        print(f"\nOpen the note manually in Obsidian:\n  {note_path}\n")


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def main():
    """
    Run the complete OneNote → Obsidian export pipeline.

    Returns 0 on success, 1 on any handled failure.
    """

    # ------------------------------------------------------------------
    # Step 1 — Load configuration
    # ------------------------------------------------------------------

    # script_dir: the directory containing this .py file
    # All other files (config, modules) are expected in the same folder.
    script_dir = Path(__file__).parent
    config_path = script_dir / "onenote_config.json"

    try:
        config = _load_config(config_path)
    except (FileNotFoundError, ValueError) as exc:
        log.error("Configuration error: %s", exc)
        print(f"\nERROR: {exc}\n")
        return 1

    # ------------------------------------------------------------------
    # Step 2 — Connect to OneNote and retrieve the current page
    # ------------------------------------------------------------------

    log.info("Connecting to OneNote...")
    print("Connecting to OneNote...")

    try:
        # oni: live connection to the OneNote COM application
        oni = OneNoteInterface()

        # content_xml: raw OneNote page XML string including embedded images
        # metadata:    dict with title, created, modified, notebook, section,
        #              page_id, onenote_link
        content_xml, metadata = oni.get_current_page()

    except RuntimeError as exc:
        log.error("OneNote error: %s", exc)
        print(f"\nERROR: {exc}\n")
        return 1

    # page_title: human-readable title for log messages and notifications
    page_title = metadata.get("title", "Untitled")
    log.info("Exporting page: %r", page_title)
    print(f"Exporting: {page_title}")

    # ------------------------------------------------------------------
    # Step 3 — Initialise the writer (creates vault directories if needed)
    # ------------------------------------------------------------------

    try:
        # writer: handles file I/O for the vault; creates target dirs
        writer = ObsidianWriter(config)
    except Exception as exc:
        log.error("Could not initialise vault writer: %s", exc)
        print(f"\nERROR: {exc}\n")
        return 1

    # ------------------------------------------------------------------
    # Step 4 — Convert OneNote XML to Markdown
    # ------------------------------------------------------------------

    log.info("Converting page content to Markdown...")
    print("Converting content...")

    try:
        # converter: stateful converter; collects images and attachments
        # as a side effect of conversion
        converter = ContentConverter(
            images_dir=writer.images_dir,
            attachments_dir=writer.attachments_dir,
            page_title=page_title,
        )

        # body_markdown: the converted Markdown body (no frontmatter)
        body_markdown = converter.convert(content_xml)

        # collected_images:      list of (filename, image_bytes)
        # collected_attachments: list of (filename, source_path_str)
        collected_images      = converter.collected_images
        collected_attachments = converter.collected_attachments

    except Exception as exc:
        log.error("Conversion failed: %s", exc, exc_info=True)
        print(f"\nERROR during conversion: {exc}\n")
        return 1

    # ------------------------------------------------------------------
    # Step 5 — Write the note and all assets to the vault
    # ------------------------------------------------------------------

    log.info("Writing note to vault...")
    print("Writing to vault...")

    try:
        # note_path: absolute Path of the newly created .md file
        note_path = writer.write(
            metadata=metadata,
            body_markdown=body_markdown,
            images=collected_images,
            attachments=collected_attachments,
        )
    except Exception as exc:
        log.error("Write failed: %s", exc, exc_info=True)
        print(f"\nERROR writing to vault: {exc}\n")
        return 1

    log.info("Export complete: %s", note_path)
    print(f"\nExport complete!\n  {note_path}\n")

    # ------------------------------------------------------------------
    # Step 6 — Notify and open in Obsidian
    # ------------------------------------------------------------------

    # image_count: number of images saved (for the notification message)
    image_count = len(collected_images)

    # att_count: number of attachments copied
    att_count = len(collected_attachments)

    # detail: a brief summary line for the toast body
    detail_parts = []
    if image_count:
        detail_parts.append(f"{image_count} image{'s' if image_count != 1 else ''}")
    if att_count:
        detail_parts.append(f"{att_count} attachment{'s' if att_count != 1 else ''}")
    detail = (", ".join(detail_parts) + " copied") if detail_parts else "No images or attachments"

    _notify(
        title=f"Exported: {page_title}",
        message=detail,
    )

    _open_in_obsidian(config, note_path)

    return 0


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    # sys.exit propagates the return code so the .bat file can detect failure
    sys.exit(main())
