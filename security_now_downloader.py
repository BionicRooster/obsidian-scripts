#!/usr/bin/env python3
"""
security_now_downloader.py

Downloads Security Now! text transcripts (.txt) and PDF show notes (-notes.pdf)
from GRC.com. Skips PDF transcripts and audio files.

Run modes:
  python security_now_downloader.py              # continuous run (catch-up then weekly)
  python security_now_downloader.py --dry-run    # scrape + report what's missing, no downloads
  python security_now_downloader.py --test 5     # download 5 newest missing episodes, then exit
  python security_now_downloader.py --reset      # delete state file and rebuild from scratch

Catch-up mode:  runs every 60 seconds, newest episodes first.
Maintenance mode: runs once per Wednesday after all historical files are present.
"""

import argparse
import json
import logging
import os
import re
import sys
import time
from datetime import datetime, date
from pathlib import Path

import requests
from bs4 import BeautifulSoup

# ─── Configuration constants ──────────────────────────────────────────────────

# Local folder where all downloaded files are saved (flat, no subfolders)
DOWNLOAD_DIR = Path(r"D:\Documents\Computer Docs\Security now")

# State file: tracks per-episode download status and run mode (JSON)
STATE_FILE = DOWNLOAD_DIR / "sn_state.json"

# Log file: appended each session
LOG_FILE = DOWNLOAD_DIR / "sn_download.log"

# GRC base URL for building all download links
BASE_URL = "https://www.grc.com"

# Main archive page (lists current + recent episodes)
MAIN_PAGE_URL = f"{BASE_URL}/securitynow.htm"

# Yearly archive pages: one per year from 2005 through 2025
ARCHIVE_URL_TMPL = f"{BASE_URL}/sn/past/{{year}}.htm"
ARCHIVE_YEARS = list(range(2025, 2004, -1))  # [2025, 2024, ..., 2005]

# HTTP settings
REQUEST_TIMEOUT = 30   # seconds to wait for a single HTTP response
RETRY_WAIT      = 10   # seconds to wait before retrying a failed request once
INTER_FILE_WAIT = 30   # seconds between the two file downloads within one tick

# Loop timing
CATCHUP_TICK_SECS     = 120   # seconds between ticks during catch-up mode
MAINTENANCE_TICK_SECS = 3600  # seconds between ticks during maintenance mode (1 hour)

# Browser-like User-Agent so GRC doesn't reject the requests
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (compatible; SecurityNow-Archiver/1.0; "
        "personal archiving; +awt@2tsquared.com)"
    )
}

# ─── Status codes stored in the JSON state file ───────────────────────────────

STATUS_PENDING = "pending"  # not yet attempted
STATUS_DONE    = "done"     # file exists on disk and was verified non-empty
STATUS_NA      = "na"       # HTTP 404 — GRC doesn't have this file
STATUS_ERROR   = "error"    # network/server error on last attempt (will be retried)


# ─── Logging setup ────────────────────────────────────────────────────────────

def setup_logging() -> None:
    """Configure logging to stdout and the log file simultaneously."""
    fmt     = "[%(asctime)s] %(message)s"
    datefmt = "%Y-%m-%d %H:%M:%S"
    logging.basicConfig(
        level=logging.INFO,
        format=fmt,
        datefmt=datefmt,
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler(LOG_FILE, encoding="utf-8"),
        ],
    )


# ─── State file helpers ───────────────────────────────────────────────────────

def load_state() -> dict:
    """
    Load the download state from sn_state.json.
    Returns a fresh default dict if the file does not exist.
    """
    if STATE_FILE.exists():
        with open(STATE_FILE, "r", encoding="utf-8") as fh:
            return json.load(fh)
    # Fresh state: catch-up mode, no episodes known yet
    return {
        "mode":                  "catching_up",  # "catching_up" or "maintenance"
        "episodes":              {},              # str(ep_int) -> {"txt": status, "notes": status}
        "last_maintenance_date": None,            # ISO date string of last Wednesday run
        "master_list_built":     False,           # True once archive pages have been scraped
    }


def save_state(state: dict) -> None:
    """Write the current state dict to sn_state.json (atomic overwrite)."""
    with open(STATE_FILE, "w", encoding="utf-8") as fh:
        json.dump(state, fh, indent=2)


# ─── Episode number formatting ────────────────────────────────────────────────

