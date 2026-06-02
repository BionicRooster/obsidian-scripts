# -*- coding: utf-8 -*-
"""
bahai_quotes_to_vault.py

Extracts "Baha'i Quote" emails from eM Client's local SQLite databases
and writes one Obsidian note per calendar month to the vault.

Usage:
  python bahai_quotes_to_vault.py              # process prior month (scheduled use)
  python bahai_quotes_to_vault.py --month 2025-03  # process one specific month
  python bahai_quotes_to_vault.py --all        # process all months (full rebuild)

Body source: mail_fti.dat -> LocalMailsIndex3_content.c2content (c0id = mail item id)
Date source: mail_index.dat -> MailItems.date (.NET DateTime ticks, epoch = 0001-01-01)
Output:      D:\\Obsidian\\Main\\01\\Bahá'í\\Daily Quotes\\yyyy-mm.md
"""

import sqlite3
import re
import sys
import argparse
import calendar
from datetime import datetime, timedelta
from pathlib import Path
from collections import defaultdict

# --- Configuration ---

# Root directory of all eM Client account UUID folders
EMCLIENT_DIR = Path(r"C:\Users\awt\AppData\Roaming\eM Client")

# Vault output folder; created if absent
VAULT_OUTPUT = Path(r"D:\Obsidian\Main\01\Bahá'í\Daily Quotes")

# Bahá'í Faith MOC to update with Daily Quotes section
MOC_PATH = Path(r"D:\Obsidian\Main\00 - Home Dashboard\MOC - Bahá'í Faith.md")

# Anchor before which the ## Daily Quotes section is inserted
MOC_ANCHOR = "## Bahá'í Books & Resources"

# Today's date for the YAML frontmatter
TODAY = datetime.now().strftime("%Y-%m-%d")

# Regex that matches the existing ## Daily Quotes section in the MOC
# Captures everything from the heading up to (but not including) the next ## heading or end of file
EXISTING_SECTION_RE = re.compile(
    r'^## Daily Quotes\n.*?(?=^## |\Z)',
    re.MULTILINE | re.DOTALL
)

# Regex to extract a single wikilink line from the Daily Quotes section:
# matches lines like:  - [[2024-03|March 2024]]
LINK_LINE_RE = re.compile(r'^\s*-\s+\[\[(\d{4}-\d{2})\|[^\]]+\]\]\s*$')

# -------------------------------------------------------------------

def parse_args():
    """
    Parse command-line arguments and return the resolved target_month string
    (YYYY-MM) or None (meaning: process all months).

    --month YYYY-MM  → process only that month
    --all            → process all months (full rebuild)
    (no args)        → process prior calendar month (default for scheduled runs)
    """
    parser = argparse.ArgumentParser(
        description="Extract Baha'i Quote emails to Obsidian vault monthly notes."
    )
    # Mutually exclusive: either --month or --all, not both
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--month",
        metavar="YYYY-MM",
        help="Process only this month (e.g. 2025-03). Default: prior month."
    )
    group.add_argument(
        "--all",
        action="store_true",
        help="Process all months found in eM Client (full rebuild)."
    )
    args = parser.parse_args()

    if args.all:
        # Signal to process everything
        return None

    if args.month:
        # Validate the supplied month string
        try:
            datetime.strptime(args.month, "%Y-%m")
        except ValueError:
            print(f"ERROR: --month value '{args.month}' is not a valid YYYY-MM date.")
            sys.exit(1)
        return args.month

    # Default: prior calendar month (first day of current month minus one day)
    today = datetime.now()
    prior_month_dt = today.replace(day=1) - timedelta(days=1)
    return prior_month_dt.strftime("%Y-%m")


