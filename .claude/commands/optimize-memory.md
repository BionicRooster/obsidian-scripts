Perform a full review and optimization of the Claude memory system. Work through the following steps in order and report every change made.

## Step 1 — Read and validate the indexes

Run the helper script to read both index files and validate them in one deterministic pass.
Substitute the actual current working directory for `<CWD>`:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\awt\.claude\commands\check-memory-indexes.ps1" -ProjectCwd "<CWD>"
```

The script outputs:
- Full content of the global index (`memory.md`) and the project `MEMORY.md`
- Dead pointer findings — index entries referencing files that do not exist
- Lines exceeding 150 characters
- Global index line count with a warning if over 200

Use this output as the basis for all subsequent steps. Do not re-read the index files manually.

## Step 2 — Read every referenced memory file

For each entry listed in both indexes (from Step 1 output), read the actual file. Do not skip any. Note the content, type (user/feedback/project/reference), and apparent freshness.

## Step 3 — Check each file for these problems

For every memory file, evaluate:

**Staleness:** Does the file reference files, paths, functions, or scripts that may no longer exist? Verify suspicious paths with Glob or Grep before flagging. If stale, update or remove the entry.

**Accuracy:** Does the content conflict with what you can observe right now in the codebase or vault? If so, correct it.

**Duplication:** Is the same fact recorded in two or more files? Consolidate to the most appropriate location and remove the duplicate.

**Wrong layer:** Is a fact in project memory that clearly applies to ALL projects (should be global)? Or is something in global memory that is specific to this project only? Move it to the correct layer. Never duplicate — remove from the source layer after moving.

**Consolidation opportunity:** Are there 3 or more related facts scattered across separate entries or inline in the index that belong together in a `domain/<topic>.md` file? Create the domain file and update the index pointer.

**Bloat:** Is any single file growing unwieldy (more than ~60 lines of content)? Consider splitting into focused sub-files.

**Missing Why/How:** Feedback memories should have a **Why:** line and a **How to apply:** line. If either is missing, add them based on context.

## Step 4 — Check the index files themselves

The script in Step 1 already ran these mechanical checks:
- Dead pointers (index entries pointing to files that don't exist) — fix any flagged
- Lines over 150 characters — trim any flagged
- Global index line count vs. 200-line cap — consolidate or remove entries if over cap

Additionally check:
- Is every memory file in the memory directory listed in its index? If a file exists but is not indexed, add it.

## Step 5 — Check the global/project split rule

Re-read the Cross-Memory Sync Rule from the global index. Scan both layers for any violation: facts duplicated across both layers, or facts clearly in the wrong layer. Resolve each violation.

## Step 6 — Report

Produce a summary table of every change made:

| File | Change type | Description |
|------|-------------|-------------|
| ... | Updated / Created / Deleted / Moved / Merged | Brief description |

If nothing needed changing in a file, do not list it. If no changes were needed at all, say so explicitly.
