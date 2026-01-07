# fix_moc_links.ps1
# Finds plain text bullet points in MOC files and converts them to links
# if a matching note exists in the vault.
# Filters out items that appear misplaced based on MOC topic.

param(
    # Path to the Obsidian vault
    [string]$VaultPath = "D:\Obsidian\Main",

    # Actually apply fixes (otherwise dry run)
    [switch]$Fix,

    # Limit number of files to process (0 = no limit)
    [int]$Limit = 0
)

Write-Host "=== MOC Link Fixer ===" -ForegroundColor Cyan
Write-Host "Vault: $VaultPath"
Write-Host ""

# Items that appear in multiple unrelated MOCs - likely misplaced
# These will be skipped unless in a relevant MOC
$misplacedItems = @{
    "impaired lung function and health status" = @("Health", "Science")
    "america's four stories" = @("Social", "Reading", "NLP")
    "predicting lung health trajectories for survivors of preterm birth" = @("Health", "Science")
    "the women of rohan" = @("Reading", "Literature")
    "using virtual desktops" = @("Technology", "Computing")
    "kahneman-thinking fast and slow" = @("NLP", "Psychology", "Reading")
    "thinking, fast and slow" = @("NLP", "Psychology", "Reading")
}

# MOC topic keywords for filtering
$mocTopics = @{
    "Recipes" = @("recipe", "food", "cook", "soup", "salad", "bread", "dessert", "sauce", "beverage", "meal", "dish")
    "Bahá'í Faith" = @("baha", "faith", "spiritual", "religion", "unity", "prayer", "tablet", "ridvan", "lsa", "nsa", "peace", "justice", "race")
    "Finance" = @("finance", "invest", "money", "tax", "budget", "bank", "stock", "retire")
    "Health" = @("health", "nutrition", "diet", "exercise", "medical", "lung", "disease", "wellness")
    "Technology" = @("tech", "computer", "software", "hardware", "linux", "windows", "program", "code", "web", "app")
    "NLP" = @("nlp", "psychology", "mind", "think", "cognitive", "behavior", "mental", "brain", "pattern")
    "Science" = @("science", "nature", "geology", "biology", "physics", "space", "animal", "plant", "earth", "climate")
    "Soccer" = @("soccer", "football", "goal", "team", "player", "match", "world cup", "league")
    "Travel" = @("travel", "trip", "destination", "park", "explore", "adventure", "road", "camp")
    "Reading" = @("book", "read", "literature", "author", "novel", "story", "writing")
    "Home" = @("home", "house", "garden", "repair", "diy", "build", "farm", "rv", "earthbag")
    "Music" = @("music", "song", "album", "artist", "guitar", "record", "band", "instrument")
    "Social" = @("social", "race", "justice", "equality", "politics", "community", "unity", "prejudice")
    "PKM" = @("obsidian", "note", "knowledge", "zettelkasten", "template", "vault", "pkm")
}

# Function to check if an item is relevant to a MOC
function Test-ItemRelevance {
    param(
        [string]$ItemText,
        [string]$MocName
    )

    $itemLower = $ItemText.ToLower()

    # Check if this is a known misplaced item
    if ($misplacedItems.ContainsKey($itemLower)) {
        $allowedMocs = $misplacedItems[$itemLower]
        $isAllowed = $false
        foreach ($allowed in $allowedMocs) {
            if ($MocName -like "*$allowed*") {
                $isAllowed = $true
                break
            }
        }
        if (-not $isAllowed) {
            return $false
        }
    }

    # Always allow MOC cross-references
    if ($itemLower -like "moc -*") {
        return $true
    }

    # Check topic relevance for items that might be misplaced
    # Find which MOC topic applies
    $mocKey = $null
    foreach ($key in $mocTopics.Keys) {
        if ($MocName -like "*$key*") {
            $mocKey = $key
            break
        }
    }

    # If we found a topic match, be more selective for generic items
    if ($mocKey) {
        $topics = $mocTopics[$mocKey]

        # Check if the item contains any topic keywords
        $hasTopicMatch = $false
        foreach ($topic in $topics) {
            if ($itemLower -like "*$topic*") {
                $hasTopicMatch = $true
                break
            }
        }

        # For very generic items, require topic match
        # For specific items (longer names), allow them
        if ($ItemText.Length -lt 30 -and -not $hasTopicMatch) {
            # Check if it's obviously misplaced
            $obviouslyWrong = $false
            foreach ($otherKey in $mocTopics.Keys) {
                if ($otherKey -eq $mocKey) { continue }
                $otherTopics = $mocTopics[$otherKey]
                foreach ($topic in $otherTopics) {
                    if ($itemLower -like "*$topic*" -and $topic.Length -gt 4) {
                        $obviouslyWrong = $true
                        break
                    }
                }
                if ($obviouslyWrong) { break }
            }

            if ($obviouslyWrong) {
                return $false
            }
        }
    }

    return $true
}

