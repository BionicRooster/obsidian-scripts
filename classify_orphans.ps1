# Classify and move orphan files to appropriate 01 subdirectories
# This script analyzes file content and moves files based on keywords and tags

param(
    [int]$BatchSize = 50,  # Number of files to process per batch
    [int]$BatchNumber = 1,  # Which batch to process (1-indexed)
    [switch]$DryRun,        # If set, only report classifications without moving
    [switch]$ListOnly       # If set, only list files without processing
)

# Define source and destination paths
$sourcePath = "D:\Obsidian\Main\20 - Permanent Notes"
$destBase = "D:\Obsidian\Main\01"

# Map category names to actual folder names (handles special characters)
$categoryFolderMap = @{
    "Bahá'í" = "Bahá'í"
    "Finance" = "Finance"
    "FOL" = "FOL"
    "Genealogy" = "Genealogy"
    "Health" = "Health"
    "Home" = "Home"
    "Music" = "Music"
    "NLP_Psy" = "NLP_Psy"
    "PKM" = "PKM"
    "Reading" = "Reading"
    "Recipes" = "Recipes"
    "Religion" = "Religion"
    "Science" = "Science"
    "Soccer" = "Soccer"
    "Social" = "Social"
    "Technology" = "Technology"
    "Travel" = "Travel"
}

