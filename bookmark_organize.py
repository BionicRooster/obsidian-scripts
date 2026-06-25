#!/usr/bin/env python3
"""
bookmark_organize.py
Loads check_results.json, assigns each surviving bookmark to the new taxonomy,
builds a nested Chromium bookmark tree, and writes it to both browsers.
Usage: python bookmark_organize.py [--dry-run]
  --dry-run : print folder assignments without writing to browsers
"""

import argparse      # CLI flags
import json          # JSON I/O
import os            # Env vars
import sys           # stdout encoding + exit
import uuid          # GUIDs for bookmark nodes
from collections import defaultdict  # Folder grouping
from pathlib import Path             # File paths
from urllib.parse import urlparse    # Domain extraction for fallback routing

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# ─── Paths ────────────────────────────────────────────────────────────────────

WORK_DIR          = Path(os.environ["USERPROFILE"]) / "bookmark_work"
CHECK_RESULTS     = WORK_DIR / "check_results.json"
CHROME_BOOKMARKS  = Path(os.environ["LOCALAPPDATA"]) / "Google/Chrome/User Data/Default/Bookmarks"
BRAVE_BOOKMARKS   = Path(os.environ["LOCALAPPDATA"]) / "BraveSoftware/Brave-Browser/User Data/Default/Bookmarks"

# ─── Taxonomy Rules ───────────────────────────────────────────────────────────
# Each rule is (original_prefix_to_match, new_folder_path).
# First match wins. Original prefix is matched after stripping browser root
# ("Bookmarks bar > " and "Bookmarks > ").

TAXONOMY_RULES = [
    # ── WCWBF: consolidate two locations into one top-level ──
    ("Computers > WCWBF",             "WCWBF"),
    ("WCWBF",                          "WCWBF"),

    # ── Computers: reroute misplaced subfolders, keep the rest ──
    ("Computers > AI",                 "AI"),
    ("Computers > Ireland",            "Travel > Ireland"),
    ("Computers > Obsidian",           "Tools"),

    ("Computers > Software",           "Computers > Software"),
    ("Computers > Model 100",          "Computers > Model 100"),
    ("Computers > RC2014",             "Computers > RC2014"),
    ("Computers > S100",               "Computers > S100"),
    ("Computers > Education",          "Computers > Education"),
    ("Computers > Enigma",             "Computers > Enigma"),
    ("Computers > Nand2Tetris",        "Computers > Nand2Tetris"),
    ("Computers > AltairDuino",        "Computers > AltairDuino"),
    ("Computers > PiDP",               "Computers > PiDP"),
    ("Computers > Digicomp",           "Computers > Digicomp"),
    ("Computers > RC-3 Relay Computer","Computers > RC-3"),
    ("Computers > Ben Eater Kits",     "Computers > Ben Eater"),
    ("Computers > Access",             "Computers > Access"),
    ("Computers > SAP-1 Breadboard Computer", "Computers > SAP-1"),
    ("Computers > SOL 20",             "Computers > SOL 20"),
    ("Computers > OS",                 "Computers > OS"),
    ("Computers",                      "Computers"),           # catch-all

    # ── Bahá'í: absorb Faith, fix "Pilgramage" spelling ──
    ("Faith",                          "Bahai"),
    ("Bahá'í > Pilgramage",  "Bahai > Pilgrimage"),  # fix spelling
    ("Bahá'í > Election",    "Bahai > Election"),
    ("Bahá'í",              "Bahai"),

    # ── Travel: fix spelling, merge Scotland dupes ──
    ("Travel > Pilgramage",            "Travel > Pilgrimage"),  # fix spelling
    ("Travel > Scottland",             "Travel > Scotland"),    # fix spelling
    ("Travel > Scotland Ireland",      "Travel > Scotland"),    # merge duplicate
    ("Travel > Washington State",      "Travel > Washington State"),
    ("Travel > Santa Fe NM",           "Travel > Santa Fe NM"),
    ("Travel > Chicago",               "Travel > Chicago"),
    ("Travel > Japan",                 "Travel > Japan"),
    ("Travel > RV Mods",               "Travel > RV Mods"),
    ("Travel > Desert Rose",           "Travel > Desert Rose"),
    ("Travel",                         "Travel"),

    # ── FOL: keep subfolder structure; reroute QB ODBC to Treasurer ──
    ("FOL > Fundraising",              "FOL > Fundraising"),
    ("FOL > Treasurer",                "FOL > Treasurer"),
    ("FOL > LGL",                      "FOL > LGL"),
    ("FOL > CBA",                      "FOL > CBA"),
    ("FOL > ODBC FOR QB",              "FOL > Treasurer"),      # QB ODBC is treasurer tooling
    ("FOL",                            "FOL"),

    # ── Home: merge HOME + Misc > Home + Misc > Food ──
    # Misc > Home > Music subfolder goes to top-level Music, not Home > Music
    ("Misc > Home > Music",            "Music"),
    ("HOME",                           "Home"),
    ("Misc > Home",                    "Home"),
    ("Misc > Food",                    "Home"),

    # ── Business: surface from Misc ──
    ("Misc > Business",                "Business"),
    ("Misc > Finance",                 "Business"),

    # ── Shopping: cars + shopping list ──
    ("Misc > Car",                     "Shopping"),
    ("Other bookmarks > Shopping list","Shopping"),

    # ── Local: Tyler TX links ──
    ("Misc > Tyler",                   "Local"),

    # ── Tools: merge Google shortcuts in ──
    ("Tools",                          "Tools"),
    ("Google",                         "Tools"),

    # ── AI: top-level ──
    ("AI",                             "AI"),

    # ── Keep as-is ──
    ("Entertainment",                  "Entertainment"),
    ("Health",                         "Health"),
    ("Music",                          "Music"),
    ("Books",                          "Books"),
    ("Weather",                        "Weather"),
    ("Genealogy",                      "Genealogy"),

    # ── Misc catch-all for anything remaining ──
    ("Misc",                           "Misc"),
]

