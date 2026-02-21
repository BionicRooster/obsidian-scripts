# Find recent orphan files in 20 - Permanent Notes folder only
# These are true orphan files that need classification

$vaultPath = "D:\Obsidian\Main\20 - Permanent Notes"
$cutoffDate = (Get-Date).AddDays(-60)

# Get all .md files in Permanent Notes
$allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -ErrorAction SilentlyContinue

# Filter for recent files, exclude the index file
$recentOrphans = $allFiles | Where-Object {
    $_.CreationTime -gt $cutoffDate -and
    $_.Name -ne "20 - Permanent Notes.md"
}

# Output results
foreach ($file in $recentOrphans) {
    Write-Output "$($file.FullName)|$($file.CreationTime.ToString('yyyy-MM-dd'))"
}
