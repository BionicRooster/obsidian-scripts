#!/usr/bin/env python3
"""
bookmark_cleanup.py
Phases:
  --phase merge   : parse Chrome + Brave Bookmarks, union-merge, save merged.json
  --phase check   : HTTP-check every URL in merged.json, save check_results.json
  --phase report  : print dead/suspect/ok summary from check_results.json
  --phase write   : read approved_final.json, build tree, write to both browsers
"""

import argparse          # CLI argument parsing
import json              # Bookmarks files are JSON
import os                # File paths, environment variables
import sys               # Exit on fatal errors
import time              # Timestamp for progress display
import re                # Regex for URL/title keyword matching
from collections import defaultdict  # Domain clustering
from concurrent.futures import ThreadPoolExecutor, as_completed  # Parallel HTTP checks
from pathlib import Path  # Path manipulation
from urllib.parse import urlparse  # Parse URL components for domain extraction

import requests  # HTTP requests for link validity checking
from requests.exceptions import (
    ConnectionError as ReqConnectionError,  # DNS failure, refused connection
    Timeout as ReqTimeout,                  # Request timed out
    SSLError as ReqSSLError,               # TLS/SSL handshake failure
    TooManyRedirects,                       # Redirect loop
    RequestException                        # Base class for all requests errors
)

# ─── Constants ────────────────────────────────────────────────────────────────

# Browser Bookmarks file paths
CHROME_BOOKMARKS  = Path(os.environ["LOCALAPPDATA"]) / "Google/Chrome/User Data/Default/Bookmarks"
BRAVE_BOOKMARKS   = Path(os.environ["LOCALAPPDATA"]) / "BraveSoftware/Brave-Browser/User Data/Default/Bookmarks"

# Work directory for intermediate files
WORK_DIR = Path(os.environ["USERPROFILE"]) / "bookmark_work"

# Output file paths
MERGED_JSON       = WORK_DIR / "merged.json"         # union of all bookmarks
CHECK_RESULTS     = WORK_DIR / "check_results.json"  # HTTP check outcomes
APPROVED_FINAL    = WORK_DIR / "approved_final.json" # user-edited approved set

# HTTP check settings
HTTP_TIMEOUT      = 10     # seconds per request
HTTP_WORKERS      = 25     # concurrent threads
HTTP_MAX_RETRIES  = 1      # retry count on timeout/connection error

# Fake browser User-Agent to avoid bot-rejection false positives
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/125.0.0.0 Safari/537.36"
)

# URL schemes that don't need HTTP checking (local/internal/invalid)
SKIP_SCHEMES = {"chrome", "chrome-extension", "edge", "brave", "file", "data",
                "javascript", "about", "blob", "mailto", "ftp"}

# Status codes that firmly indicate a dead link
DEAD_CODES = {404, 410}

# ─── Phase 1: Parse & Merge ───────────────────────────────────────────────────

def walk_tree(node, folder_path, entries, browser_name):
    """
    Recursively walk a bookmark tree node.
    node         : dict from parsed Bookmarks JSON
    folder_path  : string path like "Bookmarks Bar > Dev > Tools"
    entries      : list to append bookmark dicts to
    browser_name : "Chrome" or "Brave" label for provenance tracking
    """
    node_type = node.get("type", "")

    if node_type == "url":
        # Leaf bookmark entry — record it with provenance
        url   = node.get("url", "").strip()
        title = node.get("name", "").strip()
        if url:
            entries.append({
                "url":    url,
                "title":  title,
                "folder": folder_path,
                "browser": browser_name,
                "date_added": node.get("date_added", ""),
            })

    elif node_type == "folder":
        # Recurse into folder, extending the path string
        folder_name = node.get("name", "").strip()
        new_path    = f"{folder_path} > {folder_name}" if folder_path else folder_name
        for child in node.get("children", []):
            walk_tree(child, new_path, entries, browser_name)


def parse_bookmarks(file_path, browser_name):
    """
    Parse a Bookmarks JSON file and return a flat list of bookmark dicts.
    file_path    : Path to the Bookmarks file
    browser_name : Label for provenance
    """
    with open(file_path, "r", encoding="utf-8") as fh:
        data = json.load(fh)

    roots   = data.get("roots", {})
    entries = []

    # Walk bookmark_bar (primary toolbar) and other (unsorted bookmarks)
    for root_key in ("bookmark_bar", "other"):
        root_node = roots.get(root_key)
        if root_node:
            walk_tree(root_node, "", entries, browser_name)

    return entries


