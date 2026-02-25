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
import atexit
import json
import logging
import os
import subprocess
import sys
import threading
import time
import winreg
from pathlib import Path

import ctypes
import ctypes.wintypes

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

# PID_FILE: written on startup to track the running instance's process ID.
# Used by _ensure_single_instance() to detect and kill a previous copy.
PID_FILE = _SCRIPT_DIR / "onenote_tray.pid"


# ---------------------------------------------------------------------------
# Single-instance enforcement
# ---------------------------------------------------------------------------

def _cleanup_pid_file():
    """
    Delete the PID file if it still contains this process's PID.
    Registered with atexit so it runs on any clean shutdown.
    """
    try:
        if PID_FILE.exists() and PID_FILE.read_text().strip() == str(os.getpid()):
            PID_FILE.unlink()
    except Exception:
        pass  # best-effort only


def _ensure_single_instance():
    """
    Enforce only one running tray instance at a time.

    Reads the PID file left by any previous instance.  If that process is
    still alive it is killed via taskkill, so the new instance can take over
    without the user needing to right-click → Exit first.

    After handling any old instance, writes this process's PID to the PID
    file and registers _cleanup_pid_file() with atexit.
    """
    if PID_FILE.exists():
        try:
            # old_pid: the PID written by the previous instance
            old_pid = int(PID_FILE.read_text().strip())

            # Check if the process is alive using tasklist (os.kill(pid,0) is
            # unreliable on Windows and raises SystemError in some Python builds)
            result = subprocess.run(
                ["tasklist", "/FI", f"PID eq {old_pid}", "/FO", "CSV", "/NH"],
                capture_output=True, text=True,
            )
            # tasklist outputs the PID in the CSV row if the process exists
            process_alive = str(old_pid) in result.stdout

            if process_alive:
                # Still alive — force-kill it and wait briefly for Windows cleanup
                logging.info("Stopping previous instance (PID %d).", old_pid)
                subprocess.run(
                    ["taskkill", "/F", "/PID", str(old_pid)],
                    capture_output=True,   # suppress taskkill's stdout/stderr
                )
                time.sleep(0.5)   # give Windows time to remove the process

        except (ValueError, OSError):
            # PID file is corrupt, or the old process is already gone — fine
            pass

    # Write this instance's PID so the next launch can find and kill us
    PID_FILE.write_text(str(os.getpid()))

    # Remove the PID file when we exit normally (Exit menu item or exception)
    atexit.register(_cleanup_pid_file)


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
        import urllib.parse
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
# Global hotkey (Windows RegisterHotKey API — no admin required)
# ---------------------------------------------------------------------------

# Windows modifier flag constants for RegisterHotKey
_MOD_ALT     = 0x0001
_MOD_CONTROL = 0x0002
_MOD_SHIFT   = 0x0004
_MOD_WIN     = 0x0008

# WM_HOTKEY: Windows message posted to the thread when the hotkey fires
_WM_HOTKEY = 0x0312

# _MOD_MAP: human-readable modifier names → Windows flag values
_MOD_MAP = {
    "ctrl":    _MOD_CONTROL,
    "control": _MOD_CONTROL,
    "alt":     _MOD_ALT,
    "shift":   _MOD_SHIFT,
    "win":     _MOD_WIN,
}

# _VK_MAP: named non-modifier keys → Windows virtual-key codes
_VK_MAP = {
    **{f"f{i}": 0x6F + i for i in range(1, 13)},   # F1–F12
    "space": 0x20, "enter": 0x0D, "tab": 0x09,
    "esc": 0x1B,   "escape": 0x1B,
    "backspace": 0x08, "delete": 0x2E, "insert": 0x2D,
    "home": 0x24,  "end": 0x23,
    "pageup": 0x21, "pagedown": 0x22,
    "up": 0x26, "down": 0x28, "left": 0x25, "right": 0x27,
}