def ticks_to_dt(ticks):
    """
    Convert .NET DateTime ticks (100-nanosecond intervals since 0001-01-01)
    to a Python datetime.  eM Client stores dates in this format.
    WARNING: Do NOT use datetime(1601,1,1) — that is Windows FILETIME and
    produces years ~3600 instead of 2020+.
    """
    if not ticks:
        return datetime(1, 1, 1)  # year-1 epoch fallback
    try:
        # Divide 100ns ticks by 10 to get microseconds, add to .NET year-1 epoch
        return datetime(1, 1, 1) + timedelta(microseconds=ticks // 10)
    except (OverflowError, ValueError):
        return datetime(1, 1, 1)


def open_ro(db_path):
    """Open a SQLite database file in read-only mode to avoid write-locking eM Client."""
    uri = f"file:{Path(db_path).resolve()}?mode=ro"
    conn = sqlite3.connect(uri, uri=True, timeout=5)
    conn.row_factory = sqlite3.Row
    return conn


def has_table(conn, table_name):
    """Return True if the given table exists in the connected database."""
    cur = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,)
    )
    return cur.fetchone() is not None


def scan_mail_index(idx_path, target_month=None):
    """
    Scan one mail_index.dat for Baha'i Quote emails.

    idx_path:     Path to mail_index.dat
    target_month: YYYY-MM string; if provided, only return emails from that month.
                  Pass None to return all matching emails.

    Returns list of dicts: {id, date (datetime), ym (str yyyy-mm)}.
    """
    results = []
    try:
        conn = open_ro(idx_path)
        if not has_table(conn, "MailItems"):
            conn.close()
            return results
        cur = conn.execute("SELECT id, subject, date FROM MailItems")
        for row in cur.fetchall():
            subj = (row["subject"] or "").lower()
            # Match daily quote emails; skip forwarded, replied, or Spanish-only threads
            if ("bah" in subj and "quote" in subj
                    and "fwd" not in subj and "re:" not in subj
                    and "cit" not in subj):  # "cit" catches Spanish "Cita" subject variant
                dt = ticks_to_dt(row["date"] or 0)
                ym = dt.strftime("%Y-%m")
                # Skip if a specific month was requested and this email is from another month
                if target_month and ym != target_month:
                    continue
                results.append({
                    "id":   row["id"],
                    "date": dt,
                    "ym":   ym,
                })
        conn.close()
    except Exception:
        pass  # silently skip unreadable or incompatible databases
    return results


def fetch_body(fti_path, item_id):
    """
    Retrieve the plain-text body for a mail item from mail_fti.dat.
    The FTS content table LocalMailsIndex3_content stores:
      c0id       = mail item ID (links to mail_index.dat MailItems.id)
      c1partName = '1' for text/plain, '2' for text/html
      c2content  = decoded plain text
    Returns body string or None.
    """
    try:
        conn = open_ro(fti_path)
        if not has_table(conn, "LocalMailsIndex3_content"):
            conn.close()
            return None
        # Prefer the plain-text part (c1partName='1')
        cur = conn.execute(
            "SELECT c2content FROM LocalMailsIndex3_content "
            "WHERE c0id=? AND c1partName='1'",
            (item_id,)
        )
        row = cur.fetchone()
        conn.close()
        if row and row[0]:
            return str(row[0])
    except Exception:
        pass
    return None


# --- Body parser ---

# Separator line used by the email (30+ dashes)
SEP_RE = re.compile(r'-{30,}')


