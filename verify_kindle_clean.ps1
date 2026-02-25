$folder = "D:\Obsidian\Main\09 - Kindle Clippings"
$files = Get-ChildItem $folder -Filter "*.md"
$found = $false
foreach ($f in $files) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
    $inFM = $false; $fmCount = 0
    foreach ($line in $lines) {
        if ($line -match '^---') { $fmCount++; if ($fmCount -eq 1) { $inFM = $true } elseif ($fmCount -eq 2) { $inFM = $false }; continue }
        if ($inFM -and $line -match 'nav:') { Write-Host "FRONTMATTER LINK: $($f.Name): $line"; $found = $true }
        if (-not $inFM -and $line -match '\[\[' -and $line -notmatch '^\*\s+Author:' -and $line -notmatch 'amazon\.com') {
            Write-Host "BODY WIKILINK: $($f.Name): $line"; $found = $true
        }
    }
}
if (-not $found) { Write-Host "All clean - no outgoing links found." }