# Define category keywords for classification
$categories = @{
    "Bahá'í" = @(
        "Bahá'í", "Baha'i", "bahai", "Bahá'u'lláh", "Bahaullah", "Abdul-Baha", "Abdu'l-Bahá",
        "Shoghi Effendi", "Universal House of Justice", "UHJ", "Bahá'í Faith",
        "Naw-Rúz", "Ridván", "Feast", "LSA", "NSA", "Nineteen Day Feast",
        "Kitáb-i-Aqdas", "Hidden Words", "Bahá'í prayers", "Bahá'í temple",
        "unity of mankind", "unity of humanity", "oneness of humanity",
        "oneness of God", "oneness of religion", "Bahá'í World Centre",
        "Haifa", "Mount Carmel", "Bahji", "Shrine of the Báb", "The Báb", "Bab",
        "Covenant", "Covenant-breaking", "Aghsan", "Afnan", "ascension", "Kitáb-i-'Ahd",
        "Manifestation of God", "Nine Year Plan", "Ruhi", "devotional"
    )
    "Finance" = @(
        "investing", "investment", "stocks", "bonds", "401k", "IRA", "retirement",
        "financial", "money", "budget", "budgeting", "savings", "credit",
        "mortgage", "loan", "debt", "interest rate", "compound interest",
        "portfolio", "dividend", "mutual fund", "ETF", "stock market",
        "banking", "credit card", "tax", "taxes", "income tax"
    )
    "FOL" = @(
        "Friends of the Georgetown Public Library", "FOL", "Georgetown Library",
        "library book sale", "library volunteer", "Georgetown Public Library"
    )
    "Genealogy" = @(
        "genealogy", "ancestry", "family history", "DNA test", "23andMe",
        "AncestryDNA", "family tree", "obituary", "birth record", "death record",
        "marriage record", "census", "genealogical", "ancestor", "descendant",
        "pedigree", "Talbot", "lineage", "heritage", "FamilySearch"
    )
    "Health" = @(
        "health", "nutrition", "diet", "exercise", "workout", "fitness",
        "medical", "medicine", "disease", "illness", "symptom", "treatment",
        "doctor", "hospital", "WFPB", "vegan", "vegetarian", "plant-based",
        "vitamin", "supplement", "wellness", "healthcare", "blood pressure",
        "cholesterol", "diabetes", "cancer", "heart disease", "obesity",
        "weight loss", "healthy eating", "nutrient", "calorie"
    )
    "Home" = @(
        "home improvement", "DIY", "household", "cleaning", "gardening",
        "garden", "plant care", "lawn", "repair", "maintenance", "renovation",
        "furniture", "decor", "kitchen", "bathroom", "bedroom", "living room",
        "storage", "organization", "declutter", "housekeeping", "laundry",
        "cooking tip", "life hack", "practical tip"
    )
    "Music" = @(
        "music", "song", "album", "artist", "band", "concert", "guitar",
        "piano", "drum", "violin", "instrument", "musician", "singer",
        "composer", "symphony", "orchestra", "jazz", "rock", "classical",
        "hip hop", "rap", "country", "folk", "blues", "reggae", "electronic",
        "playlist", "Spotify", "vinyl", "record player", "recorder", "flute"
    )
    "NLP_Psy" = @(
        "psychology", "NLP", "neuro-linguistic programming", "cognitive",
        "behavior", "mental health", "anxiety", "depression", "therapy",
        "counseling", "brain", "neuroscience", "learning", "memory",
        "perception", "emotion", "motivation", "personality", "intelligence",
        "mindfulness", "meditation", "stress", "trauma", "PTSD",
        "cognitive bias", "decision making", "thinking", "Kahneman",
        "behavioral economics", "habit", "subconscious", "hypnosis"
    )
    "PKM" = @(
        "personal knowledge management", "PKM", "note-taking", "Obsidian",
        "Evernote", "Notion", "Roam Research", "Zettelkasten", "second brain",
        "productivity", "workflow", "GTD", "Getting Things Done", "todo",
        "task management", "knowledge base", "wiki", "linking", "backlinks",
        "markdown", "digital garden", "atomic notes"
    )
    "Reading" = @(
        "book review", "book notes", "reading list", "literature", "novel",
        "fiction", "non-fiction", "author", "writing", "publishing", "ebook",
        "Kindle", "audiobook", "library", "bookshelf", "bookmark",
        "reading challenge", "book club", "bestseller"
    )
    "Recipes" = @(
        "recipe", "cooking", "baking", "ingredient", "tablespoon", "teaspoon",
        "cup", "ounce", "preheat", "oven", "stove", "skillet", "pan",
        "sauté", "simmer", "boil", "fry", "grill", "roast", "bake",
        "serve", "garnish", "seasoning", "spice", "herb", "flour",
        "sugar", "salt", "pepper", "oil", "butter", "egg", "milk"
    )
    "Religion" = @(
        "Christianity", "Christian", "Jesus", "Christ", "Bible", "Gospel",
        "Judaism", "Jewish", "Torah", "Islam", "Muslim", "Quran", "Muhammad",
        "Buddhism", "Buddhist", "Buddha", "Hinduism", "Hindu", "Vedas",
        "spirituality", "spiritual", "prayer", "worship", "church", "mosque",
        "synagogue", "temple", "faith", "God", "divine", "sacred", "holy",
        "religion", "religious", "Amish", "forgiveness"
    )
    "Science" = @(
        "science", "scientific", "research", "study", "experiment", "theory",
        "physics", "chemistry", "biology", "geology", "astronomy", "space",
        "planet", "star", "galaxy", "universe", "evolution", "genetics",
        "DNA", "cell", "organism", "ecosystem", "climate", "weather",
        "micrometeorite", "fossil", "mineral", "element", "atom", "molecule",
        "Mars", "NASA", "telescope", "nature", "ecology", "environment"
    )
    "Soccer" = @(
        "soccer", "football", "FIFA", "World Cup", "Premier League",
        "Champions League", "goal", "goalkeeper", "striker", "midfielder",
        "defender", "coach", "match", "stadium", "team", "league",
        "Manchester United", "Liverpool", "Barcelona", "Real Madrid"
    )
    "Social" = @(
        "politics", "political", "government", "election", "democracy",
        "republican", "democrat", "congress", "senate", "president",
        "social issue", "justice", "equality", "racism", "discrimination",
        "civil rights", "human rights", "poverty", "inequality", "activism",
        "protest", "society", "culture", "economics", "economy", "policy",
        "immigration", "climate change", "environment", "Bernie Sanders"
    )
    "Technology" = @(
        "computer", "programming", "software", "hardware", "code", "coding",
        "developer", "algorithm", "database", "server", "network", "internet",
        "web", "website", "app", "application", "AI", "artificial intelligence",
        "machine learning", "Python", "JavaScript", "Java", "C++", "Linux",
        "Windows", "Mac", "Apple", "Google", "Microsoft", "Amazon",
        "Raspberry Pi", "Arduino", "3D printer", "gadget", "electronic",
        "vintage computing", "PiDP", "maker", "hacker", "cybersecurity",
        "malware", "VBA", "Excel", "Access", "PowerShell", "batch file"
    )
    "Travel" = @(
        "travel", "vacation", "trip", "destination", "hotel", "flight",
        "airport", "cruise", "RV", "camping", "hiking", "backpacking",
        "tourism", "tourist", "sightseeing", "adventure", "explore",
        "narrowboat", "canal", "road trip", "itinerary", "passport"
    )
}