# Domain-based fallback for bookmarks sitting at toolbar root (no subfolder)
DOMAIN_FALLBACK = [
    # (domain_substring, new_folder)
    ("youtube.com",         "Entertainment"),
    ("netflix.com",         "Entertainment"),
    ("hulu.com",            "Entertainment"),
    ("twitch.tv",           "Entertainment"),
    ("pbs.org",             "Entertainment"),
    ("imdb.com",            "Entertainment"),
    ("reelgood.com",        "Entertainment"),

    ("google.com",          "Tools"),
    ("docs.google.com",     "Tools"),
    ("drive.google.com",    "Tools"),
    ("notebooklm.google",   "Tools"),
    ("one.google.com",      "Tools"),
    ("meet.google.com",     "Tools"),
    ("calendar.google",     "Tools"),
    ("admin.google.com",    "Tools"),
    ("onedrive.live.com",   "Tools"),

    ("github.com",          "Computers"),
    ("stackoverflow.com",   "Computers"),
    ("hackaday",            "Computers"),
    ("tindie.com",          "Computers"),

    ("bahaiteachings.org",  "Bahai"),
    ("bahai-library",       "Bahai"),
    ("wilmetteinstitute",   "Bahai"),
    ("iafi.org",            "Bahai"),

    ("folgeorgetown.org",   "FOL"),
    ("lglforms.com",        "FOL"),
    ("littlegreenlight",    "FOL"),

    ("gccmatx.com",         "WCWBF"),
    ("gtxconnect.org",      "WCWBF"),

    ("amazon.com",          "Shopping"),
    ("etsy.com",            "Shopping"),

    ("nps.gov",             "Travel"),
    ("hollandamerica.com",  "Travel"),

    ("airnow.gov",          "Weather"),
    ("weather.gov",         "Weather"),
    ("kxan.com",            "Weather"),

    ("melissa.com",         "Business"),
    ("quickbooks.intuit",   "Business"),

    ("udemy.com",           "Books"),
    ("ancestry.com",        "Genealogy"),
    ("familysearch.org",    "Genealogy"),
]


def strip_root(path):
    """Remove 'Bookmarks bar > ' and 'Bookmarks > ' prefixes from path."""
    path = path.replace("Bookmarks bar > ", "").replace("Bookmarks > ", "")
    return path.strip()


def classify(entry):
    """
    Return the new folder path for a bookmark entry.
    Uses original folder path first, falls back to URL domain.
    """
    orig_chrome = strip_root(entry.get("folder_chrome", "") or "")
    orig_brave  = strip_root(entry.get("folder_brave", "") or "")
    # Prefer Chrome folder; fall back to Brave
    orig = orig_chrome or orig_brave

    # ── Rule-based path matching ──
    for prefix, new_folder in TAXONOMY_RULES:
        if orig == prefix or orig.startswith(prefix + " > "):
            # Preserve deeper sub-levels beyond the matched prefix
            remainder = orig[len(prefix):]  # e.g. "" or " > SubSub"
            return new_folder + remainder
        # Also try case-insensitive match for Bahá'í (diacriticals may vary)
        if orig.lower() == prefix.lower() or orig.lower().startswith(prefix.lower() + " > "):
            remainder = orig[len(prefix):]
            return new_folder + remainder

    # ── Domain-based fallback (for root-level toolbar items) ──
    url    = entry.get("url", "").lower()
    domain = urlparse(url).netloc.lower()
    for fragment, folder in DOMAIN_FALLBACK:
        if fragment in domain or fragment in url:
            return folder

    # ── Last resort: keep in Misc ──
    return "Misc"


# ─── Chromium Tree Builder ────────────────────────────────────────────────────

_node_id = [200000]  # mutable ID counter (avoids collision with existing IDs)

def _next_id():
    """Return next integer ID as string."""
    _node_id[0] += 1
    return str(_node_id[0])


def make_url_node(bm):
    """Build a Chromium URL bookmark node dict."""
    return {
        "date_added":      bm.get("date_added", "13000000000000000"),
        "date_last_used":  "0",
        "guid":            str(uuid.uuid4()),
        "id":              _next_id(),
        "name":            bm.get("title", ""),
        "type":            "url",
        "url":             bm["url"],
    }


