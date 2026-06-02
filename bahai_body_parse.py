# -*- coding: utf-8 -*-
"""
bahai_body_parse.py
Extract and display plain-text body from one sample "Baha'i Quote" email.
The full raw MIME message is stored in partHeader where partName='TEXT'.
"""

import sqlite3
import email
import sys
from pathlib import Path

# The specific mail_data.dat that holds the daily Baha'i Quote emails
DB_PATH = Path(r"C:\Users\awt\AppData\Roaming\eM Client\6f83bfb7-deb5-4841-afac-56330c789aea\a57979f0-26b3-4a57-96ac-3df58e1531d4\mail_data.dat")

# Sample item ID confirmed to be a Baha'i Quote email from 2024-03-23
ITEM_ID = 15117

def get_plain_text(db_path, item_id):
    """
    Retrieve the plain-text body of an email from LocalMailContents.
    The full raw MIME message is in partHeader where partName='TEXT'.
    Returns decoded plain text string, or None.
    """
    # Open database in read-only mode to avoid locking issues
    uri = f"file:{db_path.resolve()}?mode=ro"
    conn = sqlite3.connect(uri, uri=True, timeout=5)

    # Fetch the partHeader of the TEXT (multipart wrapper) row,
    # which contains the complete raw MIME email
    cur = conn.execute(
        "SELECT partHeader FROM LocalMailContents WHERE id=? AND partName='TEXT'",
        (item_id,)
    )
    row = cur.fetchone()
    conn.close()

    if not row or not row[0]:
        return None

    # Convert raw value to bytes (may be returned as bytes, memoryview, or str)
    raw = row[0]
    if isinstance(raw, memoryview):
        raw = bytes(raw)
    elif isinstance(raw, str):
        raw = raw.encode("utf-8", errors="replace")

    # Parse the complete MIME email
    msg = email.message_from_bytes(raw)

    print(f"Subject: {msg.get('Subject', 'n/a')}")
    print(f"From:    {msg.get('From', 'n/a')}")
    print(f"Date:    {msg.get('Date', 'n/a')}")
    print()

    # Walk all MIME parts looking for text/plain
    for part in msg.walk():
        ct = part.get_content_type()
        if ct == "text/plain":
            # get_payload(decode=True) handles QP/base64 decoding automatically
            payload_bytes = part.get_payload(decode=True)
            if payload_bytes:
                # Decode bytes to string; try UTF-8 first, fall back to latin-1
                try:
                    return payload_bytes.decode("utf-8", errors="replace")
                except Exception:
                    return payload_bytes.decode("latin-1", errors="replace")

    return None


text = get_plain_text(DB_PATH, ITEM_ID)

if text is None:
    print("Could not extract plain text body.")
    sys.exit(1)

print(f"=== PLAIN TEXT BODY ({len(text)} chars) ===")
print()
# Show the full body so we can see the English/Spanish split structure
print(text)
