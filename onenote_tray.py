"""
onenote_tray.py

System tray icon for the OneNote → Obsidian exporter.

Sits in the Windows taskbar notification area (system tray) and provides
a one-click way to export the currently focused OneNote page to Obsidian.
Because the tray app runs in your normal desktop session it can reach
OneNote's COM server — the same limitation that blocked running the
exporter from a terminal.

Usage:
    python onenote_tray.py          # start the tray icon (stays running)
    pythonw onenote_tray.py         # same, but without a console window

To auto-start with Windows, run:
    python onenote_tray.py --install-startup
"""

import argparse
import json
import logging
import sys
import threading
import winreg
from pathlib import Path

# pystray: cross-platform system tray library
import pystray
from PIL import Image, ImageDraw

# Add the script directory to sys.path so the onenote_* modules are importable
# even when pythonw.exe is launched from a different working directory.
_SCRIPT_DIR = Path(__file__).parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

# Import the exporter pipeline modules — these run in-process so they share
# the same desktop session and COM ROT as the tray app itself.
from onenote_interface import OneNoteInterface
from onenote_converter import ContentConverter
from onenote_writer import ObsidianWriter

# Log file for diagnosing export failures (written next to this script)
_LOG_FILE = _SCRIPT_DIR / "onenote_tray.log"
logging.basicConfig(
    filename=str(_LOG_FILE),
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# CONFIG_FILE: the exporter JSON config (same folder as this script)
CONFIG_FILE = _SCRIPT_DIR / "onenote_config.json"

# STARTUP_KEY: Windows registry key for per-user startup programs
STARTUP_KEY = r"Software\Microsoft\Windows\CurrentVersion\Run"

# APP_NAME: registry value name used for the startup entry
APP_NAME = "OneNoteObsidianExport"

# ---------------------------------------------------------------------------
# Icon drawing
# ---------------------------------------------------------------------------

def _make_icon(size: int = 64) -> Image.Image:
    """
    Draw a simple icon: a dark blue square with a white 'O→' symbol.

    size : pixel dimensions of the square image (width = height)
    Returns a PIL Image suitable for pystray.Icon.
    """
    # img: RGBA canvas — transparent background then drawn rectangle
    img  = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background: dark blue rounded rectangle
    margin = size // 8
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=size // 6,
        fill=(30, 80, 160, 255),
    )

    # Foreground: white arrow "→" as a thick horizontal line + arrowhead
    cx   = size // 2          # centre x
    cy   = size // 2          # centre y
    lw   = max(2, size // 12) # line width
    aw   = size // 5          # arrowhead size

    # Horizontal shaft
    draw.line([(cx - size // 4, cy), (cx + size // 8, cy)], fill="white", width=lw)

    # Arrowhead (triangle pointing right)
    draw.polygon(
        [(cx + size // 8, cy - aw // 2),
         (cx + size // 8 + aw, cy),
         (cx + size // 8, cy + aw // 2)],
        fill="white",
    )

    return img


# ---------------------------------------------------------------------------
# Export action
# ---------------------------------------------------------------------------

_export_lock = threading.Lock()   # prevent overlapping exports

def _do_export(icon: pystray.Icon, item):
    """
    Run the full export pipeline in-process when the user clicks the icon.

    Running in-process (rather than via subprocess) means this code runs
    inside the pythonw.exe that lives in the user's desktop session.  That
    session has access to OneNote's COM Running Object Table, so
    win32com.client.GetActiveObject("OneNote.Application") succeeds here
    even though it fails from a terminal spawned by Claude Code.

    icon : the pystray Icon object (tooltip is updated to show progress)
    item : the pystray MenuItem that was clicked (not used)
    """
    # Only allow one export at a time
    if not _export_lock.acquire(blocking=False):
        return

    try:
        # CoInitialize must be called on each thread that uses COM.
        # _do_export runs in a daemon thread, so we initialize COM here
        # and uninitialize it in the finally block.
        # Use comtypes (not pythoncom) since onenote_interface now uses comtypes.
        import comtypes
        comtypes.CoInitialize()

        icon.title = "Exporting..."
        logging.info("Export started by user.")

        # --- Load config ---
        config = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))

        # --- Connect to OneNote and read the focused page ---
        oni = OneNoteInterface()
        content_xml, metadata = oni.get_current_page()
        page_title = metadata.get("title", "Untitled")
        logging.info("Exporting page: %r", page_title)
        icon.title = f"Exporting: {page_title}..."

        # --- Set up the vault writer ---
        writer = ObsidianWriter(config)

        # --- Convert XML to Markdown ---
        converter = ContentConverter(
            images_dir=writer.images_dir,
            attachments_dir=writer.attachments_dir,
            page_title=page_title,
        )
        body_markdown = converter.convert(content_xml)

        # --- Write the note ---
        note_path = writer.write(
            metadata=metadata,
            body_markdown=body_markdown,
            images=converter.collected_images,
            attachments=converter.collected_attachments,
        )

        logging.info("Export complete: %s", note_path)

        # --- Toast notification ---
        try:
            from win10toast import ToastNotifier
            ToastNotifier().show_toast(
                f"Exported: {page_title}",
                str(note_path.name),
                duration=5,
                threaded=True,
            )
        except Exception:
            pass  # toast is non-critical

        # --- Open in Obsidian ---
        import os, urllib.parse
        vault_name   = config.get("vault_name", "Main")
        vault_root   = Path(config["vault_path"])
        rel          = note_path.relative_to(vault_root).with_suffix("")
        file_param   = urllib.parse.quote(str(rel).replace("\\", "/"))
        obsidian_uri = f"obsidian://open?vault={urllib.parse.quote(vault_name)}&file={file_param}"
        if config.get("open_after_export", True):
            os.startfile(obsidian_uri)

        icon.title = "OneNote to Obsidian (ready)"

    except Exception as exc:
        logging.error("Export failed: %s", exc, exc_info=True)
        # Show a brief error in the tooltip
        icon.title = f"Error: {str(exc)[:100]}"
        try:
            import ctypes
            ctypes.windll.user32.MessageBoxW(
                0,
                f"Export failed:\n\n{exc}",
                "OneNote Obsidian Export",
                0x10,  # MB_ICONERROR
            )
        except Exception:
            pass

    finally:
        # Release COM resources on this thread before the thread exits.
        try:
            comtypes.CoUninitialize()
        except Exception:
            pass
        _export_lock.release()


# ---------------------------------------------------------------------------
# Startup registration helpers
# ---------------------------------------------------------------------------

def _install_startup():
    """
    Add the tray app to HKCU Run so it launches at Windows login.
    Uses pythonw.exe (no console window) if available, else python.exe.
    """
    # Prefer pythonw.exe — runs without a console window
    pythonw = Path(sys.executable).parent / "pythonw.exe"
    exe     = str(pythonw) if pythonw.exists() else sys.executable

    # Command stored in the registry
    cmd = f'"{exe}" "{_SCRIPT_DIR / "onenote_tray.py"}"'

    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, STARTUP_KEY,
                        0, winreg.KEY_SET_VALUE) as key:
        winreg.SetValueEx(key, APP_NAME, 0, winreg.REG_SZ, cmd)

    print(f"Startup entry added:\n  {cmd}")


def _uninstall_startup():
    """Remove the startup registry entry if it exists."""
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, STARTUP_KEY,
                            0, winreg.KEY_SET_VALUE) as key:
            winreg.DeleteValue(key, APP_NAME)
        print("Startup entry removed.")
    except FileNotFoundError:
        print("No startup entry found.")


# ---------------------------------------------------------------------------
# Tray icon setup
# ---------------------------------------------------------------------------

def _build_menu(icon: pystray.Icon) -> pystray.Menu:
    """
    Build the right-click context menu for the tray icon.

    icon : passed through so the Export item can update the tooltip
    """
    return pystray.Menu(
        # Default item (activated on left-click or Enter): export
        pystray.MenuItem(
            "Export to Obsidian",
            lambda i, item: threading.Thread(
                target=_do_export, args=(i, item), daemon=True
            ).start(),
            default=True,    # bold; also triggered by left-click
        ),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem(
            "Add to Windows startup",
            lambda i, item: _install_startup(),
        ),
        pystray.MenuItem(
            "Remove from Windows startup",
            lambda i, item: _uninstall_startup(),
        ),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem(
            "Exit",
            lambda i, item: i.stop(),
        ),
    )


def run_tray():
    """Create and run the system tray icon (blocks until Exit is chosen)."""
    icon_image = _make_icon(size=64)

    icon = pystray.Icon(
        name=APP_NAME,
        icon=icon_image,
        title="OneNote → Obsidian (ready)",
    )

    # Assign menu after icon is created so we can pass the icon reference
    icon.menu = _build_menu(icon)

    print("Tray icon started. Left-click or right-click → Export to Obsidian.")
    icon.run()   # blocks until icon.stop() is called


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="OneNote to Obsidian system tray exporter"
    )
    parser.add_argument(
        "--install-startup",
        action="store_true",
        help="Register this script to run at Windows login, then exit.",
    )
    parser.add_argument(
        "--uninstall-startup",
        action="store_true",
        help="Remove the Windows startup entry, then exit.",
    )
    args = parser.parse_args()

    if args.install_startup:
        _install_startup()
    elif args.uninstall_startup:
        _uninstall_startup()
    else:
        run_tray()
