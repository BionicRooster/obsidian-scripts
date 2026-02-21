# Analyze subsection keywords for duplicates
# Parses the link_largest_orphan.ps1 script and finds keywords that appear in multiple subsections

# $scriptPath: Path to the main script containing subsectionKeywords
$scriptPath = "C:\Users\awt\link_largest_orphan.ps1"

# $scriptContent: The full content of the script file
$scriptContent = Get-Content $scriptPath -Raw

# $allKeywords: Hashtable mapping each keyword to array of locations (MOC|Subsection)
$allKeywords = @{}

# $currentMOC: Tracks the current MOC being parsed
$currentMOC = ""

# $currentSubsection: Tracks the current subsection being parsed
$currentSubsection = ""

# $inKeywordsArray: Flag indicating we're inside a keywords array
$inKeywordsArray = $false

# Split content into lines for parsing
$lines = $scriptContent -split "`n"

# $parsingKeywords: Flag indicating we're inside the $subsectionKeywords block
$parsingKeywords = $false

foreach ($line in $lines) {
    # Start of subsectionKeywords block
    if ($line -match '^\$subsectionKeywords\s*=\s*@\{') {
        $parsingKeywords = $true
        continue
    }

    # End of subsectionKeywords block
    if ($parsingKeywords -and $line -match '^#endregion Configuration') {
        break
    }

    if (-not $parsingKeywords) { continue }

    # Match MOC name: "MOC Name" = @{
    if ($line -match '^\s*"([^"]+)"\s*=\s*@\{\s*$') {
        $currentMOC = $Matches[1]
        continue
    }

    # Match subsection: "Subsection Name" = @(
    if ($line -match '^\s*"([^"]+)"\s*=\s*@\(\s*$') {
        $currentSubsection = $Matches[1]
        $inKeywordsArray = $true
        continue
    }

    # Match closing of array: )
    if ($line -match '^\s*\)\s*$' -and $inKeywordsArray) {
        $inKeywordsArray = $false
        continue
    }

    # Match keywords within array (extract all quoted strings)
    # Skip comment lines (lines starting with #)
    if ($inKeywordsArray -and $currentMOC -and $currentSubsection -and ($line -notmatch '^\s*#')) {
        $keywordMatches = [regex]::Matches($line, '"([^"]+)"')
        foreach ($m in $keywordMatches) {
            $keyword = $m.Groups[1].Value
            $location = "$currentMOC|$currentSubsection"

            if (-not $allKeywords.ContainsKey($keyword)) {
                $allKeywords[$keyword] = @()
            }
            if ($location -notin $allKeywords[$keyword]) {
                $allKeywords[$keyword] += $location
            }
        }
    }
}

# Find duplicates (keywords appearing in 2+ subsections)
$duplicates = $allKeywords.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | Sort-Object { $_.Value.Count } -Descending

Write-Host "=== DUPLICATE KEYWORDS ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Total unique keywords: $($allKeywords.Count)"
Write-Host "Keywords appearing in multiple subsections: $($duplicates.Count)"
Write-Host ""

# Output each duplicate with its locations
foreach ($dup in $duplicates) {
    Write-Host "Keyword: `"$($dup.Key)`" - appears in $($dup.Value.Count) locations:" -ForegroundColor Yellow
    foreach ($loc in $dup.Value) {
        $parts = $loc -split "\|"
        Write-Host "  - MOC: $($parts[0]) / Subsection: $($parts[1])"
    }
    Write-Host ""
}

# Export to JSON for further processing
$duplicateData = @{}
foreach ($dup in $duplicates) {
    $duplicateData[$dup.Key] = $dup.Value
}

$duplicateData | ConvertTo-Json -Depth 3 | Out-File "C:\Users\awt\keyword_duplicates.json" -Encoding UTF8
Write-Host "Duplicate data exported to keyword_duplicates.json" -ForegroundColor Green
