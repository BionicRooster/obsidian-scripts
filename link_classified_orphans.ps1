# link_classified_orphans.ps1
# Links orphan files to MOC subsections based on AI classification results
# Uses UTF-8 encoding to preserve diacritical characters

param(
    [switch]$DryRun = $false,  # If set, only shows what would be done without making changes
    [switch]$Verbose = $false  # If set, shows detailed progress
)

# Vault path
$vaultPath = "D:\Obsidian\Main"
# MOC folder path
$mocFolder = Join-Path $vaultPath "00 - Home Dashboard"

# Classification files location
$classificationFolder = "C:\Users\awt\AppData\Local\Temp\claude\C--Users-awt\6e63b1ee-8d1a-4517-be13-6d0849521b2b\scratchpad"

# MOC name to file mapping
$mocFileMap = @{
    "MOC - Bahá'í Faith" = "MOC - Bahá'í Faith.md"
    "MOC - Finance & Investment" = "MOC - Finance & Investment.md"
    "MOC - Genealogy" = "MOC - Genealogy.md"
    "MOC - Health & Nutrition" = "MOC - Health & Nutrition.md"
    "MOC - Home & Practical Life" = "MOC - Home & Practical Life.md"
    "MOC - Music & Record" = "MOC - Music & Record.md"
    "MOC - NLP & Psychology" = "MOC - NLP & Psychology.md"
    "MOC - Personal Knowledge Management" = "MOC - Personal Knowledge Management.md"
    "MOC - Reading & Literature" = "MOC - Reading & Literature.md"
    "MOC - Recipes" = "MOC - Recipes.md"
    "MOC - Science & Nature" = "MOC - Science & Nature.md"
    "MOC - Soccer" = "MOC - Soccer.md"
    "MOC - Social Issues" = "MOC - Social Issues.md"
    "MOC - Technology & Computers" = "MOC - Technology & Computers.md"
    "MOC - Travel & Exploration" = "MOC - Travel & Exploration.md"
}