def make_folder_node(name, children):
    """Build a Chromium folder node dict."""
    return {
        "children":       children,
        "date_added":     "13000000000000000",
        "date_last_used": "0",
        "date_modified":  "0",
        "guid":           str(uuid.uuid4()),
        "id":             _next_id(),
        "name":           name,
        "type":           "folder",
    }


def build_nested_tree(flat_dict):
    """
    Convert a flat {folder_path: [bookmarks]} dict into a Chromium children list.
    Paths use " > " as level separator (e.g. "Bahá'í > Pilgrimage").
    Builds a proper nested tree — subfolders appear inside their parents.
    """
    # Build an intermediate nested dict:
    # { "FolderName": { "_bookmarks": [...], "_children": { "SubName": {...} } } }
    tree = {}

    def get_or_create(d, key):
        """Return or create a node dict at key in dict d."""
        if key not in d:
            d[key] = {"_bookmarks": [], "_children": {}}
        return d[key]

    # Insert each folder path into the nested structure
    for path, bookmarks in flat_dict.items():
        parts  = [p.strip() for p in path.split(" > ")]
        cursor = tree
        for part in parts[:-1]:
            # Navigate to the parent node's _children
            cursor = get_or_create(cursor, part)["_children"]
        leaf = parts[-1]
        get_or_create(cursor, leaf)["_bookmarks"].extend(bookmarks)

    def serialize(d):
        """Recursively serialize nested dict into Chromium children list."""
        nodes = []
        for name in sorted(d.keys()):
            node     = d[name]
            children = []
            # URL children first (sorted by title)
            for bm in sorted(node["_bookmarks"], key=lambda b: b.get("title","").lower()):
                children.append(make_url_node(bm))
            # Subfolder children
            children.extend(serialize(node["_children"]))
            nodes.append(make_folder_node(name, children))
        return nodes

    return serialize(tree)


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Classify bookmarks and write to browsers")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print folder assignments without writing to disk")
    args = parser.parse_args()

    # ── Load check results ──
    if not CHECK_RESULTS.exists():
        print(f"ERROR: {CHECK_RESULTS} not found. Run bookmark_cleanup.py --phase check first.")
        sys.exit(1)

    with open(CHECK_RESULTS, "r", encoding="utf-8") as fh:
        results = json.load(fh)

    # ── Filter out DEAD entries ──
    survivors = [r for r in results if r.get("status") != "DEAD"]
    dead_count = len(results) - len(survivors)
    print(f"Loaded {len(results)} entries. Dropped {dead_count} DEAD. {len(survivors)} surviving.")

    # ── Classify survivors into new taxonomy ──
    folders = defaultdict(list)
    for entry in survivors:
        folder = classify(entry)
        folders[folder].append(entry)

    # ── Print assignment summary ──
    print(f"\nFolder assignments ({len(folders)} folders):")
    total = 0
    for folder in sorted(folders.keys()):
        count = len(folders[folder])
        total += count
        print(f"  {count:4d}  {folder}")
    print(f"  ────")
    print(f"  {total:4d}  TOTAL")

    if args.dry_run:
        print("\n[dry-run] No files written.")
        return

    # ── Confirm browsers are closed before writing ──
    print("\n" + "="*60)
    print("READY TO WRITE TO BOTH BROWSERS")
    print("="*60)
    print("Both Chrome and Brave must be completely closed now.")
    print("Close them, then type YES to write the new bookmarks.")
    confirm = input("Continue? ").strip()
    if confirm.upper() != "YES":
        print("Aborted — no files changed.")
        sys.exit(0)

    # ── Build the Chromium children list ──
    print("\nBuilding bookmark tree...")
    folder_children = build_nested_tree(dict(folders))

    # ── Write to Chrome ──
    with open(CHROME_BOOKMARKS, "r", encoding="utf-8") as fh:
        chrome_data = json.load(fh)
    chrome_data["roots"]["bookmark_bar"]["children"] = folder_children
    chrome_data["roots"]["other"]["children"] = []
    with open(CHROME_BOOKMARKS, "w", encoding="utf-8") as fh:
        json.dump(chrome_data, fh, ensure_ascii=False, indent=3)
    print(f"Written: {CHROME_BOOKMARKS}")

    # ── Write to Brave ──
    with open(BRAVE_BOOKMARKS, "r", encoding="utf-8") as fh:
        brave_data = json.load(fh)
    brave_data["roots"]["bookmark_bar"]["children"] = folder_children
    brave_data["roots"]["other"]["children"] = []
    with open(BRAVE_BOOKMARKS, "w", encoding="utf-8") as fh:
        json.dump(brave_data, fh, ensure_ascii=False, indent=3)
    print(f"Written: {BRAVE_BOOKMARKS}")

    print(f"\nDone. {total} bookmarks in {len(folders)} folders written to both browsers.")
    print("Reopen Chrome and Brave to verify.")


if __name__ == "__main__":
    main()
