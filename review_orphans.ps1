# review_orphans.ps1
# For each orphan file, check:
#   1. Actual filename (double spaces? special chars?)
#   2. Whether the MOC has a link with single space (mismatch)
#   3. First few lines of the file (topic/tags)

$vaultPath = 'C:\Users\awt\Sync\Obsidian'   # Vault root

# Orphan paths as reported (some with double spaces, one with special chars)
$orphanNames = @(
    # Kindle Clippings
    '09 - Kindle Clippings\Bates_et_al-Head First Design Patterns.md',
    '09 - Kindle Clippings\Bettinger-Wayne-Genetic Genealogy in Practice.md',
    '09 - Kindle Clippings\Bruzenak_et_al-Retire to an RV.md',
    '09 - Kindle Clippings\Collins-Waking Up Dead.md',
    '09 - Kindle Clippings\Hawks-Berger-Cave of Bones.md',
    '09 - Kindle Clippings\Kahneman-Thinking Fast and Slow.md',
    '09 - Kindle Clippings\Tellinger-Temples of The African Gods.md',
    '09 - Kindle Clippings\Two Winters in a Tipi.md',
    # Technology - note double spaces
    '01\Technology\AcSpreadSheetType  List.md',
    '01\Technology\FarmVille Cheats  Top 10 Cash Crops.md',
    '01\Technology\Google Apps Standard  Edition.md',
    '01\Technology\LiveCode  Create App.md',
    '01\Technology\Outlook Macro  Move.md',
    '01\Technology\VBA Express  Excel.md',
    # Psychology
    '01\Psychology\HP Retiree  Dave Pac.md',
    # Baha'i
    '01\Bah??\The Tablet of Ahmad.md',
    # Genealogy
    '15 - People\HP Retiree  Dave Packard.md',
    # 10 - Clippings
    '10 - Clippings\GreyNoise Ip Check.md'
)

# Find the Baha'i folder dynamically
$bahaiFolder = Get-ChildItem (Join-Path $vaultPath '01') -Directory |
    Where-Object { $_.Name -match 'Bah' } |
    Select-Object -First 1 -ExpandProperty FullName

foreach ($rel in $orphanNames) {
    # Resolve Baha'i wildcard
    $fullPath = if ($rel -match 'Bah\?\?') {
        Join-Path $bahaiFolder ($rel -split '\\')[-1]
    } else {
        Join-Path $vaultPath $rel
    }

    $exists = Test-Path $fullPath   # Does file exist at expected path?

    # Check for double-space variant (file may exist with single space if it was renamed)
    $singleSpace = $fullPath -replace '  ', ' '   # Single-space version of path
    $existsSingle = if ($fullPath -ne $singleSpace) { Test-Path $singleSpace } else { $false }

    Write-Host "`n--- $rel ---" -ForegroundColor Cyan
    Write-Host "  Expected path exists: $exists"
    if ($fullPath -ne $singleSpace) {
        Write-Host "  Single-space path exists: $existsSingle ($singleSpace)"
    }

    $pathToRead = if ($exists) { $fullPath } elseif ($existsSingle) { $singleSpace } else { $null }

    if ($pathToRead) {
        $bytes  = [System.IO.File]::ReadAllBytes($pathToRead)
        $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        $text   = if ($hasBom) { [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3) } else { [System.Text.Encoding]::UTF8.GetString($bytes) }
        $lines  = $text -split "`n"
        # Print tags and title from frontmatter
        $lines | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "  FILE NOT FOUND at either path" -ForegroundColor Red
    }
}

# Also check Reed Island separately (special chars in name)
Write-Host "`n--- Reed Island (special chars) ---" -ForegroundColor Cyan
$reedFiles = Get-ChildItem (Join-Path $vaultPath '02 - Working Projects') -Recurse -Filter '*Reed*' -ErrorAction SilentlyContinue
$reedFiles += Get-ChildItem $vaultPath -Recurse -Filter '*Reed*Island*' -ErrorAction SilentlyContinue
foreach ($rf in ($reedFiles | Sort-Object FullName -Unique)) {
    Write-Host "  Found: $($rf.FullName)"
}
