# Analyze Orphan Files in Obsidian Vault
# Groups orphans by category and filters out system folders

# Vault path for reference
$vaultPath = 'D:\Obsidian\Main'

# Read the orphan list
$orphans = Get-Content 'C:\Users\awt\orphan_files.txt'

# Filter out system folders
$filtered = $orphans | Where-Object {
    $_ -notmatch '^\.trash' -and
    $_ -notmatch '^05 - Templates' -and
    $_ -notmatch '^00 - Images' -and
    $_ -notmatch '^attachments' -and
    $_ -notmatch '^Clippings\\' -and
    $_ -notmatch '\.resources' -and
    $_ -notmatch '^\.obsidian'
}

Write-Host "=== Orphan Analysis ===" -ForegroundColor Cyan
Write-Host "Total orphans: $($orphans.Count)"
Write-Host "After filtering system folders: $($filtered.Count)"
Write-Host ""

# Group by top-level folder
$byFolder = @{}
foreach ($path in $filtered) {
    $parts = $path -split '\\'
    $folder = if ($parts.Count -gt 1) { $parts[0] } else { 'Root' }
    if (-not $byFolder.ContainsKey($folder)) {
        $byFolder[$folder] = @()
    }
    $byFolder[$folder] += $path
}

Write-Host "=== By Folder ===" -ForegroundColor Cyan
$byFolder.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object {
    Write-Host "$($_.Key): $($_.Value.Count)"
}

# Save filtered list
$filtered | Set-Content 'C:\Users\awt\orphan_filtered.txt'
Write-Host ""
Write-Host "Filtered list saved to: C:\Users\awt\orphan_filtered.txt"
