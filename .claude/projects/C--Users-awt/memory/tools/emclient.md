---
name: tools-emclient
description: "eM Client is the preferred email interface for all email searches — use local SQLite databases, not Gmail MCP"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 08ae3199-5e94-457c-bef6-4e7ded6e0918
---

Use eM Client local SQLite databases for ALL email search tasks. Do not default to Gmail MCP alone.

**Why:** Wayne uses eM Client as his desktop email client across multiple accounts. All email history lives in local .dat files. Gmail MCP only reaches one account; eM Client covers all 11+ accounts simultaneously.

**How to apply:** When any task involves searching email (finding correspondence, building a person file, researching a topic), use the eM Client database approach — not Gmail MCP — unless the user explicitly requests Gmail only.

---

## eM Client Data Directory

`C:\Users\awt\AppData\Roaming\eM Client\`

Each email account = a UUID folder. Each mail folder within that account = a sub-UUID folder containing:
- `mail_index.dat` — indexed metadata (MailItems + MailAddresses tables)
- `mail_data.dat` — MIME message bodies

## Schema (confirmed 2026-06-02 — date epoch corrected)

**`MailItems` table** (in mail_index.dat):
- `id`, `subject`, `date` (.NET DateTime ticks: 100ns intervals since **0001-01-01**, NOT Windows FILETIME), `preview`, `flags`

**`MailAddresses` table** (in mail_index.dat):
- `id`, `parentId` (→ MailItems.id), `type` (1/2/3=from, 4=to, 5=cc, 6=unknown), `displayName`, `address`
- **CORRECTED 2026-06-29:** Prior docs showed 0=from/1=to/2=cc — this is WRONG. Confirmed live: type=1 is From. Use `a.type = 1` to get sender. type=0 matches nothing and silently returns blank senders.

**Date conversion:** `datetime(1, 1, 1) + timedelta(microseconds=date//10)`
**WARNING:** Do NOT use `datetime(1601,1,1)` — that is Windows FILETIME epoch and will produce years like 3620 instead of 2020.

## Search Pattern (Python)

Search all accounts by scanning every sub-UUID folder's mail_index.dat:

```python
import sqlite3, os
from datetime import datetime, timedelta
from pathlib import Path

data_dir = Path(r"C:\Users\awt\AppData\Roaming\eM Client")
keywords = ["saterfield", "liverman", "cliverman"]  # customize per task
results = []

for account_dir in data_dir.iterdir():
    if not account_dir.is_dir(): continue
    for sub_dir in account_dir.iterdir():
        if not sub_dir.is_dir(): continue
        idx = sub_dir / "mail_index.dat"
        if not idx.exists(): continue
        uri = f"file:{idx.resolve()}?mode=ro"
        try:
            conn = sqlite3.connect(uri, uri=True, timeout=5)
            conn.row_factory = sqlite3.Row
            cur = conn.execute("""
                SELECT m.id, m.subject, m.date, m.preview,
                       a.displayName, a.address, a.type
                FROM MailItems m
                LEFT JOIN MailAddresses a ON a.parentId = m.id
            """)
            for row in cur.fetchall():
                text = " ".join(filter(None, [
                    str(row["subject"] or ""),
                    str(row["preview"] or ""),
                    str(row["address"] or ""),
                    str(row["displayName"] or "")
                ])).lower()
                if any(kw in text for kw in keywords):
                    dt = datetime(1, 1, 1) + timedelta(microseconds=(row["date"] or 0)//10)
                    results.append({
                        "date": dt.strftime("%Y-%m-%d"),
                        "subject": row["subject"],
                        "from_name": row["displayName"],
                        "from_addr": row["address"],
                        "preview": (row["preview"] or "")[:120]
                    })
            conn.close()
        except Exception:
            pass

# Deduplicate by subject+date
seen = set()
for r in sorted(results, key=lambda x: x["date"], reverse=True):
    key = (r["date"], r["subject"])
    if key not in seen:
        seen.add(key)
        print(f"{r['date']} | {r['from_addr']} | {r['subject']}")
        print(f"  {r['preview']}")
```

**`LocalMailContents` table** (in mail_data.dat) — confirmed 2026-07-03:
- `id` (→ MailItems.id), `partName` (MIME part: '1'=text/plain, '2'=text/html, 'TEXT'=multipart), `contentType`, `contentId`, `contentDescription`, `contentTransferEncoding` (integer, not string — e.g. 4), `contentLength` (declared byte count), `synchronizationKey`, `partHeader`, `partBody` (blob — **always empty, see Body Retrieval below**)

**`conversations.dat` tables** (confirmed 2026-07-03 — metadata only, no body text):
- `Conversations`: id, conversationId, subject, unreadCount, date, previewSnippet, and ~30 other metadata fields
- `ConversationSenders`, `ConversationRecipients`, `ConversationCategories`, `ConversationMessageIds`, `ConversationFolders`

## Body Retrieval — Raw File Search (Confirmed 2026-07-03)

**`partBody` in `LocalMailContents` is always empty (zero-length blob) even when `contentLength` is non-zero.** Do NOT attempt to read email bodies via SQLite — they are stored as raw bytes directly in `mail_data.dat` at arbitrary file offsets, not in the SQLite blob column.

**How to retrieve a message body:**
1. Get a known text snippet from `MailItems.preview` (the index database)
2. Search the raw `mail_data.dat` file for that snippet as bytes
3. Read ~6,000 bytes around the hit offset to capture the full message part

```python
from pathlib import Path

data_path = Path(r"C:\Users\awt\AppData\Roaming\eM Client\<account>\<folder>\mail_data.dat")
needle = b"known text from preview"

with open(data_path, 'rb') as f:
    content = f.read()
    offset = content.find(needle)
    if offset != -1:
        start = max(0, offset - 500)
        chunk = content[start:start + 6000]
        # Write to file (avoid console encoding issues on Windows)
        Path(r"C:\Users\awt\body_out.txt").write_text(
            chunk.decode('utf-8', errors='replace'), encoding='utf-8')
```

**Note:** For large files (mail_data.dat is ~486MB), read in 10MB chunks rather than loading fully into memory. The bodies retrieved are HTML (from the HTML MIME part); the plain text part is at a different offset.

## Skill Scripts

Extracted skill ZIP at: `C:\Users\awt\AppData\Roaming\eM Client\skill_extract\emclient-email-reader\scripts\`
- `query_emclient.py` — single-db keyword search (use when you already know the db path)
- `account_map.py` — full account/folder discovery (slow; run in background if needed)
- `discover_schema.py` — inspect any .dat file's table/column structure

## Model Routing

eM Client database scanning is **Haiku-safe**: spawn a Haiku subagent with the search script and a tight output spec. Return raw results to Sonnet for synthesis and biography writing.

## Haiku Subagent — Fire-and-Forget Constraint

`SendMessage` is not available in this environment (FleetView). Haiku subagents terminate after one response and cannot be continued.

**How to apply:** Front-load the prompt completely. Include all keyword variants upfront (name, alternate spellings, both email addresses, any known aliases). Ask for full output detail in a single pass — do not plan to iterate.

Example for a person search: keywords should include `["saterfield", "satterfield", "gsater904", "csaterfield01"]` rather than starting with the primary spelling and refining. One well-specified prompt beats two passes.
