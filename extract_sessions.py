"""Extract actual user text messages from Claude Code .jsonl session files."""
import json
import re
import pathlib

# Sessions to review: (session_id, date_label)
sessions = [
    ("40e164e8-cc20-4f6e-b7a6-ac97cd65e457", "2026-06-02 19:45"),
    ("804fe537-3441-4576-bf73-cfa9ef5b4191", "2026-06-02 19:24"),
    ("3d8b07fb-b340-480b-a5ed-d585981ba2e5", "2026-06-02 15:39"),
    ("cb1e4560-c2f0-4ab0-801e-357984912080", "2026-06-02 12:48"),
    ("258b85b2-f132-47c7-b8e9-18c098e2672e", "2026-06-01 21:20"),
]

# Prefixes that indicate injected system content rather than real user input
skip_prefixes = (
    "<local-command-caveat>",
    "<command-name>",
    "<system-reminder>",
    "<persisted-output>",
    "[Image",
)

# Regex to catch JSON/tool blobs, caveat text, and === markers
skip_pattern = re.compile(
    r"^(\s*\{|\s*\[|\s*<tool_use_error|Caveat:|===|\s*tool_use_id)",
    re.IGNORECASE,
)

# Base directory for session .jsonl files
base = pathlib.Path(r"C:\Users\awt\.claude\projects\C--Users-awt")

for session_id, date_label in sessions:
    filepath = base / (session_id + ".jsonl")
    print(f"=== {session_id[:8]} ({date_label}) ===")

    for raw_line in filepath.open(encoding="utf-8"):
        # Parse each JSON line; skip malformed lines
        try:
            obj = json.loads(raw_line)
        except json.JSONDecodeError:
            continue

        # Only process user-type, non-meta messages
        if obj.get("type") != "user":
            continue
        if obj.get("isMeta"):
            continue

        # Extract content — can be a string or a list of dicts
        content = obj.get("message", {}).get("content", "")
        if not isinstance(content, str):
            continue

        text = content.strip()

        # Skip injected system messages
        if any(text.startswith(p) for p in skip_prefixes):
            continue
        if skip_pattern.match(text):
            continue
        if len(text) < 3:
            continue

        # Truncate long messages for readability
        timestamp = obj.get("timestamp", "")[:16]
        display = text[:300] + ("..." if len(text) > 300 else "")
        print(f"  [{timestamp}] {display}")

    print()
