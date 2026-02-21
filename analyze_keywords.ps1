# Analyze keywords for duplicates across subsections in link_largest_orphan.ps1
# This script parses the keyword definitions and finds duplicates

$allKeywords = @{}

# Read the script file line by line and extract keywords
$lines = Get-Content "C:\Users\awt\link_largest_orphan.ps1" -Encoding UTF8
$currentMOC = ""
$currentSubsection = ""
$inKeywordArray = $false

foreach ($line in $lines) {
    # Detect MOC header (like "Bahá'í Faith" = @{)
    if ($line -match '^\s*"([^"]+)"\s*=\s*@\{') {
        $currentMOC = $matches[1]
    }
    # Detect subsection (like "Central Figures" = @()
    elseif ($line -match '^\s*"([^"]+)"\s*=\s*@\(') {
        $currentSubsection = $matches[1]
        $inKeywordArray = $true
    }
    # Detect end of keyword array
    elseif ($line -match '^\s*\)' -and $inKeywordArray) {
        $inKeywordArray = $false
    }
    # Extract keywords from array
    elseif ($inKeywordArray -and $line -match '"([^"]+)"') {
        $keywords = [regex]::Matches($line, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
        foreach ($kw in $keywords) {
            $kwLower = $kw.ToLower().Trim()
            if (-not $allKeywords.ContainsKey($kwLower)) {
                $allKeywords[$kwLower] = @()
            }
            $allKeywords[$kwLower] += "$currentMOC / $currentSubsection"
        }
    }
}

# Find duplicates (keywords appearing in multiple subsections)
Write-Host "`n=== DUPLICATE KEYWORDS (appearing in multiple subsections) ===" -ForegroundColor Yellow
$duplicates = $allKeywords.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | Sort-Object { $_.Value.Count } -Descending
foreach ($dup in $duplicates) {
    $uniqueLocations = $dup.Value | Select-Object -Unique
    if ($uniqueLocations.Count -gt 1) {
        Write-Host "`nKeyword: '$($dup.Key)' appears in $($uniqueLocations.Count) different subsections:" -ForegroundColor Cyan
        $uniqueLocations | ForEach-Object { Write-Host "  - $_" }
    }
}

# Count total
$realDuplicates = $duplicates | Where-Object { ($_.Value | Select-Object -Unique).Count -gt 1 }
Write-Host "`n`nTotal keywords appearing in multiple different subsections: $($realDuplicates.Count)" -ForegroundColor Green

# Also identify potentially generic/short keywords
Write-Host "`n`n=== POTENTIALLY GENERIC KEYWORDS (short words or common terms) ===" -ForegroundColor Yellow
$genericCandidates = @(
    "table", "index", "guide", "tool", "change", "state", "test", "process",
    "pattern", "strategy", "model", "system", "method", "health", "team",
    "league", "position", "formation", "art", "flow", "journey", "adventure",
    "culture", "society", "peace", "unity", "spiritual", "travel", "weather",
    "space", "plant", "garden", "writing", "reading", "book", "music", "media",
    "device", "software", "hardware", "network", "memory", "learning"
)

Write-Host "`nChecking these common terms for potential false-positive risk:"
foreach ($term in $genericCandidates) {
    if ($allKeywords.ContainsKey($term)) {
        $locations = $allKeywords[$term] | Select-Object -Unique
        Write-Host "  '$term' -> $($locations -join '; ')" -ForegroundColor Magenta
    }
}