def union_merge(chrome_entries, brave_entries):
    """
    Produce a deduplicated union of two bookmark lists.
    Dedup key = normalized URL (lowercased, trailing-slash stripped).
    When both browsers have the same URL, prefer the longer/more-descriptive title
    and keep both folder paths for organization analysis.
    Returns a list of merged bookmark dicts.
    """
    # Build lookup by normalized URL for Chrome entries
    seen = {}  # normalized_url -> merged entry dict

    def normalize_url(url):
        """Strip trailing slash and lowercase scheme+host for dedup comparison."""
        return url.rstrip("/").lower()

    def richer_title(t1, t2):
        """Return the longer of two titles, preferring non-generic ones."""
        generic = {"New Tab", "Untitled", ""}
        if t1 in generic and t2 not in generic:
            return t2
        if t2 in generic and t1 not in generic:
            return t1
        return t1 if len(t1) >= len(t2) else t2

    for entry in chrome_entries:
        key = normalize_url(entry["url"])
        merged = {
            "url":              entry["url"],
            "title":            entry["title"],
            "folder_chrome":    entry["folder"],
            "folder_brave":     "",
            "date_added":       entry["date_added"],
            "source":           "chrome",
        }
        seen[key] = merged

    for entry in brave_entries:
        key = normalize_url(entry["url"])
        if key in seen:
            # URL exists in both — merge metadata
            existing = seen[key]
            existing["title"]        = richer_title(existing["title"], entry["title"])
            existing["folder_brave"] = entry["folder"]
            existing["source"]       = "both"
        else:
            # Brave-only entry
            merged = {
                "url":              entry["url"],
                "title":            entry["title"],
                "folder_chrome":    "",
                "folder_brave":     entry["folder"],
                "date_added":       entry["date_added"],
                "source":           "brave",
            }
            seen[key] = merged

    return list(seen.values())


def phase_merge():
    """Parse both browser files, union-merge, save to MERGED_JSON."""
    print("Parsing Chrome bookmarks...")
    chrome_entries = parse_bookmarks(CHROME_BOOKMARKS, "Chrome")
    print(f"  {len(chrome_entries)} bookmark entries found in Chrome")

    print("Parsing Brave bookmarks...")
    brave_entries = parse_bookmarks(BRAVE_BOOKMARKS, "Brave")
    print(f"  {len(brave_entries)} bookmark entries found in Brave")

    print("Union-merging...")
    merged = union_merge(chrome_entries, brave_entries)

    # Count by source for reporting
    both   = sum(1 for m in merged if m["source"] == "both")
    chrome = sum(1 for m in merged if m["source"] == "chrome")
    brave  = sum(1 for m in merged if m["source"] == "brave")
    total  = len(merged)

    print(f"\nMerge summary:")
    print(f"  Total unique bookmarks : {total}")
    print(f"  In both browsers       : {both}")
    print(f"  Chrome-only            : {chrome}")
    print(f"  Brave-only             : {brave}")

    WORK_DIR.mkdir(exist_ok=True)
    with open(MERGED_JSON, "w", encoding="utf-8") as fh:
        json.dump(merged, fh, ensure_ascii=False, indent=2)
    print(f"\nSaved to {MERGED_JSON}")

    # Print folder distribution for early org analysis
    folders = defaultdict(int)
    for m in merged:
        # Use Chrome folder if available, else Brave folder
        folder = m["folder_chrome"] or m["folder_brave"] or "(root)"
        # Only top-level folder name (up to first " > ")
        top = folder.split(" > ")[0] if folder else "(root)"
        folders[top] += 1

    print("\nTop-level folder distribution (both browsers, deduplicated):")
    for folder, count in sorted(folders.items(), key=lambda x: -x[1]):
        print(f"  {count:4d}  {folder}")


# ─── Phase 2: HTTP Validity Check ────────────────────────────────────────────

