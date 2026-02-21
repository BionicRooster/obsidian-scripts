# Cleanup Misplaced Links from MOCs
# Removes links that were incorrectly added by keyword matching

$vaultPath = 'D:\Obsidian\Main'

# Define misplaced links to remove from each MOC
$cleanupRules = @{
    "MOC - Home & Practical Life" = @(
        "Navajo sand painting",
        "Windows|Windows]]",  # Both Windows entries (OS related)
        "AlomWare Tool Box",
        "Cool Tools - Scrivener",
        "How to Make Windows",
        "windows - vbscript",
        "Windows XP Slipstrea",
        "A Painting Georgia O'Keeffe",
        "Ban Eyck painting"
    )
    "MOC - Music & Record" = @(
        "NLP for Programmers",
        "xkcd- Sandwich Helix",
        "PersonalWeb - FOL help file",
        "Soil Microbe Transplants",
        "NatGeo Wallpaper",
        "Wallpaper Roundup",
        "xkcd Is It Worth",
        "You Can Help Decode",
        "The Great Sulphur Pyramids",
        "How I help free innocent prisoners"
    )
    "MOC - Technology & Computers" = @(
        "Navajo sand painting",
        "7 Practices - Practices That Restored My Buddhist Faith",
        "Archivists Finally Found the Wright Brothers",
        "Charlie Chaplin's Statement Against Fascism",
        "Earthquake Turned This New Zealand",
        "My Neighbor's Faith",
        "PersonalWeb - Edna Mae Fillingim",
        "PersonalWeb - Einstein Diet",
        "PersonalWeb - Loving poster",
        "PersonalWeb - MAGAbert",
        "Prairiedog Japanese",
        "Pumping station station disguised",
        "Rainn Wilson on Oprah",
        "Sugar Free Apple Pie",
        "This 400-mile Trail",
        "Waitress Discovers",
        "A Brief History of Children Sent Through the Mail",
        "A Painting Georgia O'Keeffe",
        "Ban Eyck painting",
        "Ukraine's mammoth bone shelters",
        "On the Trail of Stardust"
    )
    "MOC - Science & Nature" = @(
        "Edna Mae Fillingim",
        "PersonalWeb - Edna Mae Fillingim",
        "Michael Moore's to do list",
        "Star Trek - a critique"
    )
    "MOC - Recipes" = @(
        "Fisher-The Canals of",
        "This 'Fish Car' Lets",
        "Price to Tangible Bo"
    )
    "MOC - Social Issues" = @(
        "Community Tech Handout"
    )
    "MOC - Finance & Investment" = @(
        "Turn an FM Transmitter"
    )
    "MOC - Soccer" = @(
        "SMART Goals"
    )
    "MOC - Travel & Exploration" = @(
        "PDF - AirPort Extreme Setup Guide"
    )
    "MOC - NLP & Psychology" = @(
        "John Milton's Hand Annotated"
    )
}

$totalRemoved = 0

foreach ($mocName in $cleanupRules.Keys) {
    $mocPath = Join-Path $vaultPath "00 - Home Dashboard\$mocName.md"

    if (-not (Test-Path $mocPath)) {
        Write-Host "MOC not found: $mocPath" -ForegroundColor Red
        continue
    }

    Write-Host "`nCleaning $mocName..." -ForegroundColor Cyan
    $content = Get-Content $mocPath -Raw -Encoding UTF8
    $originalLength = $content.Length
    $linksToRemove = $cleanupRules[$mocName]
    $removedCount = 0

    foreach ($linkPattern in $linksToRemove) {
        # Match the full line containing this link pattern
        $pattern = "(?m)^- \[\[[^\]]*$([regex]::Escape($linkPattern))[^\]]*\]\]`r?`n?"

        if ($content -match $pattern) {
            $content = $content -replace $pattern, ""
            Write-Host "  Removed: $linkPattern" -ForegroundColor Yellow
            $removedCount++
            $totalRemoved++
        }
    }

    if ($removedCount -gt 0) {
        # Clean up any double newlines that might result
        $content = $content -replace "`r?`n`r?`n`r?`n", "`n`n"
        Set-Content $mocPath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  Removed $removedCount misplaced links" -ForegroundColor Green
    } else {
        Write-Host "  No misplaced links found" -ForegroundColor Gray
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total misplaced links removed: $totalRemoved" -ForegroundColor Green
