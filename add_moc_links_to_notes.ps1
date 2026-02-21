# Add MOC links to recent notes that are missing them
# This creates bidirectional links from notes back to MOCs

$vaultPath = "D:\Obsidian\Main"

# Classification mapping: Note pattern -> MOC name
$noteToMocMapping = @{
    # Psychology & Cognitive Science
    "Thinking, Fast and S" = "MOC - NLP & Psychology"
    "Theory of stupidity" = "MOC - NLP & Psychology"
    "Gestalt principles" = "MOC - NLP & Psychology"
    "Inattentional Blindness" = "MOC - NLP & Psychology"
    "Cocktail Party Effect" = "MOC - NLP & Psychology"
    "Dunning-Kruger" = "MOC - NLP & Psychology"
    "An Autistic Mind" = "MOC - NLP & Psychology"
    "Dyslexia May Be the Brain" = "MOC - NLP & Psychology"
    "The Dyslexie Font" = "MOC - NLP & Psychology"
    "The Advantages of Dyslexia" = "MOC - NLP & Psychology"
    "5 Strategies to Demystify" = "MOC - NLP & Psychology"
    "Ever Dream This Man" = "MOC - NLP & Psychology"
    "Changing Our Mind" = "MOC - NLP & Psychology"
    "The Trolly Problem" = "MOC - NLP & Psychology"
    "Laplace's Demon" = "MOC - Science & Nature"

    # Productivity
    "Eat the Frog" = "MOC - Personal Knowledge Management"
    "My Obsidian And Gemini" = "MOC - Personal Knowledge Management"
    "Principles for 21st century" = "MOC - Personal Knowledge Management"
    "Dilbert Creator Scott Adams" = "MOC - Personal Knowledge Management"
    "Data first by using data" = "MOC - Technology & Computers"
    "Simplifying complex ideas" = "MOC - Home & Practical Life"

    # Social Issues
    "How to deconstruct racism" = "MOC - Social Issues"
    "Christianity and the cult of Trump" = "MOC - Social Issues"
    "Global Religion in the 21st" = "MOC - Social Issues"
    "Michael Moore's to do list" = "MOC - Social Issues"
    "Charlie Chaplin's Statement" = "MOC - Social Issues"
    "Shoghi Effendi on Racism" = "MOC - Social Issues"
    "Continuum of Racism" = "MOC - Social Issues"
    "The Promulgation of Universal Peace" = "MOC - Social Issues"
    "Major causes of disunity" = "MOC - Social Issues"
    "5 Ways to Make Friends" = "MOC - Social Issues"
    "First they ignore you" = "MOC - Social Issues"
    "John Milton's Hand Annotated" = "MOC - Social Issues"

    # Health
    "Child diabetes blamed" = "MOC - Health & Nutrition"
    "The McDougall Newsletter" = "MOC - Health & Nutrition"
    "Food Insecurity - Arctic" = "MOC - Health & Nutrition"
    "Mattress Encasing" = "MOC - Health & Nutrition"
    "Free Your Mind Practice Vipassana" = "MOC - Health & Nutrition"

    # Technology
    "TRMNL The Open Source" = "MOC - Technology & Computers"
    "ClaudeCodeInDesktopApplicaiton" = "MOC - Technology & Computers"
    "Claude usage limits" = "MOC - Technology & Computers"
    "Meaning Of 'Hacker'" = "MOC - Technology & Computers"
    "Interviews Forrest Mims" = "MOC - Technology & Computers"
    "Hacking when it Counts" = "MOC - Technology & Computers"
    "NLP for Programmers" = "MOC - NLP & Psychology"
    "The boy who harnessed" = "MOC - Technology & Computers"
    "William Kamkwamba" = "MOC - Technology & Computers"

    # Science & Nature
    "What Ecologists Are Learning" = "MOC - Science & Nature"
    "Antikythera Mechanism" = "MOC - Science & Nature"
    "NASA Is Growing Potatoes" = "MOC - Science & Nature"
    "New form of carbon" = "MOC - Science & Nature"
    "Make a Moss Terrarium" = "MOC - Science & Nature"
    "Aurora Coolness" = "MOC - Science & Nature"
    "Dune Types" = "MOC - Science & Nature"
    "Recent rash of killings" = "MOC - Social Issues"
    "Map Shows How Many Roads" = "MOC - Science & Nature"
    "Amelia Earhart Died" = "MOC - Science & Nature"
    "Explore this Fascinating Map of Medieval" = "MOC - Science & Nature"
    "American Nut A History" = "MOC - Science & Nature"

    # Genealogy
    "Chester Hale Talbot" = "MOC - Genealogy"
    "Vera Irene Talbot" = "MOC - Genealogy"
    "How to merge two family" = "MOC - Genealogy"
    "PersonalWeb - Genealogy Help" = "MOC - Genealogy"

    # Recipes
    "Chickpea and Spinach Stew" = "MOC - Recipes"
    "Hot Fruit Compote" = "MOC - Recipes"
    "Scientists Found the Temperature" = "MOC - Recipes"

    # Music
    "Why Violins Have F-Holes" = "MOC - Music & Record"
    "Trevor Noah Explains How Kintsugi" = "MOC - Home & Practical Life"

    # Home & Practical Life
    "Grid Beam Building" = "MOC - Home & Practical Life"
    "Fire Pistons" = "MOC - Home & Practical Life"
    "A Year in the Round" = "MOC - Home & Practical Life"
    "Old Houses Japan" = "MOC - Home & Practical Life"
    "Whole Earth Catalog" = "MOC - Social Issues"
    "HCAS - Planning" = "MOC - Home & Practical Life"
    "Derek Timourian" = "MOC - Home & Practical Life"
    "I'm Almost In Tears" = "MOC - Home & Practical Life"
    "Audible Listening History" = "MOC - Home & Practical Life"
    "Boundary Changes" = "MOC - Home & Practical Life"
    "Pace Layers" = "MOC - Home & Practical Life"

    # Finance
    "Warren Buffett's 3 Favorite" = "MOC - Finance & Investment"

    # Books
    "Kahneman-Thinking" = "MOC - NLP & Psychology"
    "Ahrens-How to Take Smart Notes" = "MOC - Personal Knowledge Management"
    "McGhee-The Sum of Us" = "MOC - Social Issues"
    "Campbell-Jacobson-Whole" = "MOC - Health & Nutrition"
}

