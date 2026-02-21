# Summary Report for Orphan Classification and Linking
$vaultPath = 'D:\Obsidian\Main'

Write-Host "=== ORPHAN CLASSIFICATION AND LINKING SUMMARY ===" -ForegroundColor Cyan
Write-Host ""

# Count orphan files that are now linked
$orphanFolder = Join-Path $vaultPath '20 - Permanent Notes'
$orphanFiles = Get-ChildItem -Path $orphanFolder -Filter '*.md' -ErrorAction SilentlyContinue
$linkedOrphans = 0
$totalOrphans = $orphanFiles.Count

foreach ($file in $orphanFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($content -match '## Related Notes') {
        $linkedOrphans++
    }
}

Write-Host "ORPHAN FILES (20 - Permanent Notes):" -ForegroundColor Yellow
Write-Host "  Total files: $totalOrphans"
Write-Host "  Files with Related Notes: $linkedOrphans"
Write-Host ""

# Count MOC links
Write-Host "MOC FILES UPDATED:" -ForegroundColor Yellow
$mocFolder = Join-Path $vaultPath '00 - Home Dashboard'
$mocFiles = Get-ChildItem -Path $mocFolder -Filter 'MOC - *.md' -ErrorAction SilentlyContinue
$totalMocLinks = 0

foreach ($moc in $mocFiles) {
    $content = Get-Content -Path $moc.FullName -Raw -Encoding UTF8
    $linkCount = ([regex]::Matches($content, '\[\[')).Count
    $totalMocLinks += $linkCount
    $mocTopic = $moc.Name -replace 'MOC - ', '' -replace '.md', ''
    Write-Host "  $mocTopic`: $linkCount links"
}

Write-Host ""
Write-Host "Total MOC links: $totalMocLinks" -ForegroundColor Green
Write-Host ""

# Count all files with crosslinks
$allFiles = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch '09 - Kindle Clippings|\.trash|05 - Templates|\.obsidian|\.smart-env'
}

$filesWithCrosslinks = 0
foreach ($file in $allFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($content -match '## Related Notes') {
        $filesWithCrosslinks++
    }
}

Write-Host "CROSSLINKING:" -ForegroundColor Yellow
Write-Host "  Total vault files analyzed: $($allFiles.Count)"
Write-Host "  Files with Related Notes sections: $filesWithCrosslinks"
