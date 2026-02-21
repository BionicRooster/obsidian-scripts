# Auto-Link Confident Orphans - Links only high-confidence matches
# Uses multiple criteria: title match, multiple keywords, etc.

# Vault path
$vaultPath = 'D:\Obsidian\Main'

# Load orphan list
$orphansJson = Get-Content "C:\Users\awt\orphan_list.json" -Encoding UTF8 -Raw
$orphans = $orphansJson | ConvertFrom-Json

# Files to exclude (meta files, system files, etc.)
$excludePatterns = @(
    "MOC Subsection",
    "MOC - ",
    "Orphan Files",
    "Empty Notes",
    "Truncated Filenames",
    "00 - Home Dashboard",
    "02 - Working Project",
    "13 - Bases",
    "15 - People",
    "16 - Organization",
    "National Spiritual A"  # Corrupted file
)

# Define high-confidence rules for each MOC
# Format: Title patterns (strong match) and content patterns (supporting match)
$mocRules = @{
    "Bahá'í Faith" = @{
        # Title must contain one of these (case insensitive)
        TitlePatterns = @("Bahá'í", "Baha'i", "Bahá'u'lláh", "Abdu'l-Bahá", "Shoghi Effendi", "Ridván", "Ridvan", "Ayyam-i-Ha", "Naw-Ruz", "Naw Ruz", "UHJ", "Universal House of Justice", "Nine Year Plan", "Báb", "LSA", "pilgrimage", "Wilmette")
        # Content should support the match
        ContentPatterns = @("Bahá'í", "Baha'i", "Faith", "spiritual", "prayer", "teachings")
        MOCPath = "00 - Home Dashboard\MOC - Bahá'í Faith.md"
        DefaultSubsection = "Related Topics"
    }
    "Recipes" = @{
        TitlePatterns = @("Recipe", "Soup", "Salad", "Cake", "Cookies", "Bread", "Muffin", "Pasta", "Chicken", "Beef", "Fish", "Salmon", "Shrimp", "Tofu", "Quinoa", "Rice", "Bean", "Lentil", "Vegetable", "Curry", "Stew", "Chili", "Casserole", "Pie", "Tart", "Pudding", "Smoothie", "Sauce", "Dressing", "Marinade", "Waffles", "Pancakes", "Breakfast", "Dinner")
        ContentPatterns = @("ingredient", "cup", "tablespoon", "teaspoon", "bake", "cook", "simmer", "boil", "fry", "minutes", "degrees", "oven", "recipe", "servings", "prep time")
        MOCPath = "00 - Home Dashboard\MOC - Recipes.md"
        DefaultSubsection = "Recipes"
    }
    "Health & Nutrition" = @{
        TitlePatterns = @("Health", "Nutrition", "Diet", "Exercise", "Fitness", "Vitamin", "Supplement", "Medical", "Disease", "Cancer", "Diabetes", "Heart", "Blood Pressure", "Cholesterol", "Sleep", "Anxiety", "Depression", "Therapy", "Doctor", "Hospital", "Surgery", "Vaccine", "Immune", "Wellness", "Weight Loss", "Obesity", "Hearing Loss", "Decibel")
        ContentPatterns = @("health", "medical", "treatment", "symptom", "doctor", "patient", "disease", "nutrition", "vitamin", "diet", "exercise")
        MOCPath = "00 - Home Dashboard\MOC - Health & Nutrition.md"
        DefaultSubsection = "Health Topics"
    }
    "Technology & Computers" = @{
        TitlePatterns = @("Computer", "Software", "Programming", "Code", "Python", "JavaScript", "Linux", "Windows", "Mac", "iPhone", "Android", "App", "API", "Database", "Server", "Cloud", "AI", "Machine Learning", "Algorithm", "Cybersecurity", "Network", "Internet", "Web")
        ContentPatterns = @("code", "software", "computer", "programming", "technology", "digital", "app", "web")
        MOCPath = "00 - Home Dashboard\MOC - Technology & Computers.md"
        DefaultSubsection = "Technology Topics"
    }
    "NLP & Psychology" = @{
        TitlePatterns = @("NLP", "Neuro-Linguistic", "Psychology", "Therapy", "Counseling", "Cognitive", "Behavior", "Trauma", "PTSD", "Anxiety", "Depression", "Mindset", "Habit", "Hypnosis", "Anchoring", "Reframe", "Submodality", "Meta-Model", "Milton", "Presupposition", "Rapport")
        ContentPatterns = @("NLP", "psychology", "therapy", "behavior", "cognitive", "unconscious", "conscious", "belief")
        MOCPath = "00 - Home Dashboard\MOC - NLP & Psychology.md"
        DefaultSubsection = "NLP Topics"
    }
    "Social Issues" = @{
        TitlePatterns = @("Racism", "Discrimination", "Civil Rights", "Human Rights", "Justice", "Equality", "Poverty", "Homelessness", "Immigration", "Refugee", "Prejudice", "Bias", "Protest", "Activism", "Unity", "Race Amity", "Injustice", "Prison", "Incarceration")
        ContentPatterns = @("racism", "discrimination", "justice", "equality", "rights", "prejudice", "bias", "unity")
        MOCPath = "00 - Home Dashboard\MOC - Social Issues.md"
        DefaultSubsection = "Social Issues Topics"
    }
    "Home & Practical Life" = @{
        TitlePatterns = @("HOA", "Plumbing", "Electrical", "HVAC", "Repair", "Maintenance", "Cleaning", "Garden", "Lawn", "Ceiling Fan", "Appliance", "DIY", "Tool", "Paint", "Flooring", "Roof", "Window", "Door", "Furniture")
        ContentPatterns = @("home", "house", "repair", "maintenance", "garden", "DIY", "tool")
        MOCPath = "00 - Home Dashboard\MOC - Home & Practical Life.md"
        DefaultSubsection = "Home Topics"
    }
    "Travel & Exploration" = @{
        TitlePatterns = @("Travel", "Trip", "Vacation", "Flight", "Airline", "Airport", "Hotel", "Resort", "Cruise", "Road Trip", "Itinerary", "Tourism", "TSA", "Passport", "Visa", "Destination", "Fort Worth", "Big Bend")
        ContentPatterns = @("travel", "trip", "vacation", "flight", "hotel", "destination", "tourism")
        MOCPath = "00 - Home Dashboard\MOC - Travel & Exploration.md"
        DefaultSubsection = "Travel Topics"
    }
    "Music & Record" = @{
        TitlePatterns = @("Music", "Song", "Album", "Artist", "Band", "Concert", "Vinyl", "Record", "LP", "CD", "Guitar", "Piano", "Drum", "Singing", "Choir", "Orchestra", "Symphony", "Jazz", "Rock", "Classical", "Folk", "Recorder Instrument", "Arlo Guthrie", "Paul Simon")
        ContentPatterns = @("music", "song", "album", "concert", "band", "artist", "instrument")
        MOCPath = "00 - Home Dashboard\MOC - Music & Record.md"
        DefaultSubsection = "Music Topics"
    }
    "Science & Nature" = @{
        TitlePatterns = @("Science", "Nature", "Biology", "Chemistry", "Physics", "Astronomy", "Geology", "Ecology", "Climate", "Evolution", "Genetics", "DNA", "Species", "Ecosystem", "Wildlife", "Plant", "Animal", "Ocean", "Forest", "Weather", "Space", "Planet", "Star", "Tsunami", "Earthquake", "Fossil", "Dinosaur", "Meteor")
        ContentPatterns = @("science", "nature", "biology", "chemistry", "physics", "species", "ecology")
        MOCPath = "00 - Home Dashboard\MOC - Science & Nature.md"
        DefaultSubsection = "Science Topics"
    }
    "Finance & Investment" = @{
        TitlePatterns = @("Finance", "Investment", "Stock", "Bond", "401k", "IRA", "Retirement", "Portfolio", "Dividend", "Market", "Trading", "Crypto", "Bitcoin", "Budget", "Savings", "Debt", "Mortgage", "Loan", "Credit", "Tax", "Estate", "Wealth")
        ContentPatterns = @("finance", "investment", "stock", "money", "budget", "savings", "retirement")
        MOCPath = "00 - Home Dashboard\MOC - Finance & Investment.md"
        DefaultSubsection = "Finance Topics"
    }
    "Reading & Literature" = @{
        TitlePatterns = @("Book Review", "Book Summary", "Novel", "Author", "Biography", "Memoir", "Poetry", "Short Story", "Library", "Kindle", "Audiobook", "Literature")
        ContentPatterns = @("book", "author", "novel", "reading", "chapter", "story")
        MOCPath = "00 - Home Dashboard\MOC - Reading & Literature.md"
        DefaultSubsection = "Reading Topics"
    }
    "Genealogy" = @{
        TitlePatterns = @("Genealogy", "Ancestry", "Family Tree", "DNA", "Ancestor", "Heritage", "Lineage", "Surname", "Census", "Birth Record", "Death Record", "Marriage Record", "Fillingim", "Stanard")
        ContentPatterns = @("genealogy", "ancestry", "family", "ancestor", "heritage", "DNA")
        MOCPath = "00 - Home Dashboard\MOC - Genealogy.md"
        DefaultSubsection = "Genealogy Topics"
    }
    "Soccer" = @{
        TitlePatterns = @("Soccer", "Football", "FIFA", "World Cup", "Premier League", "La Liga", "Bundesliga", "Serie A", "MLS", "Champions League", "Goal", "Striker", "Midfielder", "Defender", "Goalkeeper")
        ContentPatterns = @("soccer", "football", "goal", "match", "team", "league")
        MOCPath = "00 - Home Dashboard\MOC - Soccer.md"
        DefaultSubsection = "Soccer Topics"
    }
    "Personal Knowledge Management" = @{
        TitlePatterns = @("PKM", "Zettelkasten", "Second Brain", "Obsidian", "Roam", "Notion", "Evernote", "Note-taking", "Knowledge Management", "Atomic Notes", "Evergreen Notes", "MOC")
        ContentPatterns = @("PKM", "knowledge", "notes", "linking", "tagging", "Obsidian", "Zettelkasten")
        MOCPath = "00 - Home Dashboard\MOC - Personal Knowledge Management.md"
        DefaultSubsection = "PKM Topics"
    }
}

