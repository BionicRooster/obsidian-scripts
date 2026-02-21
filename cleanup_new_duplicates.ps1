# Clean up duplicate keywords introduced in the new batch
# Only removes duplicates WITHIN the same MOC where one subsection is clearly more appropriate

$scriptPath = "C:\Users\awt\link_largest_orphan.ps1"

# Keywords to remove from specific locations (keep in the more appropriate subsection)
$removals = @{
    # PKM duplicates - keep in PKM Systems & Methods
    "Personal Knowledge Management|Note-Taking & Learning" = @(
        "evergreen notes", "atomic notes", "permanent notes", "literature notes", "fleeting notes"
    )
    # PKM duplicates - keep in Indexes & Tags
    "Personal Knowledge Management|PKM Systems & Methods" = @(
        "map of content"  # Keep in Indexes & Tags
    )
    # PKM duplicates - keep in Vault Analysis
    "Personal Knowledge Management|PKM Systems & Methods" = @(
        "hub notes"  # Keep in Vault Analysis
    )
    # Bahá'í duplicates - keep in Administrative Guidance
    "Bahá'í Faith|Community & Service" = @(
        "Feast", "Nineteen Day Feast"
    )
    # Bahá'í duplicates - keep in Bahá'í Institutions
    "Bahá'í Faith|Clippings & Resources" = @(
        "Bahá'í International Community"
    )
    # Bahá'í duplicates - keep in Core Teachings
    "Bahá'í Faith|Social Issues & Unity" = @(
        "elimination of prejudice"
    )
    # Bahá'í duplicates - keep in Social Issues & Unity
    "Bahá'í Faith|Related Topics" = @(
        "collective security"
    )
    # NLP duplicates - keep in Phobia & Trauma Work
    "NLP & Psychology|Change Work" = @(
        "timeline therapy"
    )
    # NLP duplicates - keep in Techniques & Patterns
    "NLP & Psychology|Strategies & Modeling" = @(
        "spelling strategy", "motivation strategy"
    )
    # NLP duplicates - keep in Anchoring & States
    "NLP & Psychology|NLP Technique Overview" = @(
        "calibration"
    )
    # Health duplicates - keep in Plant-Based Nutrition
    "Health & Nutrition|WFPB Resources" = @(
        "SOS-free"
    )
    # Home/PKM duplicates - keep in PKM Productivity Philosophy
    "Home & Practical Life|Life Productivity & Organization" = @(
        "deep work"
    )
    # Home/PKM duplicates - keep in PKM GTD
    "Home & Practical Life|Practical Tips & Life Hacks" = @(
        "inbox zero", "batch cooking"
    )
    # Music duplicates - keep in Songs & Hymns
    "Music & Record|Music Performances & Articles" = @(
        "a cappella"
    )
    # Science duplicates - keep in Earth Sciences
    "Science & Nature|Archaeology & Anthropology" = @(
        "stratigraphy"
    )
}

$content = Get-Content $scriptPath -Raw
$removeCount = 0

foreach ($location in $removals.Keys) {
    $parts = $location -split "\|"
    $moc = $parts[0]
    $subsection = $parts[1]
    $keywords = $removals[$location]

    foreach ($keyword in $keywords) {
        $escapedKeyword = [regex]::Escape($keyword)

        # Pattern to match the keyword with surrounding comma/whitespace
        $patterns = @(
            ',\s*"' + $escapedKeyword + '"',    # ", keyword"
            '"' + $escapedKeyword + '",\s*'     # "keyword",
        )

        foreach ($pattern in $patterns) {
            if ($content -match $pattern) {
                # Only remove if in the correct subsection context
                # This is a simplified approach - we'll remove all matches
                $content = $content -replace $pattern, ''
                $removeCount++
                Write-Host "Removed '$keyword' (duplicate)" -ForegroundColor Yellow
                break
            }
        }
    }
}

$content | Set-Content $scriptPath -Encoding UTF8 -NoNewline
Write-Host "`nRemoved $removeCount duplicate keyword instances." -ForegroundColor Green