def parse_body(raw_text):
    """
    Parse the English section of a Baha'i Quote email body.

    Email structure (English portion):
      ** Baha'i Quote
      -------
      [Bahá'í date line]
      -------
      "[quotation]" -[Author]

      [Source citation line]
      -------
      [Bahá'í month note]

      ** Cita Bah...  <- Spanish section starts here (discarded)

    Returns dict with keys: bahai_date, quotation, author, source, month_note.
    All values are strings (empty string if not found).
    """
    result = {"bahai_date": "", "quotation": "", "author": "",
              "source": "", "month_note": ""}

    # 1. Cut off Spanish section and everything after it
    for marker in ("** Cita Bah", "**Cita Bah", "\nCita Bah"):
        cut = raw_text.find(marker)
        if cut != -1:
            raw_text = raw_text[:cut]
            break

    # 2. Find the English section header line "** Bah"
    eng_start = raw_text.find("** Bah")
    if eng_start != -1:
        # Advance past the header line itself
        eng_start = raw_text.find("\n", eng_start)
        raw_text = raw_text[eng_start:].lstrip("\r\n") if eng_start != -1 else raw_text

    # 3. Split by separator lines
    # Expected segments: [0]=preamble, [1]=bahai date, [2]=quote+source, [3]=month note
    parts = SEP_RE.split(raw_text)

    # Extract Bahá'í date (segment after first separator)
    if len(parts) >= 2:
        result["bahai_date"] = parts[1].strip()

    # Extract quotation, author, and source citation (segment after second separator)
    if len(parts) >= 3:
        block = parts[2].strip()
        lines = [ln.strip() for ln in block.splitlines() if ln.strip()]

        if lines:
            # First non-empty line has format: "quotation text" -Author
            quote_line = lines[0]
            m = re.match(r'^"(.+)"\s*[-–]\s*(.+)$', quote_line, re.DOTALL)
            if m:
                result["quotation"] = m.group(1).strip()
                # Strip trailing social-media hashtags (e.g. "#Bahá'í") from author
                result["author"] = re.sub(r'\s*#\S+', '', m.group(2)).strip()
            else:
                # Fallback: treat whole line as the quotation
                result["quotation"] = quote_line.strip('"').strip()

        # Remaining non-empty lines form the source citation
        if len(lines) > 1:
            result["source"] = "\n".join(lines[1:]).strip()

    # Extract Bahá'í month/calendar note (segment after third separator)
    if len(parts) >= 4:
        result["month_note"] = parts[3].strip()

    return result


# --- Note builder ---

def build_note(month_key, entries):
    """
    Build a complete Obsidian markdown note for one calendar month.

    month_key: str like '2024-03'
    entries:   list of dicts, each with {date (datetime), bahai_date, quotation,
                                          author, source, month_note}
    Returns markdown string.
    """
    # Parse year and month number from the key
    year, mon = map(int, month_key.split("-"))
    # Human-readable heading: "March 2024"
    month_label = f"{calendar.month_name[mon]} {year}"

    lines = []

    # YAML frontmatter
    lines.append("---")
    lines.append("tags:")
    lines.append("  - Bahai")
    lines.append(f"created: {TODAY}")
    lines.append("---")
    lines.append("")

    # Page heading
    lines.append(f"# Bahá'í Daily Quotes — {month_label}")
    lines.append("")

    # One section per entry, sorted by date ascending within the month
    entries_sorted = sorted(entries, key=lambda e: e["date"])
    for entry in entries_sorted:
        # Section heading = the Bahá'í calendar date line from the email
        bahai_date = entry.get("bahai_date", "").strip()
        if bahai_date:
            lines.append(f"### {bahai_date}")
        else:
            # Fallback to Gregorian date if parsing failed
            lines.append(f"### {entry['date'].strftime('%B %#d, %Y')}")
        lines.append("")

        # Blockquote for the quotation
        quote = entry.get("quotation", "").strip()
        author = entry.get("author", "").strip()
        if quote:
            lines.append(f'> "{quote}"')
            if author:
                lines.append(f'> — {author}')
        lines.append("")

        # Source citation in italics
        source = entry.get("source", "").strip()
        if source:
            lines.append(f'*{source}*')

        # Bahá'í month note (calendar context) in italics
        month_note = entry.get("month_note", "").strip()
        if month_note:
            lines.append(f'*{month_note}*')

        lines.append("")
        lines.append("---")
        lines.append("")

    # Related Notes backlink
    lines.append("## Related Notes")
    lines.append("")
    lines.append("[[MOC - Bahá'í Faith]]")
    lines.append("")

    return "\n".join(lines)