# Subsection header mapping (normalize subsection names to actual headers)
$subsectionMap = @{
    # Bahá'í Faith
    "Core Teachings" = "## Core Teachings"
    "Administrative Guidance" = "## Administrative Guidance"
    "Ridván Messages" = "## Ridván Messages"
    "Central Figures" = "## Central Figures"
    "Bahá'í Institutions" = "## Bahá'í Institutions"
    "Social Issues & Unity" = "## Social Issues & Unity"
    "Community & Service" = "## Community & Service"
    "Bahá'í Books & Resources" = "## Bahá'í Books & Resources"
    "Nine Year Plan" = "## Nine Year Plan"
    "Related Topics" = "## Related Topics"

    # Finance & Investment
    "Investing Strategies" = "## Investing Strategies"
    "Tax Software" = "## Tax Software"
    "Financial Management" = "## Financial Management"
    "Insurance" = "## Insurance"

    # Health & Nutrition
    "Plant-Based Nutrition" = "## Plant-Based Nutrition"
    "WFPB Resources" = "## WFPB Resources"
    "Medical & Health" = "## Medical & Health"
    "Exercise & Wellness" = "## Exercise & Wellness"
    "Health Articles & Clippings" = "## Health Articles & Clippings"

    # Home & Practical Life
    "Home Projects & Repairs" = "## Home Projects & Repairs"
    "Sustainable Building & Alternative Homes" = "## Sustainable Building & Alternative Homes"
    "Gardening & Urban Farming" = "## Gardening & Urban Farming"
    "RV & Mobile Living" = "## RV & Mobile Living"
    "Entertainment & Film" = "## Entertainment & Film"
    "Life Productivity & Organization" = "## Life Productivity & Organization"
    "Practical Tips & Life Hacks" = "## Practical Tips & Life Hacks"
    "Cool Tools" = "## Cool Tools"
    "Sketchplanations" = "## Sketchplanations"

    # Music & Record
    "Recorder Resources" = "## Recorder Resources"
    "Music Theory & Performance" = "## Music Theory & Performance"
    "Record Labels & Resources" = "## Record Labels & Resources"
    "Music Performances & Articles" = "## Music Performances & Articles"

    # NLP & Psychology
    "Core NLP Concepts" = "## Core NLP Concepts"
    "Techniques & Patterns" = "## Techniques & Patterns"
    "Cognitive Science" = "## Cognitive Science"
    "Learning & Memory" = "## Learning & Memory"
    "Reframing" = "## Reframing"
    "Meta Model & Language" = "## Meta Model & Language"
    "Strategies & Modeling" = "## Strategies & Modeling"
    "Language Patterns" = "## Language Patterns"
    "Logical Levels" = "## Logical Levels"
    "Communication & Influence" = "## Communication & Influence"

    # Personal Knowledge Management
    "PKM Systems and Methods" = "## PKM Systems and Methods"
    "Obsidian Integration" = "## Obsidian Integration"
    "Note-Taking and Learning" = "## Note-Taking and Learning"
    "Productivity Philosophy" = "## Productivity Philosophy"
    "GTD and Productivity Methods" = "## GTD and Productivity Methods"
    "Templates" = "## Templates"
    "Writing Tools" = "## Writing Tools"

    # Reading & Literature
    "Key Books by Topic" = "## Key Books by Topic"
    "Kindle Clippings" = "## Kindle Clippings"
    "Book Index" = "## Book Index"
    "All Book Notes" = "## All Book Notes"
    "Productivity and Learning" = "## Productivity and Learning"
    "Chrome/Web Clippings" = "## Chrome/Web Clippings"

    # Recipes
    "Main Dishes" = "## Main Dishes"
    "Soups and Stews" = "## Soups and Stews"
    "Desserts and Sweets" = "## Desserts and Sweets"
    "Breads and Baked Goods" = "## Breads and Baked Goods"
    "Sauces, Dips and Condiments" = "## Sauces, Dips and Condiments"

    # Science & Nature
    "Micrometeorites" = "## Micrometeorites"
    "Earth Sciences and Geology" = "## Earth Sciences & Geology"
    "Archaeology and Anthropology" = "## Archaeology & Anthropology"
    "Paleontology" = "## Paleontology"
    "Life Sciences" = "## Life Sciences"
    "Gardening and Nature" = "## Gardening & Nature"
    "Space and Planetary Science" = "## Space & Planetary Science"
    "Travel and Natural Wonders" = "## Travel & Natural Wonders"
    "Weather" = "## Weather"

    # Soccer
    "Learning the Game" = "## Learning the Game"
    "Ted Lasso and English Football Culture" = "## Ted Lasso and English Football Culture"
    "Major League Soccer (MLS)" = "## Major League Soccer (MLS)"
    "World Cup and International Football" = "## World Cup and International Football"

    # Social Issues
    "Race and Equity" = "## Race & Equity"
    "Justice and Politics" = "## Justice & Politics"
    "Cultural Commentary" = "## Cultural Commentary"
    "Peace and Unity" = "## Peace & Unity"
    "Religion and Society" = "## Religion & Society"
    "Cult Awareness" = "## Cult Awareness"

    # Technology & Computers
    "Computer Sciences" = "## Computer Sciences"
    "Computing Fundamentals" = "## Computing Fundamentals"
    "Programming & Development" = "## Programming & Development"
    "Linux Resources & Guides" = "## Linux Resources & Guides"
    "Software & Tools" = "## Software & Tools"
    "Hardware & Electronics" = "## Hardware & Electronics"
    "Devices & Hardware" = "## Devices & Hardware"
    "AI & Machine Learning" = "## AI & Machine Learning"
    "Retro Computing & Hardware" = "## Retro Computing & Hardware"
    "Maker Projects" = "## Maker Projects"
    "Troubleshooting & Guides" = "## Troubleshooting & Guides"
    "Media & Entertainment Tech" = "## Media & Entertainment Tech"
    "Media & Entertainment" = "## Media & Entertainment Tech"

    # Travel & Exploration
    "Specific Locations" = "## Specific Locations"
    "Narrowboat and Canal Travel" = "## Narrowboat & Canal Travel"
    "RV and Alternative Living" = "## RV & Alternative Living"
    "National Parks and Nature" = "## National Parks & Nature"

    # Genealogy
    "Family Research" = "## Uncategorized / Screen Clippings"
    "Uncategorized / Screen Clippings" = "## Uncategorized / Screen Clippings"
}

