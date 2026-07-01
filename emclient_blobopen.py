import sqlite3
from pathlib import Path

folder_path = Path(r"C:\Users\awt\AppData\Roaming\eM Client\768c3585-7cf5-4f97-86ff-059a67ac2458\7cc44778-4682-4ebc-a19c-24bf2ae2cbfd")
data_db = folder_path / "mail_data.dat"

# Open read-only; use blobopen (low-level BLOB I/O) which bypasses any quirks
# with normal SELECT returning truncated/empty values for huge blob columns.
uri = f"file:{data_db.resolve()}?mode=ro"
conn = sqlite3.connect(uri, uri=True, timeout=5)

target_id = 37264

# First get rowid for each part we want, since blobopen needs a rowid, not just `id`
# LocalMailContents may not have an explicit rowid alias; check pragma first.
cur = conn.execute("SELECT rowid, id, partName, contentLength FROM LocalMailContents WHERE id=? ORDER BY partName", (target_id,))
rows = cur.fetchall()
print("Rows with rowid:")
for r in rows:
    print(f"  rowid={r[0]} id={r[1]} partName={r[2]} contentLength={r[3]}")

print()

# Try blobopen on partBody using the rowid for part '1' (the plain text body)
for r in rows:
    rowid, pid, partName, contentLength = r
    if contentLength and contentLength > 0:
        try:
            blob = conn.blobopen("LocalMailContents", "partBody", rowid, readonly=True)
            data = blob.read()
            blob.close()
            print(f"partName={partName}: blobopen length = {len(data)}")
            if partName == '1':
                print("First 300 bytes:", data[:300])
        except Exception as e:
            print(f"partName={partName}: blobopen error: {e}")

conn.close()
