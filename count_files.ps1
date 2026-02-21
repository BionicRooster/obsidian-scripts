# Count files in each 01 subdirectory
$destBase = "D:\Obsidian\Main\01"
$folders = Get-ChildItem -Path $destBase -Directory

Write-Host "=== Final File Counts by Category ===" -ForegroundColor Cyan
$total = 0

foreach ($folder in $folders | Sort-Object Name) {
    $count = (Get-ChildItem -Path $folder.FullName -Filter "*.md" -Recurse).Count
    Write-Host ("{0}: {1}" -f $folder.Name, $count)
    $total += $count
}

Write-Host "`nTotal files in 01 folders: $total" -ForegroundColor Green

# Check remaining in 20 - Permanent Notes
$remaining20 = (Get-ChildItem -Path "D:\Obsidian\Main\20 - Permanent Notes" -Filter "*.md" | Where-Object { $_.Name -ne "20 - Permanent Notes.md" }).Count
Write-Host "`nRemaining in 20 - Permanent Notes: $remaining20"

# Check remaining in 10 - Clippings
$remaining10 = (Get-ChildItem -Path "D:\Obsidian\Main\10 - Clippings" -Filter "*.md").Count
Write-Host "Remaining in 10 - Clippings: $remaining10"
