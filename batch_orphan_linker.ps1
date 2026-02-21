# Batch Orphan Linker - Searches orphans for each MOC's keywords
# and outputs candidates grouped by MOC for user approval

param(
    # MOC to process (optional - if not specified, processes all)
    [string]$MOCName = '',
    # Action: scan (find candidates), link (link approved)
    [string]$Action = 'scan'
)

# Vault path
$vaultPath = 'D:\Obsidian\Main'

# Load orphan list
$orphansJson = Get-Content "C:\Users\awt\orphan_list.json" -Encoding UTF8 -Raw
$orphans = $orphansJson | ConvertFrom-Json

# Define MOC keywords - topics that should be linked to each MOC
$mocKeywords = @{
    "Bahá'í Faith" = @{
        Keywords = @("Bahá'í", "Baha'i", "Bahá'u'lláh", "Bahaullah", "Abdu'l-Bahá", "Abdul-Baha", "Shoghi Effendi", "Universal House of Justice", "UHJ", "Nine Year Plan", "Ridván", "Ridvan", "LSA", "Local Spiritual Assembly", "Naw-Ruz", "Ayyam-i-Ha", "The Báb", "Bab", "pilgrimage", "Wilmette", "Haifa")
        Subsections = @{
            "Central Figures" = @("Bahá'u'lláh", "Bahaullah", "Abdu'l-Bahá", "Abdul-Baha", "The Báb", "Bab")
            "Core Teachings" = @("unity", "oneness", "progressive revelation", "spiritual", "soul", "prayer", "meditation")
            "Ridván Messages" = @("Ridván", "Ridvan")
            "Nine Year Plan" = @("Nine Year Plan", "cluster", "institute")
            "Community & Service" = @("devotional", "children's class", "junior youth", "study circle", "service")
        }
        MOCPath = "00 - Home Dashboard\MOC - Bahá'í Faith.md"
    }
    "Finance & Investment" = @{
        Keywords = @("finance", "investment", "stock", "bond", "401k", "IRA", "retirement", "portfolio", "dividend", "market", "trading", "crypto", "bitcoin", "budget", "savings", "debt", "mortgage", "loan", "credit", "tax", "estate", "wealth")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Finance & Investment.md"
    }
    "Genealogy" = @{
        Keywords = @("genealogy", "ancestry", "family tree", "DNA", "ancestor", "heritage", "lineage", "surname", "census", "birth record", "death record", "marriage record")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Genealogy.md"
    }
    "Health & Nutrition" = @{
        Keywords = @("health", "nutrition", "diet", "exercise", "fitness", "vitamin", "supplement", "protein", "carb", "fat", "calorie", "weight", "cholesterol", "blood pressure", "diabetes", "heart", "sleep", "stress", "mental health", "anxiety", "depression", "meditation", "yoga", "doctor", "medical", "cancer", "disease", "symptom", "treatment", "medicine", "pharmaceutical", "hospital", "surgery", "vaccine", "immune")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Health & Nutrition.md"
    }
    "Home & Practical Life" = @{
        Keywords = @("home", "house", "garden", "lawn", "plumbing", "electrical", "HVAC", "repair", "maintenance", "cleaning", "organizing", "declutter", "furniture", "appliance", "kitchen", "bathroom", "bedroom", "garage", "basement", "attic", "roof", "window", "door", "paint", "flooring", "carpet", "tile", "DIY", "tool", "HOA")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Home & Practical Life.md"
    }
    "Music & Record" = @{
        Keywords = @("music", "song", "album", "artist", "band", "concert", "vinyl", "record", "LP", "CD", "streaming", "Spotify", "playlist", "genre", "jazz", "rock", "classical", "hip hop", "pop", "country", "blues", "folk", "instrument", "guitar", "piano", "drum", "singing", "choir", "chorus", "orchestra", "symphony")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Music & Record.md"
    }
    "NLP & Psychology" = @{
        Keywords = @("NLP", "neuro-linguistic", "psychology", "therapy", "counseling", "cognitive", "behavior", "emotion", "mindset", "habit", "motivation", "confidence", "self-esteem", "trauma", "PTSD", "anchoring", "reframe", "rapport", "submodality", "timeline", "hypnosis", "unconscious", "conscious", "belief", "value", "meta-model", "Milton model", "presupposition")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - NLP & Psychology.md"
    }
    "Personal Knowledge Management" = @{
        Keywords = @("PKM", "knowledge management", "note-taking", "Zettelkasten", "second brain", "Obsidian", "Roam", "Notion", "Evernote", "productivity", "workflow", "atomic notes", "linking", "tagging", "MOC", "evergreen", "fleeting note", "literature note", "permanent note")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Personal Knowledge Management.md"
    }
    "Reading & Literature" = @{
        Keywords = @("book", "reading", "literature", "novel", "author", "fiction", "non-fiction", "biography", "memoir", "poetry", "short story", "chapter", "library", "kindle", "audiobook", "book review", "book summary")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Reading & Literature.md"
    }
    "Recipes" = @{
        Keywords = @("recipe", "cooking", "baking", "ingredient", "meal", "dinner", "lunch", "breakfast", "snack", "dessert", "appetizer", "soup", "salad", "sauce", "marinade", "seasoning", "spice", "herb", "vegetarian", "vegan", "gluten-free", "instant pot", "slow cooker", "oven", "grill", "stir-fry")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Recipes.md"
    }
    "Science & Nature" = @{
        Keywords = @("science", "nature", "biology", "chemistry", "physics", "astronomy", "geology", "ecology", "environment", "climate", "evolution", "genetics", "DNA", "cell", "organism", "species", "ecosystem", "conservation", "wildlife", "plant", "animal", "ocean", "forest", "mountain", "weather", "space", "planet", "star", "universe")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Science & Nature.md"
    }
    "Soccer" = @{
        Keywords = @("soccer", "football", "FIFA", "World Cup", "Premier League", "La Liga", "Bundesliga", "Serie A", "MLS", "Champions League", "goal", "striker", "midfielder", "defender", "goalkeeper", "match", "tournament", "club", "team")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Soccer.md"
    }
    "Social Issues" = @{
        Keywords = @("social", "justice", "equality", "racism", "discrimination", "civil rights", "human rights", "poverty", "homelessness", "immigration", "refugee", "gender", "LGBTQ", "feminism", "activism", "protest", "policy", "politics", "democracy", "voting", "election", "government", "community", "nonprofit", "volunteer", "charity", "unity", "prejudice", "bias")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Social Issues.md"
    }
    "Technology & Computers" = @{
        Keywords = @("technology", "computer", "software", "hardware", "programming", "code", "developer", "app", "web", "internet", "network", "cloud", "AI", "artificial intelligence", "machine learning", "data", "database", "algorithm", "API", "server", "security", "cybersecurity", "Linux", "Windows", "Mac", "iPhone", "Android", "gadget", "automation")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Technology & Computers.md"
    }
    "Travel & Exploration" = @{
        Keywords = @("travel", "trip", "vacation", "holiday", "destination", "flight", "airline", "airport", "hotel", "resort", "Airbnb", "cruise", "road trip", "backpacking", "hiking", "camping", "tourism", "tourist", "sightseeing", "passport", "visa", "luggage", "itinerary")
        Subsections = @{}
        MOCPath = "00 - Home Dashboard\MOC - Travel & Exploration.md"
    }
}