def check_url(entry):
    """
    Check a single URL for validity.
    Returns a tuple: (entry, status_label, http_code_or_error_msg)
    status_label : "OK" | "DEAD" | "SUSPECT"
    """
    url    = entry["url"]
    scheme = urlparse(url).scheme.lower()

    # Skip non-HTTP schemes entirely — not checkable with requests
    if scheme in SKIP_SCHEMES:
        return (entry, "SKIP", scheme)

    headers = {"User-Agent": USER_AGENT}
    attempt = 0

    while attempt <= HTTP_MAX_RETRIES:
        attempt += 1
        try:
            # Use HEAD first (faster, less data), fall back to GET if HEAD fails with 405
            resp = requests.head(
                url, headers=headers, timeout=HTTP_TIMEOUT,
                allow_redirects=True, verify=False
            )
            if resp.status_code == 405:
                # Server doesn't allow HEAD — try GET with stream to avoid full download
                resp = requests.get(
                    url, headers=headers, timeout=HTTP_TIMEOUT,
                    allow_redirects=True, stream=True, verify=False
                )
                resp.close()

            code = resp.status_code

            if code in DEAD_CODES:
                return (entry, "DEAD", str(code))
            elif code >= 500:
                if attempt <= HTTP_MAX_RETRIES:
                    time.sleep(1)
                    continue
                return (entry, "SUSPECT", f"HTTP {code}")
            elif code == 403:
                return (entry, "SUSPECT", "HTTP 403 (bot-blocked?)")
            else:
                return (entry, "OK", str(code))

        except ReqSSLError as e:
            return (entry, "SUSPECT", f"SSL error: {str(e)[:80]}")
        except ReqTimeout:
            if attempt <= HTTP_MAX_RETRIES:
                continue
            return (entry, "SUSPECT", "Timeout after retry")
        except ReqConnectionError as e:
            err = str(e).lower()
            # DNS failure = dead; connection refused could be dead or down
            if "name or service not known" in err or "nodename nor servname" in err \
               or "getaddrinfo failed" in err or "name resolution" in err \
               or "temporary failure in name resolution" in err:
                return (entry, "DEAD", "DNS failure")
            if "connection refused" in err:
                return (entry, "DEAD", "Connection refused")
            return (entry, "SUSPECT", f"Connection error: {str(e)[:80]}")
        except TooManyRedirects:
            return (entry, "DEAD", "Redirect loop")
        except RequestException as e:
            return (entry, "SUSPECT", f"Request error: {str(e)[:80]}")

    return (entry, "SUSPECT", "Unknown (retries exhausted)")


def phase_check():
    """Load merged.json, HTTP-check every URL, save check_results.json."""
    if not MERGED_JSON.exists():
        print(f"ERROR: {MERGED_JSON} not found. Run --phase merge first.")
        sys.exit(1)

    with open(MERGED_JSON, "r", encoding="utf-8") as fh:
        merged = json.load(fh)

    # Only check HTTP/HTTPS URLs
    to_check = [m for m in merged
                if urlparse(m["url"]).scheme.lower() not in SKIP_SCHEMES]
    skip_count = len(merged) - len(to_check)
    total      = len(to_check)

    print(f"Checking {total} URLs ({skip_count} non-HTTP skipped)...")
    print(f"Using {HTTP_WORKERS} threads, {HTTP_TIMEOUT}s timeout, {HTTP_MAX_RETRIES} retry.")
    print("This will take several minutes. Progress shown below.\n")

    results   = []
    done      = 0
    ok_count  = dead_count = suspect_count = 0

    with ThreadPoolExecutor(max_workers=HTTP_WORKERS) as pool:
        futures = {pool.submit(check_url, entry): entry for entry in to_check}
        for future in as_completed(futures):
            entry, status, detail = future.result()
            result = {**entry, "status": status, "status_detail": detail}
            results.append(result)
            done += 1

            if status == "OK":      ok_count      += 1
            elif status == "DEAD":  dead_count    += 1
            elif status == "SUSPECT": suspect_count += 1

            # Progress line every 50 URLs
            if done % 50 == 0 or done == total:
                pct = done / total * 100
                print(f"  {done}/{total} ({pct:.0f}%)  OK:{ok_count}  DEAD:{dead_count}  SUSPECT:{suspect_count}")

    # Also add back skipped entries as "SKIP"
    for m in merged:
        if urlparse(m["url"]).scheme.lower() in SKIP_SCHEMES:
            results.append({**m, "status": "SKIP", "status_detail": "non-HTTP scheme"})

    # Save full results
    with open(CHECK_RESULTS, "w", encoding="utf-8") as fh:
        json.dump(results, fh, ensure_ascii=False, indent=2)

    print(f"\nDone. Results saved to {CHECK_RESULTS}")
    print(f"\nSummary:")
    print(f"  OK      : {ok_count}")
    print(f"  DEAD    : {dead_count}")
    print(f"  SUSPECT : {suspect_count}")
    print(f"  SKIP    : {skip_count}")
    print(f"\nRun --phase report to see dead/suspect details.")