def ep_to_url_str(ep: int) -> str:
    """
    Convert an episode integer to the string used in GRC URLs.
    GRC uses 3-digit zero-padding for episodes 1-99 (e.g., 'sn-001.txt')
    and plain integers for episodes 100+ (e.g., 'sn-1082.txt').
    This matches the /sn/notes-001.htm pattern observed on the 2005 archive page.
    """
    if ep < 100:
        return f"{ep:03d}"  # zero-pad to 3 digits: 1 -> "001", 42 -> "042"
    return str(ep)          # no padding needed: 125 -> "125", 1082 -> "1082"


def ep_to_filename_txt(ep: int) -> str:
    """Return the local filename for a text transcript: sn-NNN.txt"""
    return f"sn-{ep_to_url_str(ep)}.txt"


def ep_to_filename_notes(ep: int) -> str:
    """Return the local filename for a PDF show notes file: sn-NNN-notes.pdf"""
    return f"sn-{ep_to_url_str(ep)}-notes.pdf"


def ep_to_url_txt(ep: int) -> str:
    """Return the full download URL for a text transcript."""
    return f"{BASE_URL}/sn/sn-{ep_to_url_str(ep)}.txt"


def ep_to_url_notes(ep: int) -> str:
    """Return the full download URL for a PDF show notes file."""
    return f"{BASE_URL}/sn/sn-{ep_to_url_str(ep)}-notes.pdf"


# ─── HTTP helpers ─────────────────────────────────────────────────────────────

def fetch_html(url: str) -> str | None:
    """
    Fetch a GRC archive page and return its HTML as a string.
    Returns None on any HTTP error or network failure.
    """
    try:
        resp = requests.get(url, headers=HEADERS, timeout=REQUEST_TIMEOUT)
        if resp.status_code == 200:
            return resp.text
        logging.warning(f"[HTTP-{resp.status_code}] {url}")
        return None
    except requests.RequestException as exc:
        logging.error(f"[NET-ERROR] {url} — {exc}")
        return None


def download_file(url: str, dest: Path) -> str:
    """
    Download a single binary file (text or PDF) from url to dest.
    Returns one of: STATUS_DONE, STATUS_NA, STATUS_ERROR.
    Does NOT retry — caller is responsible for retry logic.
    """
    try:
        resp = requests.get(url, headers=HEADERS, timeout=REQUEST_TIMEOUT, stream=True)

        if resp.status_code == 200:
            # Write in binary mode so both .txt and .pdf files are saved faithfully
            with open(dest, "wb") as fh:
                for chunk in resp.iter_content(chunk_size=8192):
                    fh.write(chunk)
            size_kb = dest.stat().st_size // 1024
            logging.info(f"[DOWNLOAD] {dest.name}  ({size_kb} KB)")
            return STATUS_DONE

        elif resp.status_code == 404:
            # File simply doesn't exist on GRC's server — not an error
            return STATUS_NA

        else:
            logging.warning(f"[HTTP-{resp.status_code}] {url}")
            return STATUS_ERROR

    except requests.Timeout:
        logging.warning(f"[TIMEOUT] {url}")
        return STATUS_ERROR
    except requests.RequestException as exc:
        logging.error(f"[NET-ERROR] {url} — {exc}")
        return STATUS_ERROR


def download_with_retry(url: str, dest: Path, tag: str) -> str:
    """
    Attempt to download url to dest. If STATUS_ERROR, wait RETRY_WAIT seconds
    and try once more. Logs the result with the given tag prefix.
    Returns final status string.
    """
    result = download_file(url, dest)

    if result == STATUS_ERROR:
        # One automatic retry after a short wait
        logging.info(f"[RETRY] {dest.name} in {RETRY_WAIT}s...")
        time.sleep(RETRY_WAIT)
        result = download_file(url, dest)

    if result == STATUS_NA:
        logging.info(f"[{tag}_NA] {dest.name}  (404 — not on GRC server)")
    elif result == STATUS_ERROR:
        logging.warning(f"[{tag}_ERR] {dest.name}  (will retry next tick)")

    return result


# ─── Archive page scraping ────────────────────────────────────────────────────

def extract_episode_numbers(html: str) -> list[int]:
    """
    Parse episode numbers from a GRC archive HTML page.
    Looks for href attributes matching patterns like /sn/sn-1082.txt or
    /sn/sn-001-notes.pdf and extracts the integer episode number from each.
    Returns a sorted list of unique integers (ascending order).
    """
    # Match both .txt and -notes.pdf link patterns; capture the digit string
    pattern = re.compile(r'/sn/sn-(\d+)(?:\.txt|-notes\.pdf)', re.IGNORECASE)
    nums: set[int] = set()
    for match in pattern.finditer(html):
        nums.add(int(match.group(1)))  # int() strips any leading zeros
    return sorted(nums)