def _parse_hotkey(combo: str):
    """
    Parse a hotkey string like 'ctrl+shift+o' into (mod_flags, vk_code).

    combo    : plus-separated key names (case-insensitive)
    Returns  : (modifier_flags: int, virtual_key_code: int)
    Raises   : ValueError if the string is not parseable
    """
    parts    = [p.strip().lower() for p in combo.split("+")]
    mod_flags = 0    # accumulated modifier bitflags
    vk_code   = None # virtual-key code for the main (non-modifier) key

    for part in parts:
        if part in _MOD_MAP:
            mod_flags |= _MOD_MAP[part]
        elif part in _VK_MAP:
            vk_code = _VK_MAP[part]
        elif len(part) == 1 and part.isalnum():
            # Single letter or digit — map to its uppercase ASCII code
            vk_code = ord(part.upper())
        else:
            raise ValueError(f"Unknown key token: {part!r}")

    if vk_code is None:
        raise ValueError(f"No non-modifier key found in hotkey: {combo!r}")

    return mod_flags, vk_code


def _register_hotkey(icon: pystray.Icon) -> None:
    """
    Register a system-wide hotkey using the Windows RegisterHotKey API.

    Runs a Windows message loop in this thread so WM_HOTKEY messages are
    delivered.  Blocks forever (designed to run in a daemon thread).

    icon : the live pystray Icon — passed to _do_export for tooltip updates
    """
    try:
        # Read hotkey combo from config; fall back to ctrl+shift+o
        config = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        combo  = config.get("hotkey", "ctrl+shift+o")  # combo: key string from config

        mod_flags, vk_code = _parse_hotkey(combo)

        # HOTKEY_ID: arbitrary integer identifier used to match WM_HOTKEY messages
        HOTKEY_ID = 1

        # RegisterHotKey(hwnd=None → thread msg, id, modifiers, vk)
        # Returns nonzero on success, 0 on failure (e.g. combo already taken)
        ok = ctypes.windll.user32.RegisterHotKey(None, HOTKEY_ID, mod_flags, vk_code)
        if not ok:
            err = ctypes.windll.kernel32.GetLastError()
            logging.error(
                "RegisterHotKey failed for %r (mod=0x%X vk=0x%X) error=%d",
                combo, mod_flags, vk_code, err,
            )
            return

        logging.info("Global hotkey registered: %s (mod=0x%X vk=0x%X)", combo, mod_flags, vk_code)

        # Windows message loop — blocks until the thread is terminated
        msg = ctypes.wintypes.MSG()
        while ctypes.windll.user32.GetMessageW(ctypes.byref(msg), None, 0, 0) != 0:
            if msg.message == _WM_HOTKEY and msg.wParam == HOTKEY_ID:
                logging.info("Global hotkey (%s) fired — starting export.", combo)
                threading.Thread(
                    target=_do_export, args=(icon, None), daemon=True
                ).start()
            ctypes.windll.user32.TranslateMessage(ctypes.byref(msg))
            ctypes.windll.user32.DispatchMessageW(ctypes.byref(msg))

        ctypes.windll.user32.UnregisterHotKey(None, HOTKEY_ID)

    except Exception as exc:
        logging.error("Global hotkey thread error: %s", exc, exc_info=True)


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
    # Kill any existing instance and claim the PID file before creating the icon
    _ensure_single_instance()

    icon_image = _make_icon(size=64)

    icon = pystray.Icon(
        name=APP_NAME,
        icon=icon_image,
        title="OneNote → Obsidian (ready)",
    )

    # Assign menu after icon is created so we can pass the icon reference
    icon.menu = _build_menu(icon)

    # Start global hotkey listener in a background daemon thread.
    # Daemon=True means it dies automatically when the main thread exits.
    hotkey_thread = threading.Thread(target=_register_hotkey, args=(icon,), daemon=True)
    hotkey_thread.start()

    # Print startup message only when stdout is available (python.exe, not pythonw.exe)
    if sys.stdout is not None:
        try:
            print("Tray icon started. Right-click -> Export to Obsidian.")
        except Exception:
            pass
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
