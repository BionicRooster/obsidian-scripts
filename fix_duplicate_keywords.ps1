# Fix Duplicate Keywords in link_largest_orphan.ps1
# Removes duplicate keywords, keeping only the most applicable subsection for each

# $scriptPath: Path to the main script to modify
$scriptPath = "C:\Users\awt\link_largest_orphan.ps1"

# $reportPath: Path to output the change report
$reportPath = "C:\Users\awt\duplicate_keywords_report.md"

# $keywordRetentionMap: Defines WHERE each duplicate keyword should be RETAINED
# Structure: keyword => "MOC|Subsection" (the ONE location to keep it)
# All other occurrences will be REMOVED
$keywordRetentionMap = @{
    # === HIGHLY GENERIC WORDS - Keep in most specific/primary context ===

    # "index" - Keep in the subsections that are specifically about indexes
    "index" = "Personal Knowledge Management|Indexes & Tags"

    # "resource" - Too generic, keep in PKM Resources since it's about knowledge resources
    "resource" = "Personal Knowledge Management|Resources"

    # "collection" - Keep in PKM Resources
    "collection" = "Personal Knowledge Management|Resources"

    # "study" - Keep in Learning & Memory (about learning process)
    "study" = "NLP & Psychology|Learning & Memory"

    # "organization" - Keep in Life Productivity
    "organization" = "Home & Practical Life|Life Productivity & Organization"

    # "book" - Keep in Reading & Literature (primary books MOC)
    "book" = "Reading & Literature|Key Books by Topic"

    # "library" - Keep in PKM
    "library" = "Personal Knowledge Management|Resources"

    # "reference" - Keep in PKM
    "reference" = "Personal Knowledge Management|Resources"

    # "article" - Keep in Reading/Chrome clippings
    "article" = "Reading & Literature|Chrome/Web Clippings"

    # "method" - Keep in PKM Systems
    "method" = "Personal Knowledge Management|PKM Systems & Methods"

    # "related" - Remove both (too generic), but if keeping: Related MOCs
    "related" = "Soccer|Related MOCs"

    # "clipping" - Keep in Reading Kindle Clippings
    "clipping" = "Reading & Literature|Kindle Clippings"

    # "technique" - Keep in NLP Technique Overview (most specific)
    "technique" = "NLP & Psychology|NLP Technique Overview"

    # "theory" - Keep in Music Theory (more specific)
    "theory" = "Music & Record|Music Theory & Performance"

    # "challenge" - Keep in Andrew Moreno (specific series)
    "challenge" = "NLP & Psychology|Andrew Moreno Series"

    # "flow" - Keep in Soccer Culture (flow state in sports)
    "flow" = "Soccer|Soccer Culture & Values"

    # "story" - Keep in Fiction & Literature
    "story" = "Reading & Literature|Fiction & Literature"

    # === CULTURE/SOCIAL KEYWORDS ===

    # "culture" - Keep in Social Issues Culture (primary)
    "culture" = "Social Issues|Culture"

    # "cultural" - Keep in Cultural Commentary
    "cultural" = "Social Issues|Cultural Commentary"

    # "society" - Keep in Religion & Society
    "society" = "Social Issues|Religion & Society"

    # "social" - Keep in Social Issues MOC
    "social" = "Reading & Literature|Social Issues"

    # "social issues" - Keep in Bahá'í Social Issues & Unity (specific to that community)
    "social issues" = "Bahá'í Faith|Social Issues & Unity"

    # === RACE/EQUITY KEYWORDS - Keep in Social Issues MOC (primary) ===

    "race" = "Social Issues|Race & Equity"
    "racial" = "Social Issues|Race & Equity"
    "racism" = "Social Issues|Race & Equity"
    "prejudice" = "Social Issues|Race & Equity"
    "discrimination" = "Social Issues|Race & Equity"
    "race amity" = "Bahá'í Faith|Social Issues & Unity"
    "Sum of Us" = "Social Issues|Race & Equity"
    "McGhee" = "Social Issues|Race & Equity"
    "Menakem" = "Social Issues|Race & Equity"
    "Jim Crow" = "Social Issues|Race & Equity"

    # === PEACE/UNITY KEYWORDS ===

    "unity" = "Bahá'í Faith|Social Issues & Unity"
    "peace" = "Social Issues|Peace & Unity"
    "world peace" = "Social Issues|Peace & Unity"
    "harmony" = "Music & Record|Music Theory & Performance"

    # === RELIGION KEYWORDS ===

    "religion" = "Reading & Literature|Spirituality & Religion"
    "spirituality" = "Reading & Literature|Spirituality & Religion"
    "cult" = "Social Issues|Cult Awareness"

    # === JUSTICE/POLITICS ===

    "justice" = "Social Issues|Justice & Politics"
    "inclusion" = "Social Issues|Justice & Politics"
    "diversity" = "Social Issues|Justice & Politics"
    "voting" = "Social Issues|Justice & Politics"

    # === BAHÁ'Í SPECIFIC - Keep in Bahá'í Faith MOC ===

    "covenant" = "Bahá'í Faith|Central Figures"
    "institution" = "Bahá'í Faith|Bahá'í Institutions"
    "guidance" = "Bahá'í Faith|Administrative Guidance"
    "oneness" = "Bahá'í Faith|Core Teachings"
    "equality" = "Bahá'í Faith|Core Teachings"
    "education" = "Bahá'í Faith|Core Teachings"
    "community" = "Bahá'í Faith|Community & Service"
    "study circle" = "Bahá'í Faith|Bahá'í Institutions"
    "festival" = "Bahá'í Faith|Ridván Messages"
    "letter" = "Bahá'í Faith|Ridván Messages"
    "Bahá'í" = "Bahá'í Faith|Core Teachings"

    # === SCIENCE & NATURE KEYWORDS ===

    "science" = "Science & Nature|Index"
    "nature" = "Science & Nature|Index"
    "archaeology" = "Science & Nature|Archaeology & Anthropology"
    "micrometeorite" = "Science & Nature|Micrometeorites"
    "stardust" = "Science & Nature|Micrometeorites"
    "Cave of Bones" = "Science & Nature|Archaeology & Anthropology"
    "Mars" = "Science & Nature|Space & Planetary Science"
    "tsunami" = "Science & Nature|Earth Sciences & Geology"
    "genetic" = "Science & Nature|Life Sciences"
    "DNA" = "Home & Practical Life|Genealogy"
    "disease" = "Health & Nutrition|Medical & Health"
    "allergy" = "Health & Nutrition|Medical & Health"
    "coronavirus" = "Health & Nutrition|Medical & Health"
    "specialisation" = "Science & Nature|Life Sciences"
    "sweet potato" = "Recipes|Sweet Potato Collection"

    # === HEALTH & NUTRITION KEYWORDS ===

    "research" = "Health & Nutrition|Key Research & Books"
    "vegan" = "Health & Nutrition|Plant-Based Nutrition"
    "WFPB" = "Health & Nutrition|WFPB Resources"
    "plant-based" = "Health & Nutrition|Plant-Based Nutrition"
    "medical" = "Health & Nutrition|Medical & Health"
    "China Study" = "Health & Nutrition|Key Research & Books"
    "Campbell" = "Health & Nutrition|Key Research & Books"
    "Esselstyn" = "Health & Nutrition|Key Research & Books"
    "PTSD" = "NLP & Psychology|Phobia & Trauma Work"
    "trauma" = "NLP & Psychology|Phobia & Trauma Work"
    "sugar-free" = "Health & Nutrition|WFPB Resources"
    "tofu" = "Health & Nutrition|Plant-Based Nutrition"

    # === TRAVEL KEYWORDS ===

    "travel" = "Travel & Exploration|Travel Index"
    "Japan" = "Travel & Exploration|Japan"
    "Japanese" = "Travel & Exploration|Japan"
    "Nagomi" = "Travel & Exploration|Japan"
    "RV" = "Travel & Exploration|RV & Alternative Living"
    "motorhome" = "Travel & Exploration|RV & Alternative Living"
    "tipi" = "Travel & Exploration|RV & Alternative Living"
    "narrowboat" = "Travel & Exploration|Narrowboat & Canal Travel"
    "lock" = "Travel & Exploration|Narrowboat & Canal Travel"

    # === PRODUCTIVITY & PKM KEYWORDS ===

    "productivity" = "Personal Knowledge Management|Productivity Philosophy"
    "GTD" = "Personal Knowledge Management|GTD & Productivity Methods"
    "Nozbe" = "Personal Knowledge Management|GTD & Productivity Methods"
    "workflow" = "Personal Knowledge Management|Obsidian Integration"
    "Zettelkasten" = "Personal Knowledge Management|PKM Systems & Methods"
    "smart notes" = "Personal Knowledge Management|Note-Taking & Learning"
    "note-taking" = "Personal Knowledge Management|Note-Taking & Learning"
    "slow productivity" = "Personal Knowledge Management|Productivity Philosophy"
    "KonMari" = "Personal Knowledge Management|Productivity Philosophy"
    "Obsidian" = "Personal Knowledge Management|Obsidian Integration"
    "journal" = "Personal Knowledge Management|Writing Tools"

    # === TECHNOLOGY KEYWORDS ===

    "programming" = "Technology & Computing|Programming & Development"
    "coding" = "Technology & Computing|Programming & Development"
    "software" = "Technology & Computing|Software & Applications"
    "application" = "Technology & Computing|Software & Applications"
    "developer" = "Technology & Computing|Programming & Development"
    "database" = "Technology & Computing|Programming & Development"
    "networking" = "Technology & Computing|System Administration"
    "Kindle" = "Technology & Computing|Media & Entertainment"
    "ebook" = "Technology & Computing|Media & Entertainment"
    "streaming" = "Technology & Computing|Media & Entertainment"
    "entertainment" = "Technology & Computing|Media & Entertainment"

    # === READING KEYWORDS ===

    "learning" = "NLP & Psychology|Learning & Memory"
    "cognitive" = "NLP & Psychology|Cognitive Science"
    "Kahneman" = "NLP & Psychology|Cognitive Science"
    "book notes" = "Reading & Literature|All Book Notes"

    # === NLP KEYWORDS ===

    "rapport" = "NLP & Psychology|Anchoring & States"
    "beliefs" = "NLP & Psychology|Logical Levels"
    "values" = "NLP & Psychology|Logical Levels"
    "Phobia cure" = "NLP & Psychology|Phobia & Trauma Work"
    "NLP process" = "NLP & Psychology|NLP Technique Overview"

    # === MUSIC KEYWORDS ===

    "renaissance recorder" = "Music & Record|Recorder Resources"
    "drumming" = "Music & Record|Music Performances & Articles"
    "improvisation" = "Music & Record|Music Performances & Articles"

    # === SOCCER KEYWORDS ===

    "tactics" = "Soccer|Positions & Formations"
    "Ted Lasso" = "Soccer|Ted Lasso & English Football Culture"
    "Believe" = "Soccer|Soccer Books & Literature"
    "World Cup" = "Soccer|World Cup & International Football"
    "Qatar" = "Soccer|2022 Qatar World Cup"
    "Germany" = "Soccer|World Cup & International Football"
    "formation" = "Soccer|Positions & Formations"
    "position" = "Soccer|Positions & Formations"
    "MLS" = "Soccer|Major League Soccer (MLS)"
    "team" = "Soccer|Teams & Leagues"
    "sportsmanship" = "Soccer|Soccer Culture & Values"

    # === FINANCE KEYWORDS ===

    "Warren Buffett" = "Finance & Investment|Investing Strategies"
    "Benjamin Graham" = "Finance & Investment|Investing Strategies"

    # === HOME & PRACTICAL LIFE ===

    "garden" = "Home & Practical Life|Gardening & Urban Farming"
    "gardening" = "Home & Practical Life|Gardening & Urban Farming"
    "DIY" = "Home & Practical Life|Home Projects & Repairs"

    # === RECIPES ===

    "chili recipe" = "Recipes|Main Dishes"
}