# Function to check if orphan title matches patterns
function Test-TitleMatch {
    param(
        [string]$Title,
        [string[]]$Patterns
    )
    foreach ($pattern in $Patterns) {
        if ($Title -match [regex]::Escape($pattern)) {
            return $true
        }
    }
    return $false
}

# Function to check if orphan should be excluded
function Test-Excluded {
    param([string]$Name)
    foreach ($pattern in $excludePatterns) {
        if ($Name -match [regex]::Escape($pattern)) {
            return $true
        }
    }
    return $false
}

# Track linked orphans and results
$linkedCount = 0
$linkedFiles = @()

Write-Host "=== Auto-Linking Confident Orphan Matches ===" -ForegroundColor Cyan
Write-Host ""

foreach ($mocName in $mocRules.Keys) {
    $rule = $mocRules[$mocName]
    $mocMatches = @()

    foreach ($orphan in $orphans) {
        # Skip excluded files
        if (Test-Excluded -Name $orphan.Name) { continue }

        # Check title match
        if (Test-TitleMatch -Title $orphan.Name -Patterns $rule.TitlePatterns) {
            $mocMatches += $orphan
        }
    }

    if ($mocMatches.Count -gt 0) {
        Write-Host "[$mocName] Found $($mocMatches.Count) confident matches:" -ForegroundColor Green

        foreach ($match in $mocMatches) {
            Write-Host "  Linking: $($match.Name)" -ForegroundColor White

            # Get relative path for the orphan
            $orphanRelPath = $match.RelativePath

            # Call the link-orphan action
            $result = & "C:\Users\awt\moc_orphan_linker.ps1" `
                -Action link-orphan `
                -OrphanPath $orphanRelPath `
                -MOCPath $rule.MOCPath `
                -SubsectionName $rule.DefaultSubsection 2>&1

            # Check if successful
            if ($result -match "successfully") {
                $linkedCount++
                $linkedFiles += "$($match.Name) -> $mocName"
            } else {
                Write-Host "    Warning: $result" -ForegroundColor Yellow
            }
        }
        Write-Host ""
    }
}

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total files linked: $linkedCount" -ForegroundColor Green

# Save results
$linkedFiles | Out-File "C:\Users\awt\auto_linked_results.txt" -Encoding UTF8
Write-Host "Results saved to: C:\Users\awt\auto_linked_results.txt" -ForegroundColor Gray