def build_master_list(state: dict, force: bool = False) -> dict:
    """
    Scrape all GRC archive pages and the main page to discover every episode number.
    Adds any newly found episodes to state["episodes"] with STATUS_PENDING.
    Already-known episodes are left untouched (their download progress is preserved).
    Sets state["master_list_built"] = True when complete.
    """
    if state["master_list_built"] and not force:
        logging.info("Master list already built — skipping rescrape (use --reset to force)")
        return state

    all_nums: set[int] = set()

    # Main page covers the most recent episodes (current year)
    logging.info(f"Scraping main page: {MAIN_PAGE_URL}")
    html = fetch_html(MAIN_PAGE_URL)
    if html:
        found = extract_episode_numbers(html)
        logging.info(f"  Main page: {len(found)} episode numbers")
        all_nums.update(found)

    # Each yearly archive page (newest year first)
    for year in ARCHIVE_YEARS:
        url = ARCHIVE_URL_TMPL.format(year=year)
        logging.info(f"Scraping {year} archive ({url})")
        html = fetch_html(url)
        if html:
            found = extract_episode_numbers(html)
            logging.info(f"  {year}: {len(found)} episodes")
            all_nums.update(found)
        time.sleep(1)  # 1-second pause between archive page requests — polite

    # Add newly discovered episodes with pending status; preserve existing records
    new_count = 0
    for ep in all_nums:
        key = str(ep)
        if key not in state["episodes"]:
            state["episodes"][key] = {"txt": STATUS_PENDING, "notes": STATUS_PENDING}
            new_count += 1

    total = len(state["episodes"])
    logging.info(f"Master list complete: {total} total episodes ({new_count} newly added)")
    state["master_list_built"] = True
    save_state(state)
    return state


# ─── Disk pre-scan ────────────────────────────────────────────────────────────

def prescan_disk(state: dict) -> dict:
    """
    Walk the download directory and mark any already-present files as STATUS_DONE
    in the state without actually downloading them.

    This is run once after the master list is built so that the 554+ existing
    .txt files are recognized immediately rather than being logged as [SKIP]
    one-by-one during catch-up ticks.
    """
    logging.info("Pre-scanning disk for existing files...")

    # Regex patterns to recognize valid filenames (plain integers and zero-padded)
    txt_re   = re.compile(r'^sn-(\d+)\.txt$',        re.IGNORECASE)
    notes_re = re.compile(r'^sn-(\d+)-notes\.pdf$',  re.IGNORECASE)

    txt_count = notes_count = unmatched = 0

    for f in DOWNLOAD_DIR.iterdir():
        if not f.is_file() or f.stat().st_size == 0:
            continue  # skip empty files and subdirectories

        m = txt_re.match(f.name)
        if m:
            key = str(int(m.group(1)))  # normalize "001" -> "1"
            if key in state["episodes"] and state["episodes"][key]["txt"] != STATUS_DONE:
                state["episodes"][key]["txt"] = STATUS_DONE
            txt_count += 1
            continue

        m = notes_re.match(f.name)
        if m:
            key = str(int(m.group(1)))  # normalize "001" -> "1"
            if key in state["episodes"] and state["episodes"][key]["notes"] != STATUS_DONE:
                state["episodes"][key]["notes"] = STATUS_DONE
            notes_count += 1
            continue

        # File exists but doesn't match either pattern (e.g., sn-635-notes - Unknown.pdf)
        unmatched += 1

    logging.info(
        f"Pre-scan complete: {txt_count} TXT, {notes_count} notes PDFs on disk"
        + (f", {unmatched} unrecognized files (skipped)" if unmatched else "")
    )
    save_state(state)
    return state


# ─── Per-episode download logic ───────────────────────────────────────────────

def file_on_disk(path: Path) -> bool:
    """Return True if a file exists at path with non-zero size."""
    return path.exists() and path.stat().st_size > 0