# Function to search an orphan for keywords
function Test-OrphanForKeywords {
    param(
        [object]$Orphan,
        [string[]]$Keywords
    )

    $fullPath = $Orphan.FullPath
    if (-not (Test-Path $fullPath)) { return $false }

    $content = Get-Content $fullPath -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $false }

    # Also check filename
    $fileName = $Orphan.Name

    foreach ($keyword in $Keywords) {
        if ($content -match [regex]::Escape($keyword) -or $fileName -match [regex]::Escape($keyword)) {
            return $true
        }
    }
    return $false
}

# Process MOCs
$mocsToProcess = if ($MOCName) { @($MOCName) } else { $mocKeywords.Keys }

$results = @{}

foreach ($moc in $mocsToProcess) {
    if (-not $mocKeywords.ContainsKey($moc)) {
        Write-Host "Unknown MOC: $moc" -ForegroundColor Red
        continue
    }

    Write-Host "`n=== Scanning for $moc ===" -ForegroundColor Cyan
    $keywords = $mocKeywords[$moc].Keywords
    $matches = @()

    foreach ($orphan in $orphans) {
        if (Test-OrphanForKeywords -Orphan $orphan -Keywords $keywords) {
            $matches += [PSCustomObject]@{
                Name = $orphan.Name
                FullPath = $orphan.FullPath
                RelativePath = $orphan.RelativePath
                Folder = $orphan.Folder
            }
        }
    }

    Write-Host "Found $($matches.Count) candidates" -ForegroundColor Green

    if ($matches.Count -gt 0) {
        $results[$moc] = @{
            MOCPath = $mocKeywords[$moc].MOCPath
            Candidates = $matches
        }

        # List first 20
        $i = 1
        foreach ($match in ($matches | Select-Object -First 20)) {
            Write-Host "  $i. $($match.Name)" -ForegroundColor White
            $i++
        }
        if ($matches.Count -gt 20) {
            Write-Host "  ... and $($matches.Count - 20) more" -ForegroundColor Gray
        }
    }
}

# Save results
$results | ConvertTo-Json -Depth 5 | Out-File "C:\Users\awt\orphan_candidates.json" -Encoding UTF8
Write-Host "`nResults saved to: C:\Users\awt\orphan_candidates.json" -ForegroundColor Gray