# --- MOC updater ---

def read_existing_moc_links():
    """
    Read the MOC and return a dict of {month_key: display_label} for every
    wikilink already present in the ## Daily Quotes section.
    Returns an empty dict if the section is absent or the MOC doesn't exist.
    """
    existing = {}
    if not MOC_PATH.exists():
        return existing

    moc_text = MOC_PATH.read_text(encoding="utf-8")

    # Find the ## Daily Quotes section
    m = EXISTING_SECTION_RE.search(moc_text)
    if not m:
        return existing

    # Parse each link line: - [[YYYY-MM|Month YYYY]]
    for line in m.group(0).splitlines():
        lm = LINK_LINE_RE.match(line)
        if lm:
            month_key = lm.group(1)   # e.g. "2024-03"
            year, mon = map(int, month_key.split("-"))
            existing[month_key] = f"{calendar.month_name[mon]} {year}"

    return existing


def build_moc_section(month_links):
    """
    Build the ## Daily Quotes markdown section from a dict of {month_key: label}.
    month_links: dict like {'2024-03': 'March 2024', '2024-04': 'April 2024', ...}
    Returns a string ready to be spliced into the MOC.
    """
    section_lines = ["## Daily Quotes", ""]
    # Sort chronologically by month key
    for month_key in sorted(month_links.keys()):
        month_label = month_links[month_key]
        section_lines.append(f"- [[{month_key}|{month_label}]]")
    section_lines.append("")  # blank line before the next ## section
    return "\n".join(section_lines)


def update_moc(files_written, incremental=False):
    """
    Insert or refresh the ## Daily Quotes section in the Bahá'í Faith MOC.
    The section is placed immediately before MOC_ANCHOR.

    files_written: list of (month_key, entry_count, out_file) tuples
    incremental:   if True, merge new months into the existing link list rather
                   than rebuilding from scratch. Use this for single-month runs
                   so existing links for other months are preserved.
    """
    if not MOC_PATH.exists():
        print(f"WARNING: MOC not found at {MOC_PATH} — skipping MOC update")
        return

    # Read current MOC text
    moc_text = MOC_PATH.read_text(encoding="utf-8")

    if incremental:
        # Merge: start from whatever links are already in the MOC, then add/update
        # the months from this run.
        month_links = read_existing_moc_links()
        for month_key, _count, _path in files_written:
            year, mon = map(int, month_key.split("-"))
            month_links[month_key] = f"{calendar.month_name[mon]} {year}"
    else:
        # Full rebuild: only the months passed in files_written are included.
        month_links = {}
        for month_key, _count, _path in files_written:
            year, mon = map(int, month_key.split("-"))
            month_links[month_key] = f"{calendar.month_name[mon]} {year}"

    # Build the replacement section text
    new_section = build_moc_section(month_links)

    # Remove any existing ## Daily Quotes section so we can re-insert cleanly
    moc_text = EXISTING_SECTION_RE.sub("", moc_text)

    # Insert the new section before the anchor heading
    if MOC_ANCHOR in moc_text:
        moc_text = moc_text.replace(MOC_ANCHOR, new_section + "\n" + MOC_ANCHOR)
        MOC_PATH.write_text(moc_text, encoding="utf-8")
        print(f"\nMOC updated: {len(month_links)} monthly links in {MOC_PATH.name}")
    else:
        # Anchor not found — append at end before any trailing ---
        if moc_text.rstrip().endswith("---"):
            moc_text = moc_text.rstrip()[:-3].rstrip() + "\n\n" + new_section + "\n---\n"
        else:
            moc_text = moc_text.rstrip() + "\n\n" + new_section
        MOC_PATH.write_text(moc_text, encoding="utf-8")
        print(f"\nMOC updated (appended — anchor not found): {MOC_PATH.name}")


# --- Main ---