def attempt_episode(ep: int, rec: dict, dry_run: bool = False) -> dict:
    """
    Attempt to download any missing files for episode ep.
    rec: {"txt": status, "notes": status}
    Returns the updated rec dict.

    Download order: txt first, then notes.pdf (INTER_FILE_WAIT seconds apart).
    Checks disk before each download in case the file appeared outside this script.
    """
    txt_path   = DOWNLOAD_DIR / ep_to_filename_txt(ep)
    notes_path = DOWNLOAD_DIR / ep_to_filename_notes(ep)
    txt_url    = ep_to_url_txt(ep)
    notes_url  = ep_to_url_notes(ep)

    # Track whether we actually downloaded something this call (to decide whether
    # to insert the inter-file delay before downloading the notes file)
    downloaded_txt = False

    # ── Text transcript (.txt) ────────────────────────────────────────────────
    if rec["txt"] not in (STATUS_DONE, STATUS_NA):
        if file_on_disk(txt_path):
            # File appeared on disk since last scan (e.g., manual copy)
            logging.info(f"[SKIP] {txt_path.name}  (already on disk)")
            rec["txt"] = STATUS_DONE
        elif dry_run:
            print(f"  [DRY-RUN] would download: {txt_url}")
        else:
            result = download_with_retry(txt_url, txt_path, "TXT")
            rec["txt"] = result
            if result == STATUS_DONE:
                downloaded_txt = True

    # ── PDF show notes (-notes.pdf) ───────────────────────────────────────────
    if rec["notes"] not in (STATUS_DONE, STATUS_NA):
        if file_on_disk(notes_path):
            logging.info(f"[SKIP] {notes_path.name}  (already on disk)")
            rec["notes"] = STATUS_DONE
        elif dry_run:
            print(f"  [DRY-RUN] would download: {notes_url}")
        else:
            # Insert polite delay between the two downloads if txt was just fetched
            if downloaded_txt:
                time.sleep(INTER_FILE_WAIT)
            result = download_with_retry(notes_url, notes_path, "NOTES")
            rec["notes"] = result

    return rec


# ─── Progress tracking ────────────────────────────────────────────────────────

def count_progress(state: dict) -> dict:
    """
    Tally per-status counts across all episodes.
    Returns a dict with keys: total, txt_done, txt_na, txt_pending,
    notes_done, notes_na, notes_pending.
    """
    c = dict(total=len(state["episodes"]),
             txt_done=0, txt_na=0, txt_pending=0,
             notes_done=0, notes_na=0, notes_pending=0)
    for rec in state["episodes"].values():
        if   rec["txt"] == STATUS_DONE:    c["txt_done"]    += 1
        elif rec["txt"] == STATUS_NA:      c["txt_na"]      += 1
        else:                              c["txt_pending"]  += 1
        if   rec["notes"] == STATUS_DONE:  c["notes_done"]  += 1
        elif rec["notes"] == STATUS_NA:    c["notes_na"]    += 1
        else:                              c["notes_pending"]+= 1
    return c


def is_all_complete(state: dict) -> bool:
    """
    Return True when every episode has both files resolved as done or na.
    (No pending or error entries remain.)
    """
    for rec in state["episodes"].values():
        if rec["txt"]   not in (STATUS_DONE, STATUS_NA): return False
        if rec["notes"] not in (STATUS_DONE, STATUS_NA): return False
    return True


def sorted_ep_keys(state: dict, descending: bool = True) -> list[str]:
    """
    Return episode keys sorted by integer value.
    descending=True gives newest-first order (default for catch-up).
    """
    return sorted(state["episodes"].keys(), key=int, reverse=descending)


# ─── Catch-up tick ────────────────────────────────────────────────────────────

def run_catchup_tick(state: dict) -> dict:
    """
    One catch-up tick: find the single next episode with pending/error files
    and attempt to download them (txt + notes). Saves state after each episode.
    Episodes are processed newest-first.
    Returns the updated state.
    """
    for key in sorted_ep_keys(state):
        rec = state["episodes"][key]
        if rec["txt"] in (STATUS_DONE, STATUS_NA) and rec["notes"] in (STATUS_DONE, STATUS_NA):
            continue  # this episode is fully resolved, move on

        # Found an episode that needs work
        ep = int(key)
        logging.info(f"--- Episode #{ep} ---")
        state["episodes"][key] = attempt_episode(ep, rec)
        save_state(state)

        # Print a running progress summary after each episode
        p = count_progress(state)
        logging.info(
            f"[PROGRESS] TXT: {p['txt_done']} done / {p['txt_na']} NA / {p['txt_pending']} pending  |  "
            f"Notes: {p['notes_done']} done / {p['notes_na']} NA / {p['notes_pending']} pending"
        )
        return state  # one episode per tick; caller will sleep then call again

    # All episodes fully resolved — nothing to download this tick
    return state


