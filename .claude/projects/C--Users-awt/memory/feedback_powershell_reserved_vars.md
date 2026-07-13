---
name: feedback_powershell_reserved_vars
description: "Never use $home as a variable name in PowerShell — it's a read-only built-in that silently fails on assignment, causing data corruption when used as output target"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d9c6819b-f1ec-4370-8a76-09e7a73f1aea
---

Never use `$home` as a variable name in PowerShell scripts that write to files.

**Why:** PowerShell's `$home` is a read-only automatic variable set to `C:\Users\<username>`. Assigning to it fails silently (no error thrown). If a script uses `$home` as an output path variable, the assignment fails, and `$home` retains its built-in value (`C:\Users\awt`). Any subsequent `[System.IO.File]::WriteAllText($home, $content)` call then writes the string `"C:\Users\awt"` to whatever file was the target — destroying its entire content.

**How to apply:** Always use distinct, non-built-in variable names for output paths in PowerShell: `$outPath`, `$targetFile`, `$outputContent`, `$newContent`, etc. Never `$home`, `$env`, `$args`, `$input`, `$PSVersionTable`, `$host`, `$null`, `$true`, `$false`, `$error`. Check PowerShell automatic variables list when naming script variables.

**Incident (2026-07-09):** `MOC - Home & Practical Life.md` (9,774 bytes, 266 lines) was overwritten with the string `"C:\Users\awt"` (15 bytes) during a classify session. Recovered from git history via `git show cb285aa:"00 - Home Dashboard/MOC - Home & Practical Life.md"`. LevelDB/IndexedDB blob extraction was attempted but too complex to yield clean results without a proper LevelDB parser.
