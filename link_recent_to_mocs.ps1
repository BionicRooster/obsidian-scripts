# Link recent notes to their appropriate MOCs
# This script adds bidirectional links between notes and MOCs

$vaultPath = "D:\Obsidian\Main"
$mocPath = "$vaultPath\00 - Home Dashboard"

# Classification mapping: Note name (partial match) -> MOC file, Section
$noteToMocMapping = @{
    # Psychology & Cognitive Science -> MOC - NLP & Psychology
    "Thinking, Fast and S" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }
    "Theory of stupidity" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }
    "Gestalt principles" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }
    "Inattentional Blindness" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }
    "Cocktail Party Effect" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }
    "Dunning-Kruger" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }
    "An Autistic Mind" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }
    "Dyslexia May Be the Brain" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Learning & Memory" }
    "The Dyslexie Font" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Learning & Memory" }
    "The Advantages of Dyslexia" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Learning & Memory" }
    "5 Strategies to Demystify" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Learning & Memory" }
    "Ever Dream This Man" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }
    "Changing Our Mind" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }

    # Productivity -> MOC - Personal Knowledge Management
    "Eat the Frog" = @{ MOC = "MOC - Personal Knowledge Management.md"; Section = "## Productivity Philosophy" }
    "The Trolly Problem" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Cognitive Science" }
    "Laplace's Demon" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Life Sciences" }
    "My Obsidian And Gemini" = @{ MOC = "MOC - Personal Knowledge Management.md"; Section = "## Obsidian Integration" }
    "Principles for 21st century" = @{ MOC = "MOC - Personal Knowledge Management.md"; Section = "## Productivity Philosophy" }
    "Dilbert Creator Scott Adams" = @{ MOC = "MOC - Personal Knowledge Management.md"; Section = "## Productivity Philosophy" }
    "Data first by using data" = @{ MOC = "MOC - Technology & Computers.md"; Section = "## AI & Machine Learning" }
    "Simplifying complex ideas" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Sketchplanations" }

    # Social Issues -> MOC - Social Issues
    "How to deconstruct racism" = @{ MOC = "MOC - Social Issues.md"; Section = "## Race & Equity" }
    "Christianity and the cult of Trump" = @{ MOC = "MOC - Social Issues.md"; Section = "## Religion & Society" }
    "Global Religion in the 21st" = @{ MOC = "MOC - Social Issues.md"; Section = "## Religion & Society" }
    "Michael Moore's to do list" = @{ MOC = "MOC - Social Issues.md"; Section = "## Justice & Politics" }
    "Charlie Chaplin's Statement" = @{ MOC = "MOC - Social Issues.md"; Section = "## Justice & Politics" }
    "Shoghi Effendi on Racism" = @{ MOC = "MOC - Social Issues.md"; Section = "## Race & Equity" }
    "Continuum of Racism" = @{ MOC = "MOC - Social Issues.md"; Section = "## Race & Equity" }
    "The Promulgation of Universal Peace" = @{ MOC = "MOC - Social Issues.md"; Section = "## Peace & Unity" }
    "Major causes of disunity" = @{ MOC = "MOC - Social Issues.md"; Section = "## Race & Equity" }
    "5 Ways to Make Friends from Different" = @{ MOC = "MOC - Social Issues.md"; Section = "## Peace & Unity" }
    "First they ignore you" = @{ MOC = "MOC - Social Issues.md"; Section = "## Peace & Unity" }

    # Health -> MOC - Health & Nutrition
    "Child diabetes blamed" = @{ MOC = "MOC - Health & Nutrition.md"; Section = "## Medical & Health" }
    "The McDougall Newsletter" = @{ MOC = "MOC - Health & Nutrition.md"; Section = "## Key Research & Books" }
    "Food Insecurity - Arctic" = @{ MOC = "MOC - Health & Nutrition.md"; Section = "## Medical & Health" }
    "Mattress Encasing" = @{ MOC = "MOC - Health & Nutrition.md"; Section = "## Medical & Health" }
    "Free Your Mind Practice Vipassana" = @{ MOC = "MOC - Health & Nutrition.md"; Section = "## Exercise & Wellness" }

    # Technology -> MOC - Technology & Computers
    "TRMNL The Open Source" = @{ MOC = "MOC - Technology & Computers.md"; Section = "## Maker Projects" }
    "ClaudeCodeInDesktopApplicaiton" = @{ MOC = "MOC - Technology & Computers.md"; Section = "## AI & Machine Learning" }
    "Claude usage limits" = @{ MOC = "MOC - Technology & Computers.md"; Section = "## AI & Machine Learning" }
    "Meaning Of 'Hacker'" = @{ MOC = "MOC - Technology & Computers.md"; Section = "## Computing Fundamentals" }
    "Interviews Forrest Mims" = @{ MOC = "MOC - Technology & Computers.md"; Section = "## Maker Projects" }
    "Hacking when it Counts" = @{ MOC = "MOC - Technology & Computers.md"; Section = "## Maker Projects" }
    "NLP for Programmers" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## NLP for Programmers & Technical Applications" }

    # Science & Nature -> MOC - Science & Nature
    "What Ecologists Are Learning" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Archaeology & Anthropology" }
    "New insights into how the famed Antikythera" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Archaeology & Anthropology" }
    "NASA Is Growing Potatoes" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Space & Planetary Science" }
    "New form of carbon" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Earth Sciences & Geology" }
    "Make a Moss Terrarium" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Gardening & Nature" }
    "Aurora Coolness" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Space & Planetary Science" }
    "Dune Types Transverse" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Earth Sciences & Geology" }
    "Recent rash of killings of environmental" = @{ MOC = "MOC - Social Issues.md"; Section = "## Justice & Politics" }
    "Map Shows How Many Roads" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Archaeology & Anthropology" }
    "Amelia Earhart Died" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Archaeology & Anthropology" }
    "Explore this Fascinating Map of Medieval" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Archaeology & Anthropology" }
    "John Milton's Hand Annotated" = @{ MOC = "MOC - Social Issues.md"; Section = "## Cultural Commentary" }

    # Genealogy -> MOC - Genealogy
    "Chester Hale Talbot" = @{ MOC = "MOC - Genealogy.md"; Section = "## Talbot Family Members" }
    "Vera Irene Talbot" = @{ MOC = "MOC - Genealogy.md"; Section = "## Talbot Family Members" }
    "How to merge two family trees" = @{ MOC = "MOC - Genealogy.md"; Section = "## Resources & How-Tos" }
    "PersonalWeb - Genealogy Help" = @{ MOC = "MOC - Genealogy.md"; Section = "## Resources & How-Tos" }

    # Recipes -> MOC - Recipes
    "Chickpea and Spinach Stew" = @{ MOC = "MOC - Recipes.md"; Section = "## Soups & Stews" }
    "Hot Fruit Compote" = @{ MOC = "MOC - Recipes.md"; Section = "## Desserts & Sweets" }
    "Scientists Found the Temperature" = @{ MOC = "MOC - Recipes.md"; Section = "## Desserts & Sweets" }

    # Music -> MOC - Music & Record
    "Why Violins Have F-Holes" = @{ MOC = "MOC - Music & Record.md"; Section = "## Music Performances & Articles" }
    "Trevor Noah Explains How Kintsugi" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Practical Tips & Life Hacks" }

    # Home & Practical Life -> MOC - Home & Practical Life
    "Grid Beam Building" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Sustainable Building & Alternative Homes" }
    "Fire Pistons" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Practical Tips & Life Hacks" }
    "A Year in the Round Why a tipi" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Sustainable Building & Alternative Homes" }
    "Old Houses Japan" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Sustainable Building & Alternative Homes" }
    "Whole Earth Catalog" = @{ MOC = "MOC - Social Issues.md"; Section = "## Cultural Commentary" }
    "HCAS - Planning" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## The Friends of the Georgetown Public Library" }
    "Derek Timourian" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Georgetown Cultural Citizens Memorial Association" }
    "I'm Almost In Tears!" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Entertainment & Film" }
    "Audible Listening History" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Entertainment & Film" }

    # Finance -> MOC - Finance & Investment
    "Warren Buffett's 3 Favorite Books" = @{ MOC = "MOC - Finance & Investment.md"; Section = "## Investment Books" }

    # Books (Kindle Clippings)
    "Kahneman-Thinking, Fast and Slow" = @{ MOC = "MOC - NLP & Psychology.md"; Section = "## Related Resources" }
    "Ahrens-How to Take Smart Notes" = @{ MOC = "MOC - Personal Knowledge Management.md"; Section = "## Note-Taking & Learning" }
    "McGhee-The Sum of Us" = @{ MOC = "MOC - Social Issues.md"; Section = "## Race & Equity" }
    "Campbell-Jacobson-Whole" = @{ MOC = "MOC - Health & Nutrition.md"; Section = "## Key Research & Books" }

    # Maker/DIY
    "The boy who harnessed the wind" = @{ MOC = "MOC - Technology & Computers.md"; Section = "## Maker Projects" }
    "William Kamkwamba" = @{ MOC = "MOC - Technology & Computers.md"; Section = "## Maker Projects" }

    # Misc
    "Boundary Changes" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Life Productivity & Organization" }
    "Pace Layers" = @{ MOC = "MOC - Home & Practical Life.md"; Section = "## Sketchplanations" }
    "American Nut A History of the Pecan" = @{ MOC = "MOC - Science & Nature.md"; Section = "## Life Sciences" }
}

