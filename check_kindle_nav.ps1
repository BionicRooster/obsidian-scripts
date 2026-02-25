# Check all Kindle Clippings files for nav properties or outgoing wikilinks in frontmatter
$folder = "D:\Obsidian\Main\09 - Kindle Clippings"
$files = Get-ChildItem $folder -Filter "*.md" | Sort-Object Name

Write-Host "=== Files with nav or outgoing links ==="
foreach ($f in $files) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
    $inFM = $false; $fmCount = 0
    foreach ($line in $lines) {
        if ($line -match '^---') { $fmCount++; if ($fmCount -eq 1) { $inFM = $true } elseif ($fmCount -eq 2) { $inFM = $false } continue }
        if ($inFM -and $line -match 'nav:') { Write-Host "$($f.Name): NAV: $line" }
    }
}
Write-Host ""
Write-Host "=== Files missing author metadata ==="
foreach ($f in $files) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
    $inFM = $false; $fmCount = 0; $hasAuthor = $false
    foreach ($line in $lines) {
        if ($line -match '^---') { $fmCount++; if ($fmCount -eq 1) { $inFM = $true } elseif ($fmCount -eq 2) { $inFM = $false } continue }
        if ($inFM -and $line -match '^author') { $hasAuthor = $true }
    }
    if (-not $hasAuthor) { Write-Host $f.Name }
}
