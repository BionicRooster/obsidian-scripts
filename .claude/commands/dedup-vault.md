# Vault Duplicate Note Cleanup (`/dedup-vault`)

Detect and remove duplicate notes from the Obsidian vault. For each duplicate pair, merges unique content into the canonical version, cleans up all inbound links, and deletes the weaker file. Leaves zero broken links and zero stubs behind.

**Trigger:** "check vault for duplicates", "find duplicate notes", "dedup vault", "duplicate cleanup"

---

## Step 1 — Detect Filename Duplicates

Run PowerShell to find all `.md` files sharing a filename across different folders (excluding `.trash`):

```powershell
Get-ChildItem -Recurse -Filter "*.md" "D:\Obsidian\Main" |
    Where-Object { $_.DirectoryName -notmatch '\\\.trash' } |
    Group-Object Name | Where-Object { $_.Count -gt 1 } |
    Select-Object Name, Count, @{N='Paths';E={($_.Group.FullName -join ' | ')}} |
    Sort-Object Count -Descending
```

Also check for numbered import artifacts (files with `(1)`, `(2)`, etc. in name):

```powershell
Get-ChildItem -Recurse -Filter "*.md" "D:\Obsidian\Main" |
    Where-Object { $_.Name -match '\(\d+\)' } |
    Select-Object Name, DirectoryName | Sort-Object Name
```

---

## Step 2 — Classify Each Pair

For each duplicate pair, read both files and classify:

| Type | Description | Action |
|---|---|---|
| **True duplicate** | Same name, one is a stub or weaker version | Delete weaker, merge unique content |
| **Intentional parallel** | Same name but genuinely different purpose (e.g., People entry + topic note) | Treat as true duplicate — People version wins; merge content |
| **Import artifact** | Numbered suffix `(N)` but no base file — distinct note with bad name | Rename only (no deletion) |
| **Thread continuation** | `(2)`, `(3)` alongside a base file — same email thread | Legitimate; no action |

**Decision rule for "which to keep":**
1. If one is in `15 - People/` with full biography format → keep People version
2. If one is in `30 - Synthesis/` and the other is a thin stub → keep Synthesis version
3. If one is in a correct-type folder (`16 - Organizations/` for a club) → keep correct-folder version
4. Otherwise keep the one with more content / more inbound links

---

## Step 3 — For Each True Duplicate: Merge → Check Links → Delete

For each pair, execute in order:

### 3a. Read both files fully
Identify any content in the "to-delete" file not present in the "to-keep" file:
- Image embeds (`![[...]]`)
- Related Notes links not already in the surviving file
- Unique tags or frontmatter fields

### 3b. Merge unique content into surviving file
Use `Edit` to add missing items to the surviving file's Related Notes or body.

### 3c. Check for explicit path-based inbound links
Grep the vault for any links using the full folder path of the file to be deleted:

```
Grep pattern: `folder[/\\]filename` (without .md extension)
```

If hits found: edit those files to update the path to the surviving file's path.
If no hits: deletion is safe — bare `[[Note Name]]` links resolve automatically once the ambiguity is removed.

**Safe pattern for multi-file link rewrites** — use a flat `[string[]]` array of old/new pairs. PowerShell flattens `@(@("a","b"))` into `@("a","b")`, so `$pair[0]` becomes a single character, not the first string. Always pass alternating old/new values in a single flat array:

```powershell
function Update-VaultFile {
    param($Path, [string[]]$Replacements)
    $content = Get-Content $Path -Raw -Encoding UTF8
    for ($i = 0; $i -lt $Replacements.Count; $i += 2) {
        $old = $Replacements[$i]; $new = $Replacements[$i+1]
        if ($content -match [regex]::Escape($old)) {
            $content = $content -replace [regex]::Escape($old), $new
        }
    }
    Set-Content -Path $Path -Value $content -Encoding UTF8 -NoNewline
}
# Call with flat alternating pairs:
Update-VaultFile $path @("old name 1", "new name 1", "old name 2", "new name 2")
```

**If a file is corrupted by a bad replace**: check if it's tracked by git (`git ls-files "path"`), then restore with `git show "HEAD:path" | Set-Content "path" -Encoding UTF8`. Do NOT use `git checkout HEAD -- path` if any sibling path in the same command is untracked — the whole command exits 1 and may not restore tracked files.

### 3d. Delete the weaker file
```powershell
Remove-Item "D:\Obsidian\Main\path\to\file.md" -ErrorAction Stop
```

---

## Step 4 — Handle Numbered-Suffix Import Artifacts

Files like `Vegan Planet - Recipe (1).md` with **no base file** are distinct notes with poor names. Do NOT delete. Flag for a separate rename pass:
- Check the `title:` frontmatter field for the actual title
- Rename using the actual title (e.g., `Vegan Planet - Sloppy Giuseppes.md`)
- Ask user before renaming if the correct title is unclear

---

## Step 5 — Verify

```powershell
# Should return no output (zero remaining duplicates)
Get-ChildItem -Recurse -Filter "*.md" "D:\Obsidian\Main" |
    Where-Object { $_.DirectoryName -notmatch '\\\.trash' } |
    Group-Object Name | Where-Object { $_.Count -gt 1 }
```

Spot-check: grep for each deleted file's explicit path — should return zero hits.

---

## Step 6 — Log to Claude Action Log

Append a `## YYYY-MM-DD` section to `D:\Obsidian\Main\01\PKM\Claude Action Log.md` with `[LINT]` prefix entries:

```
[LINT] Duplicate note audit — N exact-filename duplicates resolved, 0 remaining
- [DELETE] path/deleted.md → reason; content merged into path/kept.md
```

---

## Notes

- **Obsidian link resolution**: When two files share a filename, `[[Note Name]]` links are ambiguous. Deleting one clears the ambiguity automatically — no mass link rewrites needed unless explicit paths are used.
- **Numbered files that DO have a base file** (e.g., `Re_ Subject (2).md` alongside `Re_ Subject.md`) are likely email thread continuations — they are distinct notes, not duplicates.
- **People Index priority**: Per vault rules, the `15 - People/` biography is always canonical. If a topic note duplicates a People entry, merge into the People version.
- **Synthesis priority**: Per vault rules, `30 - Synthesis/` pages supersede thin topic stubs on the same subject.
- **Never delete without reading** — always verify the file to delete contains no unique content before removal.
