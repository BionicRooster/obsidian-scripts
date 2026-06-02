# -*- coding: utf-8 -*-
"""
bahai_quote_discovery.py
Phase 1: Scan all eM Client SQLite databases for 'Baha'i Quote' emails.
Reports: count, date range, month breakdown, mail_data.dat schema, one sample body.
"""

import sqlite3
import os
import re
from datetime import datetime, timedelta
from pathlib import Path
from collections import Counter
import email
from email import policy

# --- Configuration ---
# Root directory containing all eM Client account UUID folders
DATA_DIR = Path(r"C:\Users\awt\AppData\Roaming\eM Client")

# Subject must contain this substring (case-insensitive) to match
SUBJECT_KEYWORD = "quote"

def filetime_to_dt(filetime):
    """Convert Windows FILETIME (100-nanosecond intervals since 1601-01-01) to datetime."""
    # FILETIME is an integer; divide by 10 to get microseconds, add to epoch
    if not filetime:
        return datetime(1601, 1, 1)
    return datetime(1601, 1, 1) + timedelta(microseconds=filetime // 10)

def get_mail_data_schema(mail_data_path):
    """Inspect mail_data.dat: return dict of {table_name: [column_names]}."""
    schema = {}
    try:
        uri = f"file:{mail_data_path.resolve()}?mode=ro"
        conn = sqlite3.connect(uri, uri=True, timeout=5)
        # Get all user-defined tables
        cur = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
        tables = [row[0] for row in cur.fetchall()]
        for table in tables:
            cur = conn.execute(f"PRAGMA table_info({table})")
            cols = [row[1] for row in cur.fetchall()]
            schema[table] = cols
        conn.close()
    except Exception as e:
        schema["_error"] = str(e)
    return schema

def get_row_count(mail_data_path, table):
    """Return row count for a given table in mail_data.dat."""
    try:
        uri = f"file:{mail_data_path.resolve()}?mode=ro"
        conn = sqlite3.connect(uri, uri=True, timeout=5)
        cur = conn.execute(f"SELECT COUNT(*) FROM {table}")
        count = cur.fetchone()[0]
        conn.close()
        return count
    except:
        return -1

def try_fetch_body(mail_data_path, item_id):
    """
    Attempt to retrieve the raw message body from mail_data.dat for a given item_id.
    Tries multiple likely column/table combinations.
    Returns (raw_text, method_description) or (None, reason).
    """
    if not mail_data_path.exists():
        return None, "mail_data.dat not found"

    uri = f"file:{mail_data_path.resolve()}?mode=ro"
    try:
        conn = sqlite3.connect(uri, uri=True, timeout=5)
    except Exception as e:
        return None, f"connect error: {e}"

    # Probe schema first
    schema = {}
    try:
        cur = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
        tables = [row[0] for row in cur.fetchall()]
        for t in tables:
            cur = conn.execute(f"PRAGMA table_info({t})")
            schema[t] = [row[1] for row in cur.fetchall()]
    except:
        pass

    # Try every table that has an 'id' column and a column that sounds like content
    content_col_hints = ["body", "data", "content", "message", "text", "mime", "raw", "payload"]
    for table, cols in schema.items():
        cols_lower = [c.lower() for c in cols]
        if "id" not in cols_lower:
            continue
        for hint in content_col_hints:
            if hint in cols_lower:
                actual_col = cols[cols_lower.index(hint)]
                try:
                    cur = conn.execute(f"SELECT [{actual_col}] FROM [{table}] WHERE id=?", (item_id,))
                    row = cur.fetchone()
                    if row and row[0]:
                        conn.close()
                        return row[0], f"{table}.{actual_col}"
                except:
                    pass

    # Fallback: dump first 2000 chars of every column in every table, first row
    fallback_results = []
    for table, cols in schema.items():
        try:
            cur = conn.execute(f"SELECT * FROM [{table}] LIMIT 1")
            row = cur.fetchone()
            if row:
                for i, val in enumerate(row):
                    if val and isinstance(val, (str, bytes)) and len(str(val)) > 50:
                        fallback_results.append(f"[{table}.{cols[i]}] = {str(val)[:500]}")
        except:
            pass

    conn.close()
    if fallback_results:
        return "\n".join(fallback_results), "fallback_probe"
    return None, f"no body found. Tables: {list(schema.keys())}"

# ---- Main scan ----
print("Scanning eM Client databases for Baha'i Quote emails...")
print(f"Data dir: {DATA_DIR}\n")

# Collect all matching emails across all accounts/folders
results = []        # list of dicts with email metadata
schema_samples = {} # sub_dir path -> mail_data schema (for first hit per dir)

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
            cur = conn.execute("""
                SELECT m.id, m.subject, m.date, m.preview,
                       a.displayName, a.address
                FROM MailItems m
                LEFT JOIN MailAddresses a ON a.parentId = m.id AND a.type = 0
            """)
            rows = cur.fetchall()
            conn.close()
            for row in rows:
                subj = (row["subject"] or "").lower()
                # Match: subject contains 'quote' and 'bah' (covers baha, baha'i, bahai)
                if SUBJECT_KEYWORD in subj and "bah" in subj:
                    dt = filetime_to_dt(row["date"] or 0)
                    results.append({
                        "id": row["id"],
                        "subject": row["subject"],
                        "date": dt,
                        "ym": dt.strftime("%Y-%m"),
                        "preview": (row["preview"] or "")[:300],
                        "from_name": row["displayName"],
                        "from_addr": row["address"],
                        "sub_dir": sub_dir,
                    })
        except Exception as e:
            pass  # Skip unreadable databases silently

# ---- Report summary ----
print(f"TOTAL MATCHING EMAILS: {len(results)}")
if not results:
    print("No matches found. Check subject keyword variants.")
    import sys; sys.exit(0)

# Sort by date
results.sort(key=lambda r: r["date"])
print(f"Date range: {results[0]['date'].strftime('%Y-%m-%d')} to {results[-1]['date'].strftime('%Y-%m-%d')}")

# Count per month
month_counts = Counter(r["ym"] for r in results)
print(f"\nPer-month breakdown ({len(month_counts)} months):")
for ym in sorted(month_counts):
    print(f"  {ym}: {month_counts[ym]} emails")

# Unique subjects seen
subjects = Counter(r["subject"] for r in results)
print(f"\nSubject variants found:")
for subj, cnt in subjects.most_common(10):
    print(f"  [{cnt}x] {subj}")

# Unique senders
senders = Counter(r["from_addr"] for r in results)
print(f"\nSenders:")
for addr, cnt in senders.most_common():
    print(f"  [{cnt}x] {addr}")

# ---- Schema discovery for first hit's mail_data.dat ----
sample = results[0]
mail_data_path = sample["sub_dir"] / "mail_data.dat"
print(f"\n--- mail_data.dat schema (from first hit folder) ---")
print(f"Path: {mail_data_path}")
print(f"Exists: {mail_data_path.exists()}")
if mail_data_path.exists():
    schema = get_mail_data_schema(mail_data_path)
    for table, cols in schema.items():
        row_count = get_row_count(mail_data_path, table)
        print(f"  Table '{table}' ({row_count} rows): {cols}")

# ---- Sample body extraction ----
print(f"\n--- Sample email body (id={sample['id']}) ---")
print(f"  Subject: {sample['subject']}")
print(f"  Date:    {sample['date'].strftime('%Y-%m-%d')}")
print(f"  From:    {sample['from_addr']}")
print(f"  Preview: {sample['preview']}")

raw_body, method = try_fetch_body(mail_data_path, sample["id"])
print(f"\n  Body retrieval method: {method}")
if raw_body:
    body_text = raw_body if isinstance(raw_body, str) else raw_body.decode("utf-8", errors="replace")
    print(f"  Body length: {len(body_text)} chars")
    print(f"  First 2000 chars:\n{'-'*60}")
    print(body_text[:2000])
    print(f"{'-'*60}")
else:
    print("  Could not retrieve body.")

# ---- Also try MIME parse via email module ----
if raw_body and isinstance(raw_body, (str, bytes)):
    try:
        raw_bytes = raw_body if isinstance(raw_body, bytes) else raw_body.encode("utf-8", errors="replace")
        msg = email.message_from_bytes(raw_bytes, policy=policy.default)
        print(f"\n  MIME parsed subject: {msg.get('Subject', 'n/a')}")
        # Try to get plain text part
        if msg.is_multipart():
            for part in msg.walk():
                ct = part.get_content_type()
                if ct == "text/plain":
                    payload = part.get_payload(decode=True)
                    if payload:
                        print(f"  Plain text part ({len(payload)} bytes):")
                        print(payload.decode("utf-8", errors="replace")[:1500])
                        break
        else:
            payload = msg.get_payload(decode=True)
            if payload:
                print(f"  Single part ({len(payload)} bytes):")
                print(payload.decode("utf-8", errors="replace")[:1500])
    except Exception as e:
        print(f"  MIME parse error: {e}")