# Function to classify a file based on content
function Get-FileCategory {
    param(
        [string]$FilePath,
        [string]$FileName
    )

    try {
        # Read file content with UTF-8 encoding
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction Stop

        # Combine filename and content for analysis
        $textToAnalyze = "$FileName`n$content"

        # Score each category
        $scores = @{}
        foreach ($category in $categories.Keys) {
            $score = 0
            foreach ($keyword in $categories[$category]) {
                # Case-insensitive matching
                if ($textToAnalyze -match [regex]::Escape($keyword)) {
                    # Weight title matches higher
                    if ($FileName -match [regex]::Escape($keyword)) {
                        $score += 3
                    } else {
                        $score += 1
                    }
                }
            }
            $scores[$category] = $score
        }

        # Find category with highest score
        $maxScore = 0
        $bestCategory = $null
        foreach ($category in $scores.Keys) {
            if ($scores[$category] -gt $maxScore) {
                $maxScore = $scores[$category]
                $bestCategory = $category
            }
        }

        # Return best category if score is above threshold
        if ($maxScore -ge 2) {
            return @{
                Category = $bestCategory
                Score = $maxScore
            }
        } else {
            return @{
                Category = "Unknown"
                Score = 0
            }
        }
    }
    catch {
        return @{
            Category = "Error"
            Score = 0
            Error = $_.Exception.Message
        }
    }
}

# Get all markdown files in source
$allFiles = Get-ChildItem -Path $sourcePath -Filter "*.md" | Sort-Object Name

# Skip certain files
$skipFiles = @("20 - Permanent Notes.md")
$allFiles = $allFiles | Where-Object { $_.Name -notin $skipFiles }

Write-Host "Total files to process: $($allFiles.Count)" -ForegroundColor Cyan

if ($ListOnly) {
    $allFiles | ForEach-Object { Write-Host $_.Name }
    exit
}

# Calculate batch range
$startIndex = ($BatchNumber - 1) * $BatchSize
$endIndex = [Math]::Min($startIndex + $BatchSize - 1, $allFiles.Count - 1)

if ($startIndex -ge $allFiles.Count) {
    Write-Host "Batch $BatchNumber is out of range. Total batches: $([Math]::Ceiling($allFiles.Count / $BatchSize))" -ForegroundColor Red
    exit
}

$batchFiles = $allFiles[$startIndex..$endIndex]

Write-Host "`nProcessing batch $BatchNumber (files $($startIndex + 1) to $($endIndex + 1))..." -ForegroundColor Yellow

# Track results
$results = @()
$categoryCounts = @{}

foreach ($file in $batchFiles) {
    $classification = Get-FileCategory -FilePath $file.FullName -FileName $file.BaseName

    $result = [PSCustomObject]@{
        FileName = $file.Name
        Category = $classification.Category
        Score = $classification.Score
        Status = ""
    }

    if ($classification.Category -ne "Unknown" -and $classification.Category -ne "Error") {
        # Use the folder mapping for the category
        $folderName = $categoryFolderMap[$classification.Category]
        if (-not $folderName) {
            $folderName = $classification.Category
        }
        $destFolder = Join-Path $destBase $folderName

        if (-not (Test-Path $destFolder)) {
            Write-Host "Warning: Destination folder does not exist: $destFolder" -ForegroundColor Red
            $result.Status = "Folder missing"
        }
        else {
            $destPath = Join-Path $destFolder $file.Name

            if (Test-Path $destPath) {
                $result.Status = "Duplicate exists"
            }
            elseif ($DryRun) {
                $result.Status = "Would move"
            }
            else {
                try {
                    Move-Item -Path $file.FullName -Destination $destPath -ErrorAction Stop
                    $result.Status = "Moved"

                    # Update category counts
                    if (-not $categoryCounts.ContainsKey($classification.Category)) {
                        $categoryCounts[$classification.Category] = 0
                    }
                    $categoryCounts[$classification.Category]++
                }
                catch {
                    $result.Status = "Error: $($_.Exception.Message)"
                }
            }
        }
    }
    else {
        $result.Status = "Unclassified"
    }

    $results += $result
}

# Display results
Write-Host "`n=== Classification Results ===" -ForegroundColor Green
$results | Format-Table -Property FileName, Category, Score, Status -AutoSize

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Total processed: $($results.Count)"
Write-Host "Moved: $(($results | Where-Object { $_.Status -eq 'Moved' }).Count)"
Write-Host "Unclassified: $(($results | Where-Object { $_.Status -eq 'Unclassified' }).Count)"
Write-Host "Duplicates: $(($results | Where-Object { $_.Status -eq 'Duplicate exists' }).Count)"
Write-Host "Errors: $(($results | Where-Object { $_.Status -like 'Error*' }).Count)"

if ($categoryCounts.Count -gt 0) {
    Write-Host "`n=== Files moved by category ===" -ForegroundColor Green
    $categoryCounts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        Write-Host "$($_.Key): $($_.Value)"
    }
}

# Return results for further processing
return $results
