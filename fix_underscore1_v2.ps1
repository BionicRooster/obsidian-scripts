# Fix files ending with _1 - Version 2 (handles edge cases)
param(
    [switch]$WhatIf,
    [string]$Path = "D:\Obsidian\Main"
)

$renamed = 0
$deleted = 0

# Find all files ending with _1 (before extension)
$files = Get-ChildItem -Path $Path -Filter "*_1.md" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $files) {
    if (-not $file.DirectoryName) { continue }

    # Get the base name without _1
    $baseName = $file.BaseName -replace '_1$', ''
    $newName = "$baseName$($file.Extension)"
    $newPath = Join-Path $file.DirectoryName $newName

    $relativePath = $file.FullName -replace [regex]::Escape($Path + "\"), ""

    # Check if a file without _1 already exists
    if (Test-Path -LiteralPath $newPath) {
        # Collision - get both file sizes
        $existingFileInfo = Get-Item -LiteralPath $newPath -ErrorAction SilentlyContinue

        if (-not $existingFileInfo) {
            Write-Host "ERROR: Could not get info for $newPath" -ForegroundColor Red
            continue
        }

        $file1Size = $file.Length
        $file2Size = $existingFileInfo.Length

        if ($file1Size -ge $file2Size) {
            # _1 file is larger or equal - delete the other, rename _1 file
            Write-Host "DELETE: $newPath ($file2Size bytes - smaller)" -ForegroundColor Yellow
            Write-Host "RENAME: $relativePath -> $newName ($file1Size bytes - larger)" -ForegroundColor Green

            if (-not $WhatIf) {
                Remove-Item -LiteralPath $newPath -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 100  # Small delay to ensure file is deleted
                Rename-Item -LiteralPath $file.FullName -NewName $newName -ErrorAction SilentlyContinue
                $deleted++
                $renamed++
            }
        } else {
            # Existing file is larger - delete _1 file
            Write-Host "DELETE: $relativePath ($file1Size bytes - smaller)" -ForegroundColor Yellow
            Write-Host "KEEP:   $newPath ($file2Size bytes - larger)" -ForegroundColor Cyan

            if (-not $WhatIf) {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
                $deleted++
            }
        }
    } else {
        # No collision - simply rename
        Write-Host "RENAME: $relativePath -> $newName (no collision)" -ForegroundColor Green

        if (-not $WhatIf) {
            Rename-Item -LiteralPath $file.FullName -NewName $newName -ErrorAction SilentlyContinue
            $renamed++
        }
    }
}

Write-Host "`n========== SUMMARY ==========" -ForegroundColor Green
if ($WhatIf) { Write-Host "PREVIEW MODE" -ForegroundColor Yellow }
Write-Host "Files renamed: $renamed"
Write-Host "Files deleted: $deleted"
