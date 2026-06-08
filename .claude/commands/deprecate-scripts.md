Audit the script catalog for deprecated, superseded, and one-off scripts. Present candidates grouped by reason, wait for approval, then move approved scripts to `C:\Users\awt\_deprecated\` and refresh the catalog.

## Parameters

Optional argument: `--dry-run` — produce the candidate list only; do not move any files.

---

## Step 1 — Read the Catalog

Read `memory/domain/scripts.md` (the active script catalog). This file is auto-generated and lists all PS1 and Python scripts in `C:\Users\awt\` with name, description, and last-modified date.

---

## Step 2 — Identify Candidates

Scan every entry in the catalog and flag candidates using these heuristics:

### Group 1 — `temp_*` and `debug_*` scripts → DELETE
Any script whose filename starts with `temp_` or `debug_`. These are explicitly named as temporary or diagnostic and have no reuse value.

### Group 2 — Version series, keep latest only → DELETE older
Detect pairs/series where the same base name exists with a `_v2`, `_v3`, or similar suffix. Keep the highest-numbered version; flag all earlier versions.
Also flag explicit supersession where a general-purpose script replaces a per-task one (e.g., `extract_docx_notes.py` supersedes `extract_light_of_world.py` — check description for per-file names).

### Group 3 — Single-task named scripts → DELETE
Scripts whose description names a specific file, note, or one-time event. Signals: description contains a vault note title, person name, or phrase like "the X file", "missed insertions", "the malformed entry". These are non-reusable.

Also flag completed-project series: scripts for known completed projects (per `memory/projects_completed.md`) with no ongoing value. Examples: Talbot file series, Riḍván fix, title case fix, Kolam/Reed/Kintsugi one-offs.

### Group 4 — Wrong domain → DELETE
Scripts for Office add-ins, Windows registry, COM objects, or other non-vault tasks unrelated to Obsidian or script infrastructure.

### Group 5 — `read_*` diagnostic one-offs → DELETE
Scripts named `read_<specific thing>` that describe reading a single specific file for inspection. These are session artifacts, not utilities.

### Group 6 — Completed-project verifiers → DELETE
Scripts named `verify_<completed project>` or `check_<completed project>` where the project is known to be finished (per memory or description). Do not flag general-purpose validators like `check_yaml.ps1`.

### Group 7 — Journal/activity one-offs → DELETE
Scripts that append a specific dated entry to a journal. Description typically says "append X activity" or "add the Y entry".

### Never flag (always keep)
- Scripts referenced by name in `CLAUDE.md` (e.g., `find_broken_images.ps1`, `fix_backslash_paths.ps1`, `moc_orphan_linker.ps1`, `obsidian_maintenance.ps1`, `update-script-catalog.ps1`)
- Active watchers (`dashboard_watcher.ps1`, `watch_prn_files.ps1`, `pdf_watcher.ps1`)
- General-purpose utilities with broad descriptions
- Scripts modified within the last 30 days (likely active)
- The `_deprecated` folder itself

---

## Step 3 — Present Candidate List

Group candidates into a markdown table per group. For each group show:
- Group name and reason
- Script filenames
- Count

End with a summary table:

| Group | Reason | Count | Action |
|-------|--------|-------|--------|
| ...   | ...    | ...   | Delete |
| **Total** | | N | |

Then stop and ask:
> "Approve all, approve by group number, or name exceptions to skip?"

---

## Step 4 — Dry-Run Gate

If `--dry-run` was passed: stop after Step 3. Do not move any files.

---

## Step 5 — Move Approved Scripts

1. Create `C:\Users\awt\_deprecated\` if it doesn't exist
2. For each approved script, move from `C:\Users\awt\` to `C:\Users\awt\_deprecated\` using `Move-Item`
3. Report: moved count, any not-found (skip silently if already gone)

---

## Step 6 — Refresh Catalog

Run:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\awt\update-script-catalog.ps1"
```

Report the new active script count.

---

## Step 7 — Commit and Push

Stage deletions with `git add -u`, commit with message:

```
Deprecate N superseded and one-off scripts

<one-line summary of groups moved>. Active catalog: X -> Y scripts.
```

Push to `origin main`.

---

## Output

Report:
- Scripts moved: N
- Active scripts remaining: N
- Commit hash
