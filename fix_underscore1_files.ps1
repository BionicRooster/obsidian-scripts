# Fix files ending with _1
# - If no collision: rename to remove _1
# - If collision: keep largest file, delete smaller, rename if needed

param(
    [switch]$WhatIf,  # Preview changes without modifying files
    [string]$Path = "D:\Obsidian\Main"
)

# Track statistics
$renamed = 0
$deleted = 0
$kept = 0
$actions = @()

# Find all files ending with _1 (before extension)
$files = Get-ChildItem -Path $Path -Filter "*_1.md" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $files) {
    # Skip if DirectoryName is null
    if (-not $file.DirectoryName) { continue }

    # Get the base name without _1
    $baseName = $file.BaseName -replace '_1$', ''
    $newName = "$baseName$($file.Extension)"
    $newPath = Join-Path $file.DirectoryName $newName

    # Check if a file without _1 already exists
    if (Test-Path $newPath) {
        # Collision exists - compare file sizes
        $existingFile = Get-Item $newPath
        $file1Size = $file.Length
        $file2Size = $existingFile.Length

        $relativePath1 = $file.FullName -replace [regex]::Escape($Path + "\"), ""
        $relativePath2 = $existingFile.FullName -replace [regex]::Escape($Path + "\"), ""

        if ($file1Size -ge $file2Size) {
            # _1 file is larger or equal - delete the other, rename _1 file
            $actions += [PSCustomObject]@{
                Action = "DELETE"
                File = $relativePath2
                Size = $file2Size
                Reason = "Smaller than _1 version ($file2Size vs $file1Size bytes)"
            }
            $actions += [PSCustomObject]@{
                Action = "RENAME"
                File = $relativePath1
                Size = $file1Size
                NewName = $newName
                Reason = "Larger/equal, removing _1 suffix"
            }

            if (-not $WhatIf) {
                Remove-Item $existingFile.FullName -Force
                Rename-Item $file.FullName -NewName $newName
                $deleted++
                $renamed++
            }
        } else {
            # Existing file is larger - delete _1 file, keep existing
            $actions += [PSCustomObject]@{
                Action = "DELETE"
                File = $relativePath1
                Size = $file1Size
                Reason = "Smaller than non-_1 version ($file1Size vs $file2Size bytes)"
            }
            $actions += [PSCustomObject]@{
                Action = "KEEP"
                File = $relativePath2
                Size = $file2Size
                Reason = "Larger file"
            }

            if (-not $WhatIf) {
                Remove-Item $file.FullName -Force
                $deleted++
                $kept++
            }
        }
    } else {
        # No collision - simply rename
        $relativePath = $file.FullName -replace [regex]::Escape($Path + "\"), ""
        $actions += [PSCustomObject]@{
            Action = "RENAME"
            File = $relativePath
            Size = $file.Length
            NewName = $newName
            Reason = "No collision, removing _1 suffix"
        }

        if (-not $WhatIf) {
            Rename-Item $file.FullName -NewName $newName
            $renamed++
        }
    }
}

# Output summary
Write-Host "`n========== SUMMARY ==========" -ForegroundColor Green
if ($WhatIf) {
    Write-Host "PREVIEW MODE - No files were modified" -ForegroundColor Yellow
}
Write-Host "Files found with _1 suffix: $($files.Count)"
Write-Host "Files renamed: $renamed"
Write-Host "Files deleted (duplicates): $deleted"
Write-Host "Files kept (larger non-_1 version): $kept"

if ($actions.Count -gt 0) {
    Write-Host "`nActions:" -ForegroundColor Cyan
    $actions | Format-Table -Property Action, File, Size, NewName, Reason -AutoSize -Wrap
}
