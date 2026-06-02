---
name: feedback-no-secrets-in-code
description: "Never hardcode credentials, API keys, passwords, or usernames in code — always read them from a file on the OS"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cb1e4560-c2f0-4ab0-801e-357984912080
---

Never include usernames, passwords, API keys, tokens, or any other security-sensitive data as literals in code. Always read them from a file stored on the operating system at runtime.

**Why:** Hardcoded secrets end up in git history and get exposed (e.g., the YouTube API key incident that required git filter-repo to purge 60 commits).

**How to apply:** When writing any PS1, Python, or other script that needs credentials or keys:
- Store the secret in a local file (e.g., `C:\Users\awt\secrets\youtube_api_key.txt` or a `.env` file)
- Read it at runtime: `$apiKey = Get-Content "C:\Users\awt\secrets\youtube_api_key.txt" -Raw` (PS1) or `open("path").read().strip()` (Python)
- Never use a placeholder literal like `'REMOVED_API_KEY'` — use the file-read pattern from the start
- Note the expected file path in a comment so the user knows where to place the secret