# Read the original script
$scriptContent = Get-Content $scriptPath -Raw

# $changes: Array to track all changes made
$changes = @()

# Process each keyword that needs deduplication
foreach ($keyword in $keywordRetentionMap.Keys) {
    $retainLocation = $keywordRetentionMap[$keyword]
    $retainParts = $retainLocation -split "\|"
    $retainMOC = $retainParts[0]
    $retainSubsection = $retainParts[1]

    # Find all occurrences of this keyword in the script
    # We need to find the pattern: "keyword" within keyword arrays

    # Escape special regex characters in keyword
    $escapedKeyword = [regex]::Escape($keyword)

    # Pattern to match the keyword as a standalone quoted string
    # We'll look for it in context and remove from non-retained locations

    # For each MOC and subsection, check if keyword exists and should be removed
    # This requires parsing the structure to know current MOC/subsection context
}

# Let's do a more targeted approach - parse and rebuild the keywords section
# First, extract the subsectionKeywords block

$startMarker = '$subsectionKeywords = @{'
$endMarker = '#endregion Configuration Variables'

$startIndex = $scriptContent.IndexOf($startMarker)
$endIndex = $scriptContent.IndexOf($endMarker)

if ($startIndex -lt 0 -or $endIndex -lt 0) {
    Write-Host "ERROR: Could not find subsectionKeywords block markers" -ForegroundColor Red
    exit 1
}