# ─── Maintenance tick (Wednesday weekly check) ────────────────────────────────

def is_wednesday() -> bool:
    """Return True if today is Wednesday (Python weekday 2 = Wednesday)."""
    return datetime.today().weekday() == 2


def already_ran_this_week(state: dict) -> bool:
    """
    Return True if maintenance was already run during the current ISO calendar week.
    Prevents double-running when the script restarts mid-Wednesday.
    """
    last_str = state.get("last_maintenance_date")
    if not last_str:
        return False
    last_d = date.fromisoformat(last_str)
    today  = date.today()
    # Same ISO year + same ISO week number = same week
    return last_d.isocalendar()[:2] == today.isocalendar()[:2]


def run_maintenance_check(state: dict) -> dict:
    """
    Wednesday maintenance run: check for new episodes published since last week.
    Scrapes main page and the 2025 archive for new episode numbers, downloads
    any missing files, and records the run date in state.
    """
    today_str = date.today().isoformat()
    logging.info(f"[WEEKLY_CHECK] Wednesday maintenance check — {today_str}")

    # Only scrape pages that would have new episodes (main page + current year)
    current_year = datetime.today().year
    urls_to_check = [
        MAIN_PAGE_URL,
        ARCHIVE_URL_TMPL.format(year=current_year),
    ]

    new_eps: set[int] = set()
    for url in urls_to_check:
        html = fetch_html(url)
        if html:
            new_eps.update(extract_episode_numbers(html))

    # Register any newly discovered episodes
    added = 0
    for ep in new_eps:
        key = str(ep)
        if key not in state["episodes"]:
            state["episodes"][key] = {"txt": STATUS_PENDING, "notes": STATUS_PENDING}
            added += 1
    if added:
        logging.info(f"[WEEKLY_CHECK] {added} new episode(s) discovered")

    # Download files for any pending episodes
    downloaded_ep_count = 0
    for key in sorted_ep_keys(state):
        rec = state["episodes"][key]
        if rec["txt"] in (STATUS_DONE, STATUS_NA) and rec["notes"] in (STATUS_DONE, STATUS_NA):
            continue  # nothing to do for this episode
        ep = int(key)
        logging.info(f"--- Maintenance: Episode #{ep} ---")
        state["episodes"][key] = attempt_episode(ep, rec)
        downloaded_ep_count += 1
        time.sleep(INTER_FILE_WAIT)  # be polite between episodes during maintenance

    state["last_maintenance_date"] = today_str
    save_state(state)
    logging.info(
        f"[WEEKLY_CHECK] Done — {downloaded_ep_count} episode(s) had files downloaded/checked."
    )
    return state


# ─── Run modes ────────────────────────────────────────────────────────────────

def run_dry_run() -> None:
    """
    Scrape all archive pages, compute what is missing, and print a summary.
    Does not download any files. Useful for a quick sanity check.
    """
    state = load_state()
    state = build_master_list(state, force=True)  # always rescrape for dry-run
    state = prescan_disk(state)

    p = count_progress(state)
    print(f"\n{'='*62}")
    print("DRY-RUN SUMMARY — no files downloaded")
    print(f"{'='*62}")
    print(f"Total episodes in master list : {p['total']}")
    print(f"TXT   — done: {p['txt_done']:4d}  NA: {p['txt_na']:4d}  pending: {p['txt_pending']:4d}")
    print(f"Notes — done: {p['notes_done']:4d}  NA: {p['notes_na']:4d}  pending: {p['notes_pending']:4d}")

    total_to_dl = p["txt_pending"] + p["notes_pending"]
    mins_est    = total_to_dl // 2  # ~2 files per minute
    print(f"\nEstimated files to download : {total_to_dl}")
    print(f"Estimated time at 2/min     : ~{mins_est} minutes (~{mins_est//60}h {mins_est%60}m)")

    print(f"\nFirst 10 pending episodes (newest first):")
    shown = 0
    for key in sorted_ep_keys(state):
        rec = state["episodes"][key]
        if rec["txt"] in (STATUS_DONE, STATUS_NA) and rec["notes"] in (STATUS_DONE, STATUS_NA):
            continue
        ep = int(key)
        attempt_episode(ep, rec, dry_run=True)
        shown += 1
        if shown >= 10:
            break
    print(f"{'='*62}\n")


