# fix_curly_apostrophes.ps1
# Renames all files and folders in the Obsidian vault that contain curly apostrophes
# (U+2019) to use standard apostrophes (U+0027), using a two-step rename to avoid
# Windows case-insensitive conflicts.

$vaultPath = "C:\Users\awt\Sync\Obsidian"
$curlyApostrophe = [char]0x2019    # ' (U+2019 right single quotation mark)
$straightApostrophe = "'"           # ' (U+0027 standard apostrophe)

$renamedFiles   = 0
$renamedFolders = 0
$errors         = 0

Write-Host "Scanning vault for curly apostrophes in filenames..." -ForegroundColor Cyan

# Process FILES — deepest first so folder renames don't break paths
$files = Get-ChildItem -Path $vaultPath -Recurse -File |
    Where-Object { $_.Name -match [regex]::Escape($curlyApostrophe) } |
    Sort-Object { $_.FullName.Length } -Descending

foreach ($file in $files) {
    $newName = $file.Name -replace [regex]::Escape($curlyApostrophe), $straightApostrophe
    $newPath = Join-Path $file.DirectoryName $newName

    # Two-step rename: old -> temp -> new (handles Windows case-insensitivity)
    $tempPath = Join-Path $file.DirectoryName ("__tmp_" + [System.IO.Path]::GetRandomFileName())

    try {
        Rename-Item -LiteralPath $file.FullName -NewName $tempPath -ErrorAction Stop
        Rename-Item -LiteralPath $tempPath      -NewName $newPath  -ErrorAction Stop
        Write-Host "  FILE: $($file.Name)" -ForegroundColor Yellow
        Write-Host "     -> $newName" -ForegroundColor Green
        $renamedFiles++
    } catch {
        Write-Host "  ERROR renaming $($file.FullName): $_" -ForegroundColor Red
        # Attempt rollback if temp exists
        if (Test-Path $tempPath) {
            try { Rename-Item -LiteralPath $tempPath -NewName $file.FullName } catch {}
        }
        $errors++
    }
}

# Process FOLDERS — shallowest first so paths remain valid
$folders = Get-ChildItem -Path $vaultPath -Recurse -Directory |
    Where-Object { $_.Name -match [regex]::Escape($curlyApostrophe) } |
    Sort-Object { $_.FullName.Length }

foreach ($folder in $folders) {
    $newName = $folder.Name -replace [regex]::Escape($curlyApostrophe), $straightApostrophe
    $newPath = Join-Path $folder.Parent.FullName $newName

    $tempPath = Join-Path $folder.Parent.FullName ("__tmp_" + [System.IO.Path]::GetRandomFileName())

    try {
        Rename-Item -LiteralPath $folder.FullName -NewName $tempPath -ErrorAction Stop
        Rename-Item -LiteralPath $tempPath        -NewName $newPath  -ErrorAction Stop
        Write-Host "  FOLDER: $($folder.Name)" -ForegroundColor Yellow
        Write-Host "       -> $newName" -ForegroundColor Green
        $renamedFolders++
    } catch {
        Write-Host "  ERROR renaming $($folder.FullName): $_" -ForegroundColor Red
        if (Test-Path $tempPath) {
            try { Rename-Item -LiteralPath $tempPath -NewName $folder.FullName } catch {}
        }
        $errors++
    }
}

Write-Host ""
Write-Host "Done. Files renamed: $renamedFiles  |  Folders renamed: $renamedFolders  |  Errors: $errors" -ForegroundColor Cyan