# Get recent files
$cutoffDate = (Get-Date).AddDays(-7)
$recentFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse |
    Where-Object { $_.CreationTime -gt $cutoffDate } |
    Where-Object { $_.FullName -notmatch "00 - Home Dashboard" }

$updatedCount = 0

foreach ($file in $recentFiles) {
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $matchedMOC = $null

    # Find matching MOC
    foreach ($key in $noteToMocMapping.Keys) {
        if ($fileName -like "*$key*") {
            $matchedMOC = $noteToMocMapping[$key]
            break
        }
    }

    if ($matchedMOC) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8

        # Check if MOC link already exists
        if ($content -notmatch [regex]::Escape("[[" + $matchedMOC)) {
            # Check if Related Notes section exists
            if ($content -match "## Related Notes") {
                # Add MOC link to existing Related Notes section
                $newLink = "- [[00 - Home Dashboard/$matchedMOC|$matchedMOC]]"
                $content = $content -replace "(## Related Notes\s*\r?\n)", "`$1$newLink`n"
            } else {
                # Add Related Notes section at end
                $relatedSection = "`n---`n## Related Notes`n- [[00 - Home Dashboard/$matchedMOC|$matchedMOC]]`n"
                $content = $content.TrimEnd() + $relatedSection
            }

            [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
            Write-Host "Added MOC link to: $fileName -> $matchedMOC"
            $updatedCount++
        }
    }
}

Write-Host "`n=== Summary ==="
Write-Host "Notes updated with MOC links: $updatedCount"