def main():
    # Resolve the target month (None = all months)
    target_month = parse_args()

    if target_month:
        year, mon = map(int, target_month.split("-"))
        print(f"Mode: single month — {calendar.month_name[mon]} {year} ({target_month})")
    else:
        print("Mode: full rebuild — all months")
    print(f"Output folder: {VAULT_OUTPUT}\n")

    # Create output folder if it doesn't exist
    VAULT_OUTPUT.mkdir(parents=True, exist_ok=True)

    # Collect matching emails from all eM Client account/folder databases.
    # folder_emails maps sub_dir path string -> list of email record dicts.
    folder_emails = defaultdict(list)

    for account_dir in sorted(EMCLIENT_DIR.iterdir()):
        if not account_dir.is_dir():
            continue
        for sub_dir in sorted(account_dir.iterdir()):
            if not sub_dir.is_dir():
                continue
            idx = sub_dir / "mail_index.dat"
            fti = sub_dir / "mail_fti.dat"
            if not idx.exists():
                continue
            # Pass target_month so scan_mail_index filters at query time
            matches = scan_mail_index(idx, target_month=target_month)
            if matches:
                for m in matches:
                    m["fti"] = fti        # path to the FTS body database
                    m["sub_dir"] = sub_dir
                folder_emails[str(sub_dir)].extend(matches)
                print(f"  Found {len(matches)} emails in {sub_dir.name}")

    # Fetch bodies and parse each email
    all_entries = []   # list of fully-parsed entry dicts
    skipped = 0        # emails where no body was found in mail_fti.dat
    parse_errors = 0   # emails where the quotation regex yielded no match

    for sub_dir_str, emails in folder_emails.items():
        fti_path = emails[0]["fti"]  # same FTS file for all emails in this folder
        if not fti_path.exists():
            print(f"  WARNING: mail_fti.dat not found at {fti_path} — "
                  f"skipping {len(emails)} emails")
            skipped += len(emails)
            continue

        for email_rec in emails:
            body = fetch_body(fti_path, email_rec["id"])
            if not body:
                skipped += 1
                continue

            parsed = parse_body(body)
            if not parsed["quotation"]:
                parse_errors += 1
                # Keep the entry so we don't silently drop a day
                parsed["quotation"] = "[could not parse quotation]"

            all_entries.append({
                "date":       email_rec["date"],
                "ym":         email_rec["ym"],
                "bahai_date": parsed["bahai_date"],
                "quotation":  parsed["quotation"],
                "author":     parsed["author"],
                "source":     parsed["source"],
                "month_note": parsed["month_note"],
            })

    print(f"\nTotal emails processed: {len(all_entries)}")
    print(f"Skipped (no body):      {skipped}")
    print(f"Parse warnings:         {parse_errors}")

    # Deduplicate: if two emails share the same (ym, bahai_date), keep the first
    seen_keys = set()
    deduped = []
    for entry in sorted(all_entries, key=lambda e: e["date"]):
        key = (entry["ym"], entry["bahai_date"] or entry["date"].strftime("%Y-%m-%d"))
        if key not in seen_keys:
            seen_keys.add(key)
            deduped.append(entry)
    print(f"After deduplication:    {len(deduped)}")

    # Group entries by month
    by_month = defaultdict(list)
    for entry in deduped:
        by_month[entry["ym"]].append(entry)

    # Write one note per month
    files_written = []
    for month_key in sorted(by_month.keys()):
        entries = by_month[month_key]
        note_content = build_note(month_key, entries)
        out_file = VAULT_OUTPUT / f"{month_key}.md"
        out_file.write_text(note_content, encoding="utf-8")
        files_written.append((month_key, len(entries), out_file))
        print(f"  Wrote {out_file.name}  ({len(entries)} entries)")

    print(f"\nDone. {len(files_written)} files written to {VAULT_OUTPUT}")

    # Update MOC: use incremental merge when processing a single month
    # so existing links for other months are preserved.
    update_moc(files_written, incremental=(target_month is not None))


if __name__ == "__main__":
    main()
