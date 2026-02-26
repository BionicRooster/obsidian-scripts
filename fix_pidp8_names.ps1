# fix_pidp8_names.ps1
# Removes brackets from [pidp8] note filenames and updates all wikilinks
# Rename: "[pidp8] foo.md" -> "pidp8 foo.md"  and  "Re_ [pidp8] foo.md" -> "Re_ pidp8 foo.md"

$vaultPath = "D:\Obsidian\Main"                   # Vault root
$enc       = [System.Text.Encoding]::UTF8          # UTF-8 for all I/O

# --- Step 1: Find all files with [pidp8] in name ---
$pidp8Files = Get-ChildItem $vaultPath -Recurse -Filter '*.md' | Where-Object {
    $_.Name -like '*[[]pidp8[]]*.md'   # [[ and ]] escape brackets in wildcards
}

if ($pidp8Files.Count -eq 0) {
    Write-Host "No [pidp8] files found."
    exit
}

# Build rename map: oldBasename -> newBasename (both without extension)
$renameMap = @{}   # key = old lowercase basename, value = [oldFull, newFull]
foreach ($f in $pidp8Files) {
    $newName = $f.Name -replace '\[pidp8\]', 'pidp8'  # remove brackets
    $newFull = Join-Path $f.DirectoryName $newName
    $renameMap[$f.BaseName.ToLower()] = @{
        OldFull     = $f.FullName
        NewFull     = $newFull
        OldBasename = $f.BaseName
        NewBasename = [System.IO.Path]::GetFileNameWithoutExtension($newName)
    }
    Write-Host "RENAME: $($f.Name)"
    Write-Host "     -> $newName"
}

# --- Step 2: Rename the files ---
Write-Host "`nRenaming files..."
foreach ($entry in $renameMap.Values) {
    if (Test-Path -LiteralPath $entry.OldFull) {
        # Use -LiteralPath to prevent PowerShell treating [ ] in filename as wildcards
        Rename-Item -LiteralPath $entry.OldFull -NewName (Split-Path $entry.NewFull -Leaf) -ErrorAction Stop
        Write-Host "  Renamed: $($entry.OldBasename)"
    }
}

# --- Step 3: Scan all vault .md files and update wikilinks ---
Write-Host "`nUpdating wikilinks..."
$allMd = Get-ChildItem $vaultPath -Recurse -Filter '*.md'

$updatedFiles = 0
foreach ($f in $allMd) {
    $bytes  = [System.IO.File]::ReadAllBytes($f.FullName)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

    $changed = $false
    foreach ($entry in $renameMap.Values) {
        $old = $entry.OldBasename   # e.g. "[pidp8] Another Pathetic Newbie..."
        $new = $entry.NewBasename   # e.g. "pidp8 Another Pathetic Newbie..."
        if ($text.Contains($old)) {
            $text    = $text.Replace($old, $new)
            $changed = $true
        }
        # Also handle lowercase variants (wikilinks may have mixed case in target portion)
        if ($text.ToLower().Contains($old.ToLower()) -and -not $text.Contains($old)) {
            # Case-insensitive only - do a regex replace
            $escaped = [regex]::Escape($old)
            $newText = [regex]::Replace($text, $escaped, $new, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($newText -ne $text) { $text = $newText; $changed = $true }
        }
    }

    if ($changed) {
        $out = if ($hasBom) { $enc.GetPreamble() + $enc.GetBytes($text) } else { $enc.GetBytes($text) }
        [System.IO.File]::WriteAllBytes($f.FullName, $out)
        Write-Host "  Updated links in: $($f.Name)"
        $updatedFiles++
    }
}

Write-Host "`nDone. Renamed $($renameMap.Count) files, updated links in $updatedFiles files."