# Extract the block
$beforeBlock = $scriptContent.Substring(0, $startIndex)
$blockContent = $scriptContent.Substring($startIndex, $endIndex - $startIndex)
$afterBlock = $scriptContent.Substring($endIndex)

# Parse and process the block line by line
$lines = $blockContent -split "`n"
$newLines = @()
$currentMOC = ""
$currentSubsection = ""
$inKeywordsArray = $false
$removedCount = 0

foreach ($line in $lines) {
    $modifiedLine = $line
    $shouldRemoveLine = $false

    # Track current MOC
    if ($line -match '^\s*"([^"]+)"\s*=\s*@\{\s*$') {
        $currentMOC = $Matches[1]
    }

    # Track current subsection
    if ($line -match '^\s*"([^"]+)"\s*=\s*@\(\s*$') {
        $currentSubsection = $Matches[1]
        $inKeywordsArray = $true
    }

    # End of array
    if ($line -match '^\s*\)\s*$' -and $inKeywordsArray) {
        $inKeywordsArray = $false
    }

    # Process keywords within array
    if ($inKeywordsArray -and $currentMOC -and $currentSubsection) {
        $currentLocation = "$currentMOC|$currentSubsection"

        # Check each keyword in our retention map
        foreach ($keyword in $keywordRetentionMap.Keys) {
            $retainLocation = $keywordRetentionMap[$keyword]

            # Skip if this IS the location to retain
            if ($currentLocation -eq $retainLocation) {
                continue
            }

            # Check if this line contains this keyword
            $escapedKeyword = [regex]::Escape($keyword)
            $pattern = '"' + $escapedKeyword + '"'

            if ($line -match $pattern) {
                # Need to remove this keyword from this line
                # Handle various patterns:
                # 1. "keyword", "other" -> "other"
                # 2. "other", "keyword" -> "other"
                # 3. "keyword" (only one) -> remove line or leave empty

                # Remove the keyword with surrounding comma handling
                $beforePattern = ',\s*"' + $escapedKeyword + '"'
                $afterPattern = '"' + $escapedKeyword + '",\s*'
                $onlyPattern = '^\s*"' + $escapedKeyword + '",?\s*$'

                $originalLine = $modifiedLine

                # Try to remove with comma before
                if ($modifiedLine -match $beforePattern) {
                    $modifiedLine = $modifiedLine -replace $beforePattern, ''
                }
                # Try to remove with comma after
                elseif ($modifiedLine -match $afterPattern) {
                    $modifiedLine = $modifiedLine -replace $afterPattern, ''
                }
                # Check if it's the only keyword on line
                elseif ($modifiedLine -match $onlyPattern) {
                    $shouldRemoveLine = $true
                }

                if ($originalLine -ne $modifiedLine -or $shouldRemoveLine) {
                    $removedCount++
                    $changes += [PSCustomObject]@{
                        Keyword = $keyword
                        Action = "REMOVED"
                        FromMOC = $currentMOC
                        FromSubsection = $currentSubsection
                        RetainedIn = $retainLocation
                    }
                }
            }
        }
    }

    if (-not $shouldRemoveLine) {
        $newLines += $modifiedLine
    }
}