# ─── Phase 3: Report ─────────────────────────────────────────────────────────

def phase_report():
    """Print grouped dead/suspect report from check_results.json."""
    if not CHECK_RESULTS.exists():
        print(f"ERROR: {CHECK_RESULTS} not found. Run --phase check first.")
        sys.exit(1)

    with open(CHECK_RESULTS, "r", encoding="utf-8") as fh:
        results = json.load(fh)

    # Group by status
    dead    = [r for r in results if r["status"] == "DEAD"]
    suspect = [r for r in results if r["status"] == "SUSPECT"]
    ok      = [r for r in results if r["status"] == "OK"]
    skip    = [r for r in results if r["status"] == "SKIP"]

    print(f"\n{'='*70}")
    print(f"BOOKMARK VALIDITY REPORT")
    print(f"{'='*70}")
    print(f"  Total   : {len(results)}")
    print(f"  OK      : {len(ok)}")
    print(f"  DEAD    : {len(dead)}")
    print(f"  SUSPECT : {len(suspect)}")
    print(f"  SKIP    : {len(skip)}")

    def folder_label(r):
        """Return best available folder label for grouping."""
        return r.get("folder_chrome") or r.get("folder_brave") or "(root)"

    def print_group(entries, label):
        """Print a list of entries grouped by their top-level folder."""
        if not entries:
            print(f"\n  (none)")
            return
        by_folder = defaultdict(list)
        for r in entries:
            top = folder_label(r).split(" > ")[0] or "(root)"
            by_folder[top].append(r)
        for folder in sorted(by_folder.keys()):
            print(f"\n  [{folder}]")
            for r in by_folder[folder]:
                title  = r["title"][:60] or "(no title)"
                url    = r["url"][:80]
                detail = r.get("status_detail", "")
                print(f"    * {title}")
                print(f"      {url}")
                print(f"      → {detail}")

    print(f"\n{'-'*70}")
    print(f"DEAD ({len(dead)})  - safe to delete")
    print(f"{'-'*70}")
    print_group(dead, "DEAD")

    print(f"\n{'-'*70}")
    print(f"SUSPECT ({len(suspect)})  - review manually before deleting")
    print(f"{'-'*70}")
    print_group(suspect, "SUSPECT")

    # Domain clustering for organization taxonomy proposal
    print(f"\n{'='*70}")
    print(f"ORGANIZATION ANALYSIS  (top domains across OK + SUSPECT bookmarks)")
    print(f"{'='*70}")
    domain_counts = defaultdict(int)
    for r in ok + suspect:
        try:
            host = urlparse(r["url"]).netloc.lower()
            # Strip www. prefix for cleaner grouping
            host = re.sub(r'^www\.', '', host)
            domain_counts[host] += 1
        except Exception:
            pass

    print(f"\nTop 40 domains:")
    for domain, count in sorted(domain_counts.items(), key=lambda x: -x[1])[:40]:
        print(f"  {count:4d}  {domain}")

    print(f"\nExisting folder names (merged, sorted):")
    folder_counts = defaultdict(int)
    for r in results:
        for fld in [r.get("folder_chrome",""), r.get("folder_brave","")]:
            if fld:
                top = fld.split(" > ")[0]
                folder_counts[top] += 1
    for folder, count in sorted(folder_counts.items(), key=lambda x: -x[1]):
        if folder:
            print(f"  {count:3d}  {folder}")


# ─── Phase 4: Write ───────────────────────────────────────────────────────────