# Function to add a link to a MOC subsection
function Add-LinkToMOC {
    param(
        [string]$mocName,       # e.g., "MOC - Technology & Computers"
        [string]$subsection,    # e.g., "Software & Tools"
        [string]$noteName       # e.g., "MyNote.md" (will be converted to [[MyNote]])
    )

    # Get MOC file path
    $mocFileName = $mocFileMap[$mocName]
    if (-not $mocFileName) {
        Write-Warning "Unknown MOC: $mocName"
        return $false
    }

    $mocPath = Join-Path $mocFolder $mocFileName
    if (-not (Test-Path $mocPath)) {
        Write-Warning "MOC file not found: $mocPath"
        return $false
    }

    # Get subsection header
    $header = $subsectionMap[$subsection]
    if (-not $header) {
        # Try direct match with ## prefix
        $header = "## $subsection"
    }

    # Clean note name (remove .md extension)
    $cleanNoteName = $noteName -replace '\.md$', ''
    $wikiLink = "- [[$cleanNoteName]]"

    # Read MOC content
    $content = Get-Content -Path $mocPath -Raw -Encoding UTF8

    # Check if link already exists
    if ($content -match [regex]::Escape("[[$cleanNoteName]]")) {
        if ($Verbose) {
            Write-Host "  Link already exists: $cleanNoteName in $mocName"
        }
        return $false
    }

    # Find the subsection and add the link
    # Try multiple header formats (with or without &)
    $headerVariants = @(
        $header,
        ($header -replace ' & ', ' and '),
        ($header -replace ' and ', ' & ')
    )

    $found = $false
    foreach ($headerVariant in $headerVariants) {
        $escapedHeader = [regex]::Escape($headerVariant)
        $pattern = "(?m)^$escapedHeader\s*$"

        if ($content -match $pattern) {
            $found = $true

            # Find the position after the header
            $match = [regex]::Match($content, $pattern)
            $insertPos = $match.Index + $match.Length

            # Insert the link after the header line
            $newContent = $content.Substring(0, $insertPos) + "`n$wikiLink" + $content.Substring($insertPos)

            if (-not $DryRun) {
                # Write back with UTF-8 encoding (no BOM)
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($mocPath, $newContent, $utf8NoBom)
            }

            return $true
        }
    }

    if (-not $found) {
        Write-Warning "Subsection not found: '$header' in $mocName"
        return $false
    }

    return $false
}

# Load and process classification files
$classificationFiles = Get-ChildItem -Path $classificationFolder -Filter "orphan_classifications*.json"

$totalLinks = 0
$successfulLinks = 0
$skippedLinks = 0
$failedLinks = 0

foreach ($file in $classificationFiles) {
    Write-Host "`nProcessing: $($file.Name)" -ForegroundColor Cyan

    $json = Get-Content -Path $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

    foreach ($classification in $json.classifications) {
        $fileName = $classification.file

        if ($classification.mocs.Count -eq 0) {
            if ($Verbose) {
                Write-Host "  Skipping (no MOCs): $fileName" -ForegroundColor Yellow
            }
            continue
        }

        foreach ($moc in $classification.mocs) {
            $totalLinks++

            $mocName = $moc.moc
            $subsection = $moc.subsection
            $confidence = $moc.confidence

            # Skip null or empty subsections
            if ([string]::IsNullOrEmpty($subsection)) {
                # For Genealogy, use a default subsection
                if ($mocName -eq "MOC - Genealogy") {
                    $subsection = "Uncategorized / Screen Clippings"
                } else {
                    Write-Host "  Skipping (no subsection): $fileName -> $mocName" -ForegroundColor Yellow
                    $skippedLinks++
                    continue
                }
            }

            if ($DryRun) {
                Write-Host "  Would link: $fileName -> $mocName / $subsection ($confidence)" -ForegroundColor Gray
                $successfulLinks++
            } else {
                $result = Add-LinkToMOC -mocName $mocName -subsection $subsection -noteName $fileName
                if ($result) {
                    Write-Host "  Linked: $fileName -> $mocName / $subsection" -ForegroundColor Green
                    $successfulLinks++
                } else {
                    $failedLinks++
                }
            }
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total link attempts: $totalLinks"
Write-Host "Successful links: $successfulLinks" -ForegroundColor Green
Write-Host "Skipped links: $skippedLinks" -ForegroundColor Yellow
Write-Host "Failed links: $failedLinks" -ForegroundColor Red

if ($DryRun) {
    Write-Host "`nDry run complete. No changes were made." -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes." -ForegroundColor Yellow
}