# Build index of all markdown files by their base name (without .md)
Write-Host "Building note index..." -ForegroundColor Gray
$noteIndex = @{}  # lowercase base name -> full file path
$noteNames = @{}  # lowercase base name -> actual base name (for proper casing)
$noteList = @()   # list of all note base names for fuzzy matching

$allMdFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike "*\.obsidian*" }

foreach ($file in $allMdFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $key = $baseName.ToLower()

    # Store first occurrence (or prefer 20 - Permanent Notes)
    if (-not $noteIndex.ContainsKey($key) -or $file.FullName -like "*20 - Permanent Notes*") {
        $noteIndex[$key] = $file.FullName
        $noteNames[$key] = $baseName
    }

    # Add to list for fuzzy matching
    $noteList += @{
        BaseName = $baseName
        Key = $key
        FullPath = $file.FullName
        IsPermanent = $file.FullName -like "*20 - Permanent Notes*"
    }
}

Write-Host "Indexed $($noteIndex.Count) notes" -ForegroundColor Gray

# Function to find fuzzy match for a text
function Find-FuzzyMatch {
    param([string]$SearchText)

    $searchLower = $SearchText.ToLower().Trim()

    # Remove common suffixes/parentheticals for matching
    $searchClean = $searchLower -replace '\s*\([^)]+\)\s*$', ''  # Remove (Tiny Living) etc.
    $searchClean = $searchClean -replace '\?$', ''  # Remove trailing ?
    $searchClean = $searchClean.Trim()

    $bestMatch = $null
    $bestScore = 0

    foreach ($note in $noteList) {
        $noteLower = $note.Key
        $noteClean = $noteLower.Trim()

        # Skip very short names to avoid false matches
        if ($noteClean.Length -lt 5) { continue }

        $score = 0

        # Strategy 1: Search text starts with note name (truncated note names)
        # e.g., "Is Cordwood Masonry Right for You?" starts with "Is Cordwood Masonry"
        if ($searchClean -like "$noteClean*") {
            $score = 80 + ($noteClean.Length / $searchClean.Length * 20)
        }
        # Strategy 2: Note name starts with search text (search is truncated)
        elseif ($noteClean -like "$searchClean*") {
            $score = 70 + ($searchClean.Length / $noteClean.Length * 20)
        }
        # Strategy 3: Note name contains the search text
        elseif ($noteClean -like "*$searchClean*") {
            $score = 60 + ($searchClean.Length / $noteClean.Length * 20)
        }
        # Strategy 4: Search text contains note name
        elseif ($searchClean -like "*$noteClean*") {
            $score = 50 + ($noteClean.Length / $searchClean.Length * 20)
        }
        # Strategy 5: Significant word overlap
        else {
            $searchWords = $searchClean -split '\s+' | Where-Object { $_.Length -gt 3 }
            $noteWords = $noteClean -split '\s+' | Where-Object { $_.Length -gt 3 }

            if ($searchWords.Count -gt 0 -and $noteWords.Count -gt 0) {
                $matchingWords = 0
                foreach ($sw in $searchWords) {
                    foreach ($nw in $noteWords) {
                        if ($sw -eq $nw -or $sw -like "$nw*" -or $nw -like "$sw*") {
                            $matchingWords++
                            break
                        }
                    }
                }

                # Need at least 2 matching significant words, or 1 if it's a key word
                $minWords = [Math]::Max(1, [Math]::Min($searchWords.Count, $noteWords.Count) - 1)
                if ($matchingWords -ge $minWords -and $matchingWords -ge 2) {
                    $score = 40 + ($matchingWords / [Math]::Max($searchWords.Count, $noteWords.Count) * 30)
                }
            }
        }

        # Boost score for 20 - Permanent Notes
        if ($note.IsPermanent -and $score -gt 0) {
            $score += 5
        }

        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestMatch = $note
        }
    }

    # Only return if score is good enough (above 50)
    # Also require that the match isn't much shorter than the search (avoid "Vegan Pie" -> "Vegan")
    if ($bestScore -ge 50 -and $bestMatch) {
        $matchLen = $bestMatch.BaseName.Length
        $searchLen = $SearchText.Length

        # Reject if match is less than 40% of search length (too short)
        if ($matchLen -lt ($searchLen * 0.4)) {
            return $null
        }

        return @{
            BaseName = $bestMatch.BaseName
            Score = $bestScore
        }
    }

    return $null
}