# Reconstruct the script
$newBlockContent = $newLines -join "`n"
$newScriptContent = $beforeBlock + $newBlockContent + $afterBlock

# Write the modified script
$newScriptContent | Set-Content $scriptPath -Encoding UTF8 -NoNewline

Write-Host "Modified script saved. Removed $removedCount keyword occurrences." -ForegroundColor Green

# Generate the report
$reportContent = @"
# Duplicate Keywords Removal Report

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary

- **Total duplicate keyword instances removed:** $removedCount
- **Unique keywords processed:** $($keywordRetentionMap.Count)

## Changes Made

The following keywords were found in multiple subsections. Each keyword has been retained
in only the most applicable subsection (shown in **bold**) and removed from all other locations.

---

"@

# Group changes by keyword
$groupedChanges = $changes | Group-Object Keyword | Sort-Object Name

foreach ($group in $groupedChanges) {
    $keyword = $group.Name
    $retainLocation = $keywordRetentionMap[$keyword]
    $retainParts = $retainLocation -split "\|"

    $reportContent += @"

### "$keyword"

**RETAINED IN:** $($retainParts[0]) / $($retainParts[1])

**REMOVED FROM:**

"@

    foreach ($change in $group.Group) {
        $reportContent += "- $($change.FromMOC) / $($change.FromSubsection)`n"
    }
}

# Add unchanged duplicates (keywords found in multiple places but we may have missed)
$reportContent += @"

---

## Keyword Retention Decisions

Below is the complete list of duplicate keywords and their designated primary location:

| Keyword | Retained In (MOC / Subsection) |
|---------|-------------------------------|
"@

foreach ($keyword in ($keywordRetentionMap.Keys | Sort-Object)) {
    $location = $keywordRetentionMap[$keyword]
    $parts = $location -split "\|"
    $reportContent += "| $keyword | $($parts[0]) / $($parts[1]) |`n"
}

$reportContent | Set-Content $reportPath -Encoding UTF8

Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan
Write-Host "`nChanges summary:"
Write-Host "  - Keywords deduplicated: $($groupedChanges.Count)"
Write-Host "  - Total removals: $removedCount"
