# compare_conflicts.ps1
# Compare conflicting files to determine if they're duplicates

$conflicts = @(
    @{Old='D:\Obsidian\Main\04 - Indexes\Computer Sciences\Linux.md'; New='D:\Obsidian\Main\01\Technology\Linux.md'},
    @{Old='D:\Obsidian\Main\04 - Indexes\Computer Sciences\Windows.md'; New='D:\Obsidian\Main\01\Technology\Windows.md'},
    @{Old='D:\Obsidian\Main\04 - Indexes\Computer Sciences\Hardware\Hardware.md'; New='D:\Obsidian\Main\01\Technology\Hardware.md'},
    @{Old='D:\Obsidian\Main\04 - Indexes\Religion\Religion.md'; New='D:\Obsidian\Main\01\Religion\Religion.md'}
)

foreach ($c in $conflicts) {
    $oldContent = [System.IO.File]::ReadAllText($c.Old, [System.Text.Encoding]::UTF8)
    $newContent = [System.IO.File]::ReadAllText($c.New, [System.Text.Encoding]::UTF8)

    $fileName = Split-Path $c.Old -Leaf
    Write-Host "=== Comparing $fileName ===" -ForegroundColor Cyan
    Write-Host "Old size: $($oldContent.Length) chars"
    Write-Host "New size: $($newContent.Length) chars"

    if ($oldContent -eq $newContent) {
        Write-Host "IDENTICAL - can delete old" -ForegroundColor Green
        # Delete the old duplicate
        Remove-Item -Path $c.Old -Force
        Write-Host "Deleted: $($c.Old)" -ForegroundColor Gray
    } else {
        Write-Host "DIFFERENT - keeping both (old has more content)" -ForegroundColor Yellow
        # Show size difference
        if ($oldContent.Length -gt $newContent.Length) {
            Write-Host "Old file is LARGER - consider replacing new with old" -ForegroundColor Magenta
        }
    }
    Write-Host ''
}

# Clean up empty folders
Write-Host "=== Cleaning up empty folders ===" -ForegroundColor Cyan
$sourceFolder = "D:\Obsidian\Main\04 - Indexes"

$emptyFolders = Get-ChildItem -Path $sourceFolder -Recurse -Directory -ErrorAction SilentlyContinue |
    Sort-Object { $_.FullName.Length } -Descending

foreach ($folder in $emptyFolders) {
    $items = Get-ChildItem -Path $folder.FullName -Force -ErrorAction SilentlyContinue
    if ($items.Count -eq 0) {
        Write-Host "Removing empty folder: $($folder.Name)" -ForegroundColor Gray
        Remove-Item -Path $folder.FullName -Force -ErrorAction SilentlyContinue
    }
}

# Check what's left
Write-Host ""
Write-Host "=== Remaining in 04 - Indexes ===" -ForegroundColor Cyan
$remaining = Get-ChildItem -Path $sourceFolder -Recurse -File -ErrorAction SilentlyContinue
if ($remaining) {
    $remaining | ForEach-Object { Write-Host $_.FullName }
} else {
    Write-Host "Folder is now empty or can be deleted" -ForegroundColor Green
}