# Find MOC files
$mocFiles = Get-ChildItem -Path $VaultPath -Filter "MOC*.md" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike "*\.obsidian*" }

Write-Host "Found $($mocFiles.Count) MOC files" -ForegroundColor Gray
Write-Host ""

$totalMatches = 0
$totalSkipped = 0
$totalFixed = 0
$filesModified = 0

foreach ($mocFile in $mocFiles) {
    $mocName = $mocFile.Name
    Write-Host "Processing: $mocName" -ForegroundColor Yellow

    try {
        $content = Get-Content -Path $mocFile.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        if (-not $content) { continue }
    } catch {
        Write-Host "  ERROR: Could not read file" -ForegroundColor Red
        continue
    }

    $originalContent = $content
    $fileFixCount = 0
    $fileSkipCount = 0

    # Process line by line
    $lines = $content -split "`n"
    $newLines = @()

    foreach ($line in $lines) {
        $newLine = $line

        # Check if this is a bullet point line
        if ($line -match '^(\s*-\s*)(.+)$') {
            $prefix = $Matches[1]
            $text = $Matches[2].Trim()

            # Skip if already contains a link
            if ($text -match '\[\[') {
                $newLines += $line
                continue
            }

            # Skip empty or very short text
            if ($text.Length -lt 3) {
                $newLines += $line
                continue
            }

            # Skip markdown separators and tag lines
            if ($text -match '^-+$' -or $text -match '^\*\*Tags:\*\*') {
                $newLines += $line
                continue
            }

            # Try to find a matching note
            $textLower = $text.ToLower()

            $matchFound = $false
            $actualName = $null
            $isFuzzy = $false

            # Direct match
            if ($noteIndex.ContainsKey($textLower)) {
                $matchFound = $true
                $actualName = $noteNames[$textLower]
            }
            # Try removing trailing parenthetical like "(LSA)" or "(Full)"
            elseif ($text -match '^(.+?)\s*\([^)]+\)$') {
                $baseText = $Matches[1].Trim()
                $baseTextLower = $baseText.ToLower()
                if ($noteIndex.ContainsKey($baseTextLower)) {
                    $matchFound = $true
                    $actualName = $noteNames[$baseTextLower]
                }
            }

            # Fuzzy match if no exact match found
            if (-not $matchFound) {
                $fuzzyResult = Find-FuzzyMatch -SearchText $text
                if ($fuzzyResult) {
                    $matchFound = $true
                    $actualName = $fuzzyResult.BaseName
                    $isFuzzy = $true
                }
            }

            if ($matchFound) {
                # Check if this item is relevant to this MOC
                if (Test-ItemRelevance -ItemText $text -MocName $mocName) {
                    if ($text -match '\([^)]+\)$') {
                        $newLine = "$prefix[[$actualName|$text]]"
                    } else {
                        $newLine = "$prefix[[$actualName]]"
                    }
                    $matchType = if ($isFuzzy) { "Fuzzy" } else { "Link" }
                    $color = if ($isFuzzy) { "Cyan" } else { "Green" }
                    Write-Host "  ${matchType}: '$text' -> [[$actualName]]" -ForegroundColor $color
                    $fileFixCount++
                    $totalMatches++
                } else {
                    Write-Host "  Skip: '$text' (not relevant to $mocName)" -ForegroundColor DarkYellow
                    $fileSkipCount++
                    $totalSkipped++
                }
            }
        }

        $newLines += $newLine
    }

    $newContent = $newLines -join "`n"

    if ($fileFixCount -gt 0 -and $newContent -ne $originalContent) {
        if ($Fix) {
            Set-Content -Path $mocFile.FullName -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "  Updated: $fileFixCount links (skipped $fileSkipCount)" -ForegroundColor Green
            $filesModified++
        } else {
            Write-Host "  Would update: $fileFixCount links (skip $fileSkipCount)" -ForegroundColor Yellow
        }
        $totalFixed += $fileFixCount
    } else {
        Write-Host "  No relevant matches found (skipped $fileSkipCount)" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total links to add: $totalMatches"
Write-Host "Total skipped (misplaced): $totalSkipped"
Write-Host "Files to modify: $(if($Fix) { $filesModified } else { 'pending' })"

if (-not $Fix -and $totalFixed -gt 0) {
    Write-Host ""
    Write-Host "Run with -Fix to apply changes" -ForegroundColor Yellow
}