def build_tree(bookmarks_by_folder, root_name="Bookmarks bar"):
    """
    Build a Chromium Bookmarks tree from a dict of {folder_name: [bookmark_dicts]}.
    Returns a list of child nodes suitable for insertion under roots.bookmark_bar.
    """
    import uuid
    node_id = [100000]  # mutable counter for generating numeric IDs

    def next_id():
        node_id[0] += 1
        return str(node_id[0])

    def make_url_node(bm):
        """Create a Chromium-format URL bookmark node."""
        return {
            "date_added": bm.get("date_added", "13000000000000000"),
            "date_last_used": "0",
            "guid": str(uuid.uuid4()),
            "id": next_id(),
            "name": bm.get("title", ""),
            "type": "url",
            "url": bm["url"],
        }

    def make_folder_node(name, children):
        """Create a Chromium-format folder node."""
        return {
            "children": children,
            "date_added": "13000000000000000",
            "date_last_used": "0",
            "date_modified": "0",
            "guid": str(uuid.uuid4()),
            "id": next_id(),
            "name": name,
            "type": "folder",
        }

    # Build folder nodes from the dict
    folder_nodes = []
    for folder_name in sorted(bookmarks_by_folder.keys()):
        bm_list = bookmarks_by_folder[folder_name]
        url_nodes = [make_url_node(bm) for bm in bm_list]
        folder_nodes.append(make_folder_node(folder_name, url_nodes))

    return folder_nodes


def phase_write():
    """
    Read approved_final.json, build Chromium bookmark tree, write to both browsers.
    IMPORTANT: Both browsers must be closed before running this phase.
    """
    if not APPROVED_FINAL.exists():
        print(f"ERROR: {APPROVED_FINAL} not found.")
        print("This file should be produced by the organize phase (approved_final.json).")
        sys.exit(1)

    print("WARNING: This will overwrite the Bookmarks file in BOTH browsers.")
    print("Both Chrome and Brave must be completely closed before proceeding.")
    confirm = input("Type YES to continue: ").strip()
    if confirm != "YES":
        print("Aborted.")
        sys.exit(0)

    with open(APPROVED_FINAL, "r", encoding="utf-8") as fh:
        final_data = json.load(fh)

    # final_data expected structure: {"folders": {"FolderName": [{"url":..,"title":..},..]}}
    bookmarks_by_folder = final_data.get("folders", {})
    folder_nodes = build_tree(bookmarks_by_folder)

    # Load existing Chrome file to preserve checksums/other root structure
    with open(CHROME_BOOKMARKS, "r", encoding="utf-8") as fh:
        template = json.load(fh)

    # Replace bookmark_bar children with our new organized set
    template["roots"]["bookmark_bar"]["children"] = folder_nodes
    # Clear 'other' (unsorted) — was nearly empty anyway
    template["roots"]["other"]["children"] = []

    # Write to Chrome
    with open(CHROME_BOOKMARKS, "w", encoding="utf-8") as fh:
        json.dump(template, fh, ensure_ascii=False, indent=3)
    print(f"Written to Chrome: {CHROME_BOOKMARKS}")

    # Write same structure to Brave
    with open(BRAVE_BOOKMARKS, "r", encoding="utf-8") as fh:
        brave_template = json.load(fh)
    brave_template["roots"]["bookmark_bar"]["children"] = folder_nodes
    brave_template["roots"]["other"]["children"] = []
    with open(BRAVE_BOOKMARKS, "w", encoding="utf-8") as fh:
        json.dump(brave_template, fh, ensure_ascii=False, indent=3)
    print(f"Written to Brave: {BRAVE_BOOKMARKS}")

    total = sum(len(v) for v in bookmarks_by_folder.values())
    print(f"\nDone. {total} bookmarks in {len(bookmarks_by_folder)} folders written to both browsers.")


# ─── Entry Point ──────────────────────────────────────────────────────────────

def main():
    # Force UTF-8 output so Unicode chars in titles/URLs don't crash on Windows cp1252 consoles
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

    parser = argparse.ArgumentParser(description="Bookmark cleanup and sync tool")
    parser.add_argument(
        "--phase",
        choices=["merge", "check", "report", "write"],
        required=True,
        help="Which phase to run"
    )
    args = parser.parse_args()

    if args.phase == "merge":
        phase_merge()
    elif args.phase == "check":
        # Suppress SSL warnings (many sites have cert issues but are still "alive")
        import urllib3
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        phase_check()
    elif args.phase == "report":
        phase_report()
    elif args.phase == "write":
        phase_write()


if __name__ == "__main__":
    main()
