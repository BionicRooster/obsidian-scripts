# Analyze remaining unlinked orphan files

$vaultPath = 'D:\Obsidian\Main'

# Read orphan list
$orphans = Get-Content 'C:\Users\awt\orphan_filtered.txt'

# Count orphans that still have no "Related Notes" section (weren't processed)
$stillOrphan = @()
foreach ($path in $orphans) {
    $fullPath = Join-Path $vaultPath $path
    if (Test-Path $fullPath) {
        $content = Get-Content -Path $fullPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content -and $content -notmatch '## Related Notes') {
            $stillOrphan += $path
        }
    }
}

Write-Host "Files still without connections: $($stillOrphan.Count)"

# Group by folder
$byFolder = @{}
foreach ($path in $stillOrphan) {
    $parts = $path -split '\\'
    $folder = if ($parts.Count -gt 1) { $parts[0] } else { 'Root' }
    if (-not $byFolder.ContainsKey($folder)) {
        $byFolder[$folder] = @()
    }
    $byFolder[$folder] += $path
}

Write-Host "`nBy folder:"
$byFolder.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object {
    Write-Host "$($_.Key): $($_.Value.Count)"
}

# Show samples from larger groups
Write-Host "`nSample unconnected files (first 30):"
$stillOrphan | Select-Object -First 30
