# Find all markdown files created in the last 7 days
# Output: List of file paths and creation times

$vaultPath = "D:\Obsidian\Main"
$cutoffDate = (Get-Date).AddDays(-7)

# Get all markdown files created in the last 7 days
$recentFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse |
    Where-Object { $_.CreationTime -gt $cutoffDate } |
    Sort-Object CreationTime -Descending

# Output file count
Write-Host "Found $($recentFiles.Count) files created in the last 7 days`n"

# Output each file with its creation time
foreach ($file in $recentFiles) {
    $relativePath = $file.FullName.Replace($vaultPath + "\", "")
    Write-Host "$($file.CreationTime.ToString('yyyy-MM-dd HH:mm')) | $relativePath"
}
