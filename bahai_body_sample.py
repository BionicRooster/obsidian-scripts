# -*- coding: utf-8 -*-
"""
bahai_body_sample.py
Corrected epoch + body extraction test.
Finds the first 3 'Baha'i Quote' emails, extracts and decodes their plain-text bodies.
"""

import sqlite3
import re
import base64
import quopri
from datetime import datetime, timedelta
from pathlib import Path
from email import message_from_bytes
from email import policy as email_policy

# Root eM Client data directory
DATA_DIR = Path(r"C:\Users\awt\AppData\Roaming\eM Client")

def filetime_to_dt(ticks):
    """
    Convert eM Client date (100-nanosecond ticks since 0001-01-01, .NET DateTime epoch)
    to a Python datetime.
    """
    # eM Client stores dates as .NET DateTime.Ticks: 100ns intervals since Jan 1, year 1
    # Python: datetime(1,1,1) = Jan 1, year 1
    if not ticks:
        return datetime(1, 1, 1)
    try:
        # Convert 100ns ticks to microseconds (divide by 10), add to .NET epoch
        return datetime(1, 1, 1) + timedelta(microseconds=ticks // 10)
    except Exception:
        return datetime(1, 1, 1)

def decode_part_body(raw, encoding):
    """
    Decode a MIME part body based on its Content-Transfer-Encoding.
    raw:      bytes or str — the encoded body content from the database
    encoding: str like 'quoted-printable', 'base64', '7bit', '8bit', None
    Returns decoded UTF-8 string.
    """
    # Normalize to bytes
    if isinstance(raw, str):
        raw_bytes = raw.encode("latin-1", errors="replace")
    elif isinstance(raw, (bytes, bytearray)):
        raw_bytes = bytes(raw)
    else:
        # Handle SQLite BLOB returned as memoryview
        raw_bytes = bytes(raw)

    encoding = (encoding or "").strip().lower()

    try:
        if encoding == "quoted-printable":
            # quopri.decodestring handles QP encoding
            decoded = quopri.decodestring(raw_bytes)
        elif encoding == "base64":
            # base64.decodebytes handles multi-line base64
            decoded = base64.decodebytes(raw_bytes)
        else:
            # 7bit, 8bit, binary, or unknown — treat as-is
            decoded = raw_bytes

        # Try UTF-8 first, then latin-1 as fallback
        return decoded.decode("utf-8", errors="replace")
    except Exception as e:
        return f"[decode error: {e}]\n{raw_bytes[:500]}"

def get_plain_text_parts(mail_data_path, item_id):
    """
    Query mail_data.dat (LocalMailContents) for all text/plain parts
    belonging to a given MailItem id.
    Returns list of decoded plain-text strings.
    """
    results = []
    if not mail_data_path.exists():
        return ["[mail_data.dat not found]"]
    try:
        uri = f"file:{mail_data_path.resolve()}?mode=ro"
        conn = sqlite3.connect(uri, uri=True, timeout=5)
        # Query for text/plain parts; also try text/html as fallback
        cur = conn.execute("""
            SELECT contentType, contentTransferEncoding, partBody
            FROM LocalMailContents
            WHERE id = ?
              AND contentType LIKE 'text/%'
            ORDER BY
              CASE WHEN contentType LIKE 'text/plain%' THEN 0 ELSE 1 END
        """, (item_id,))
        rows = cur.fetchall()
        conn.close()

        if not rows:
            return ["[no text/* parts found for this id]"]

        for content_type, encoding, part_body in rows:
            if part_body is None:
                continue
            decoded = decode_part_body(part_body, encoding)
            results.append((content_type, decoded))
    except Exception as e:
        results.append(("error", f"[query error: {e}]"))
    return results

# ---- Scan for Baha'i Quote emails ----
print("Scanning for Baha'i Quote emails (corrected epoch)...\n")

# Collect matching emails from all account folders
found = []   # list of dicts: {id, subject, date, ym, sub_dir}

for account_dir in sorted(DATA_DIR.iterdir()):
    if not account_dir.is_dir():
        continue
    for sub_dir in sorted(account_dir.iterdir()):
        if not sub_dir.is_dir():
            continue
        idx = sub_dir / "mail_index.dat"
        if not idx.exists():
            continue
        try:
            uri = f"file:{idx.resolve()}?mode=ro"
            conn = sqlite3.connect(uri, uri=True, timeout=5)
            conn.row_factory = sqlite3.Row
            cur = conn.execute("SELECT id, subject, date FROM MailItems")
            rows = cur.fetchall()
            conn.close()
            for row in rows:
                subj = (row["subject"] or "").strip()
                # Only exact "Baha'i Quote" subject (the core daily emails)
                subj_lower = subj.lower()
                if "baha" in subj_lower and "quote" in subj_lower and "fwd" not in subj_lower and "re:" not in subj_lower:
                    dt = filetime_to_dt(row["date"] or 0)
                    found.append({
                        "id": row["id"],
                        "subject": subj,
                        "date": dt,
                        "ym": dt.strftime("%Y-%m"),
                        "sub_dir": sub_dir,
                    })
        except Exception:
            pass

# Deduplicate by (ym, id)
seen = set()
unique = []
for r in found:
    key = (r["ym"], r["id"])
    if key not in seen:
        seen.add(key)
        unique.append(r)

unique.sort(key=lambda r: r["date"])
print(f"Total unique 'Baha'i Quote' emails (deduplicated): {len(unique)}")
if unique:
    print(f"Date range: {unique[0]['date'].strftime('%Y-%m-%d')} to {unique[-1]['date'].strftime('%Y-%m-%d')}\n")

# ---- Extract bodies for first 3 emails from different months ----
# Pick one email from each of the first 3 distinct months
month_samples = {}   # ym -> email record
for r in unique:
    if r["ym"] not in month_samples:
        month_samples[r["ym"]] = r
    if len(month_samples) >= 3:
        break

for ym, r in list(month_samples.items()):
    print(f"{'='*70}")
    print(f"EMAIL: {r['subject']}")
    print(f"Date:  {r['date'].strftime('%Y-%m-%d')}   ID: {r['id']}")
    print(f"Folder: {r['sub_dir']}")
    print()

    mail_data_path = r["sub_dir"] / "mail_data.dat"
    parts = get_plain_text_parts(mail_data_path, r["id"])

    if not parts:
        print("  [No text parts found]")
        continue

    for content_type, text in parts:
        print(f"  --- Part: {content_type} ({len(text)} chars) ---")
        # Show first 3000 chars to see full structure
        print(text[:3000])
        print()
        # Stop after the first text/plain part
        if "plain" in content_type:
            break