# Get recent files
$cutoffDate = (Get-Date).AddDays(-7)
$recentFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse |
    Where-Object { $_.CreationTime -gt $cutoffDate } |
    Where-Object { $_.FullName -notmatch "00 - Home Dashboard" }  # Exclude MOC files

$linkedCount = 0
$mocUpdates = @{}

foreach ($file in $recentFiles) {
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $matchedMapping = $null

    # Find matching mapping
    foreach ($key in $noteToMocMapping.Keys) {
        if ($fileName -like "*$key*") {
            $matchedMapping = $noteToMocMapping[$key]
            break
        }
    }

    if ($matchedMapping) {
        $mocFile = "$mocPath\$($matchedMapping.MOC)"
        $section = $matchedMapping.Section

        # Check if link already exists in MOC
        if (Test-Path $mocFile) {
            $mocContent = Get-Content $mocFile -Raw -Encoding UTF8
            $linkPattern = "\[\[$fileName\]\]"

            if ($mocContent -notmatch [regex]::Escape("[[" + $fileName + "]]")) {
                # Track updates to make to MOC
                if (-not $mocUpdates.ContainsKey($mocFile)) {
                    $mocUpdates[$mocFile] = @()
                }
                $mocUpdates[$mocFile] += @{
                    Section = $section
                    Link = "- [[$fileName]]"
                    FileName = $fileName
                }
                $linkedCount++
                Write-Host "Will link: $fileName -> $($matchedMapping.MOC) ($section)"
            }
        }
    }
}

Write-Host "`n=== Summary ==="
Write-Host "Notes to link: $linkedCount"

# Now apply the MOC updates
foreach ($mocFile in $mocUpdates.Keys) {
    $mocContent = Get-Content $mocFile -Raw -Encoding UTF8
    $updates = $mocUpdates[$mocFile]

    foreach ($update in $updates) {
        $section = $update.Section
        $link = $update.Link

        # Find section and add link after it
        if ($mocContent -match "(?m)^$section\s*$") {
            # Add link after section header
            $pattern = "(?m)(^$section\s*\r?\n)"
            $replacement = "`$1$link`n"
            $mocContent = $mocContent -replace $pattern, $replacement
            Write-Host "  Added $($update.FileName) to $section in $([System.IO.Path]::GetFileName($mocFile))"
        }
    }

    # Write updated MOC
    [System.IO.File]::WriteAllText($mocFile, $mocContent, [System.Text.Encoding]::UTF8)
}

Write-Host "`nDone! Linked $linkedCount notes to MOCs."