def run_test(n: int) -> None:
    """
    Download only the n newest episodes that have missing files, then exit.
    Use this to verify the script works before committing to a full run.
    """
    state = load_state()
    if not state["master_list_built"]:
        state = build_master_list(state)
    state = prescan_disk(state)

    done = 0
    for key in sorted_ep_keys(state):
        rec = state["episodes"][key]
        if rec["txt"] in (STATUS_DONE, STATUS_NA) and rec["notes"] in (STATUS_DONE, STATUS_NA):
            continue
        ep = int(key)
        logging.info(f"--- TEST: Episode #{ep} ({done+1}/{n}) ---")
        state["episodes"][key] = attempt_episode(ep, rec)
        save_state(state)
        done += 1
        if done >= n:
            break

    logging.info(f"[TEST] Complete — processed {done} episode(s). Exiting.")


def run_continuous() -> None:
    """
    Main continuous run loop.

    Phase 1 (catch-up): downloads missing files 1 episode per minute, newest first.
    Phase 2 (maintenance): checks for new episodes every Wednesday.

    The loop runs forever until killed (Ctrl-C or process termination).
    State is saved to disk after every episode so progress survives restarts.
    """
    state = load_state()

    # First run: scrape all archive pages to build the master episode list
    if not state["master_list_built"]:
        logging.info("First run detected — building episode master list from GRC archives...")
        state = build_master_list(state)
        state = prescan_disk(state)      # mark existing files done before catch-up starts
    else:
        # Still pre-scan on subsequent starts in case files were added manually
        state = prescan_disk(state)

    p = count_progress(state)
    logging.info(
        f"Starting in '{state['mode']}' mode — "
        f"{p['total']} episodes known, "
        f"{p['txt_pending'] + p['notes_pending']} file(s) still pending"
    )

    try:
        while True:
            # ── Catch-up phase ────────────────────────────────────────────────
            if state["mode"] == "catching_up":
                state = run_catchup_tick(state)

                if is_all_complete(state):
                    p = count_progress(state)
                    logging.info(
                        f"[COMPLETE] All episodes fully processed! "
                        f"TXT: {p['txt_done']} downloaded / {p['txt_na']} not on server.  "
                        f"Notes: {p['notes_done']} downloaded / {p['notes_na']} not on server.  "
                        f"Switching to weekly maintenance mode."
                    )
                    state["mode"] = "maintenance"
                    save_state(state)
                    time.sleep(MAINTENANCE_TICK_SECS)
                else:
                    time.sleep(CATCHUP_TICK_SECS)

            # ── Maintenance phase ─────────────────────────────────────────────
            elif state["mode"] == "maintenance":
                if is_wednesday() and not already_ran_this_week(state):
                    state = run_maintenance_check(state)
                else:
                    reason = (
                        "already ran this week"
                        if is_wednesday()
                        else f"today is {datetime.today().strftime('%A')} — waiting for Wednesday"
                    )
                    logging.info(f"[MAINTENANCE] Standing by ({reason})")

                time.sleep(MAINTENANCE_TICK_SECS)

    except KeyboardInterrupt:
        logging.info("[STOPPED] Interrupted by user. Progress saved.")
        sys.exit(0)


# ─── CLI argument parsing ─────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Security Now! transcript and show-notes downloader",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python security_now_downloader.py              # continuous run\n"
            "  python security_now_downloader.py --dry-run    # preview only\n"
            "  python security_now_downloader.py --test 5     # download 5 episodes\n"
            "  python security_now_downloader.py --reset      # wipe state and restart\n"
        )
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Show what would be downloaded without downloading anything"
    )
    parser.add_argument(
        "--test", type=int, metavar="N",
        help="Download the N newest episodes with missing files, then exit"
    )
    parser.add_argument(
        "--reset", action="store_true",
        help="Delete the state file so the master list is rebuilt from scratch"
    )
    args = parser.parse_args()

    # Ensure the download folder exists before setting up logging (log file lives there)
    DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
    setup_logging()

    if args.reset:
        if STATE_FILE.exists():
            STATE_FILE.unlink()
            logging.info("[RESET] State file deleted — will rebuild master list on next run")

    if args.dry_run:
        run_dry_run()
    elif args.test:
        run_test(args.test)
    else:
        run_continuous()


if __name__ == "__main__":
    main()
