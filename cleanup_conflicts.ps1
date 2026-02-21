# cleanup_conflicts.ps1
# Fix conflicting files and clean up 04 - Indexes folder

# Replace Hardware.md with the better version from old folder
Copy-Item -Path 'D:\Obsidian\Main\04 - Indexes\Computer Sciences\Hardware\Hardware.md' -Destination 'D:\Obsidian\Main\01\Technology\Hardware.md' -Force
Write-Host 'Replaced Hardware.md with better version' -ForegroundColor Green

# Delete the old conflicting files we don't need
Remove-Item -Path 'D:\Obsidian\Main\04 - Indexes\Computer Sciences\Linux.md' -Force
Remove-Item -Path 'D:\Obsidian\Main\04 - Indexes\Computer Sciences\Windows.md' -Force
Remove-Item -Path 'D:\Obsidian\Main\04 - Indexes\Computer Sciences\Hardware\Hardware.md' -Force
Remove-Item -Path 'D:\Obsidian\Main\04 - Indexes\Religion\Religion.md' -Force
Write-Host 'Deleted old conflicting files' -ForegroundColor Green

# Clean up empty folders recursively
$sourceFolder = 'D:\Obsidian\Main\04 - Indexes'
$emptyFolders = Get-ChildItem -Path $sourceFolder -Recurse -Directory -ErrorAction SilentlyContinue |
    Sort-Object { $_.FullName.Length } -Descending

foreach ($folder in $emptyFolders) {
    $items = Get-ChildItem -Path $folder.FullName -Force -ErrorAction SilentlyContinue
    if ($items.Count -eq 0) {
        Remove-Item -Path $folder.FullName -Force -ErrorAction SilentlyContinue
        Write-Host "Removed empty folder: $($folder.Name)" -ForegroundColor Gray
    }
}

# Check if main 04 - Indexes is empty
$remaining = Get-ChildItem -Path $sourceFolder -Force -ErrorAction SilentlyContinue
if ($remaining.Count -eq 0) {
    Remove-Item -Path $sourceFolder -Force
    Write-Host 'Removed empty 04 - Indexes folder' -ForegroundColor Green
} else {
    Write-Host 'Remaining items in 04 - Indexes:' -ForegroundColor Yellow
    $remaining | ForEach-Object { Write-Host $_.FullName }
}

Write-Host ''
Write-Host '=== Migration Complete ===' -ForegroundColor Cyan
