# Move recent orphan files from 20 - Permanent Notes to 01/[category] folders
# Uses UTF-8 encoding to preserve content integrity

param(
    [int]$Limit = 0,           # 0 = process all files
    [switch]$DryRun = $false   # If true, only show what would be moved
)

$vaultPath = "D:\Obsidian\Main"
$orphanPath = "$vaultPath\20 - Permanent Notes"
$destBase = "$vaultPath\01"
$cutoffDate = (Get-Date).AddDays(-60)

# Category definitions with keywords (case-insensitive matching)
$categories = @{}

# Bahai category - use folder detection to handle encoding
$bahaiFolderName = (Get-ChildItem -Path "$vaultPath\01" -Directory | Where-Object { $_.Name -match "^Bah" }).Name
if (-not $bahaiFolderName) { $bahaiFolderName = "Bahá'í" }
$categories["Bahai"] = @{
    folder = $bahaiFolderName
    keywords = @("Bahai", "Baha'i", "Baha'u'llah", "Bahaullah", "Abdu'l-Baha", "Abdul-Baha", "UHJ", "Universal House of Justice", "NSA ", "LSA ", "Spiritual Assembly", "Ayyam-i-Ha", "Naw-Ruz", "Ridvan", "Nine Year Plan", "Bahau'llah", "BAHAI", "Feast of", "Tablet of Ahmad", "Baha'i Faith", "Banu", "Hollow Reed", "Georgetown LSA", "Ministerial Alliance", "GCCMA", "Georgetown Fellowship")
}

# Finance category
$categories["Finance"] = @{
    folder = "Finance"
    keywords = @("invest", "stock", "bond", "budget", "money", "finance", "savings", "Warren Buffett", "retirement", "401k", "IRA ", "tax", "USAA", "insurance claim", "loan", "savings bond", "TurboTax", "credit")
}

# FOL category
$categories["FOL"] = @{
    folder = "FOL"
    keywords = @("FOL", "Friends of the Georgetown Public Library", "library board", "book sale", "WCWBF")
}

# Genealogy category
$categories["Genealogy"] = @{
    folder = "Genealogy"
    keywords = @("genealogy", "ancestry", "family tree", "DNA", "centimorgan", "Talbot", "obituary", "funeral", "heritage", "heredity", "family history", "descendants", "geneology", "PersonalWeb", "Delores Joiner", "Edna Mae", "Chester Hale", "David Irvin", "Clayton Talbot", "Bailey Talbot", "Alfred W. Talbot", "Vera Irene", "Malinda Lloyd")
}

# Health category
$categories["Health"] = @{
    folder = "Health"
    keywords = @("health", "nutrition", "vitamin", "diet", "medical", "wellness", "exercise", "prostate", "BPH", "cataract", "surgery", "diabetes", "Alzheimer", "cancer", "walking", "nails", "hearing aids", "neck surgery", "supplement", "McDougall", "pandemics", "breast cancer", "ACDF")
}

# Home category
$categories["Home"] = @{
    folder = "Home"
    keywords = @("DIY", "home improvement", "household", "practical tips", "weed killer", "mail sorting", "organize", "cleaning", "mattress", "Water heater", "fire piston", "insulation", "fireplace", "rocket stove", "earthbag", "cordwood", "SIPs", "air plant", "potatoes grow", "home server", "safe", "fold", "FiberFirst", "HomeAgain", "Groasis")
}

# Music category
$categories["Music"] = @{
    folder = "Music"
    keywords = @("music", "song", "guitar", "ukulele", "instrument", "contrabass", "recorder", "flute", "Laurel Canyon", "vinyl records", "violins", "hymn")
}

# NLP_Psy category
$categories["NLP_Psy"] = @{
    folder = "NLP_Psy"
    keywords = @("psychology", "NLP", "cognitive", "mental", "brain", "dyslexia", "learning", "memory", "thinking", "Kahneman", "attention", "inattentional blindness", "stupidity", "apology", "autistic", "meditation", "naps", "puzzles", "Vipassana", "cult", "Rebecca Saxe", "learning process")
}

# PKM category
$categories["PKM"] = @{
    folder = "PKM"
    keywords = @("obsidian", "note-taking", "productivity", "knowledge management", "PKM", "Nozbe", "Evernote", "Trello", "Scrivener", "Anki", "Kaizen", "Getting Things Done", "CLAUDE.md", "Gemini CLI", "Obsidian maintenance", "Mastering Git")
}

# Reading category
$categories["Reading"] = @{
    folder = "Reading"
    keywords = @("book", "reading", "kindle", "e-book", "epub", "calibre", "DRM", "Dresden Files", "literature", "Shakespeare", "Women of Rohan")
}

# Religion category
$categories["Religion"] = @{
    folder = "Religion"
    keywords = @("Christianity", "Christian", "Buddhism", "Buddhist", "Hindu", "Islam", "Muslim", "Judaism", "Jewish", "Bible", "Jerusalem", "Pagan", "spiritual", "faith", "19th Century Religious", "church", "chapel", "indigenous religion", "Sapolsky", "Global Religion", "Religious Mission", "My Neighbor's Faith")
}

# Science category
$categories["Science"] = @{
    folder = "Science"
    keywords = @("science", "micrometeorite", "astronomy", "physics", "geology", "nature", "octopi", "potatoes NASA", "archaeology", "indigenous", "ecology", "climate", "environment", "fossil", "ancient", "carbon", "Chernobyl", "virus", "fractals", "planets", "meteorite", "sweet potatoes archaeology", "Hiroshima tree", "moss terrarium", "rock", "Neanderthal", "bonsai", "Baker Creek", "turtle plant", "pecan")
}

# Soccer category
$categories["Soccer"] = @{
    folder = "Soccer"
    keywords = @("soccer", "football", "World Cup", "USMNT", "Soccer Positions")
}

# Social category
$categories["Social"] = @{
    folder = "Social"
    keywords = @("race", "racism", "social", "politics", "justice", "society", "inequality", "Gini", "activist", "prejudice", "patronizing", "Moore", "fascism", "identity theft", "cybercrime", "Power of Proximity", "Destroy Racism", "White Patronizing", "Crossing the Line", "Charlie Chaplin", "Internet service", "environmental activist")
}

# Technology category
$categories["Technology"] = @{
    folder = "Technology"
    keywords = @("technology", "computer", "programming", "AI ", "Arduino", "Raspberry Pi", "Linux", "server", "code", "software", "hardware", "python", "PowerShell", "Access", "Excel", "VBA", "SQL", "Nagios", "Docker", "PCB", "DHCP", "git", "VS Code", "Claude", "LaMDA", "augmented reality", "RC2014", "plotter", "gadget", "URL", "e-mail", "backup", "browser", "FTP", "VPN", "smartphone", "TiVo", "Google Voice", "Stardock", "XSplit", "eMClient", "glasswire", "TRMNL", "Salesforce", "Multiplicity", "Perl", "Ubuntu", "grub", "dpkg", "Visual Studio", "Microsoft Office", "Writage", "Air Live Drive", "AlomWare")
}

# Travel category
$categories["Travel"] = @{
    folder = "Travel"
    keywords = @("travel", "RV", "camping", "cruise", "destination", "trip", "itinerary", "tipi", "Big Bend", "Fort Worth", "Antarctica", "Amelia Earhart", "Rome", "Medieval Europe", "Ireland")
}

# Function to determine category based on file content and tags
function Get-FileCategory {
    param([string]$FilePath)

    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction Stop
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $searchText = "$fileName`n$content"

        $matchedCategory = $null
        $highestScore = 0

        foreach ($catName in $categories.Keys) {
            $cat = $categories[$catName]
            $score = 0

            foreach ($keyword in $cat.keywords) {
                if ($searchText -match [regex]::Escape($keyword)) {
                    $score++
                    # Bonus points for longer, more specific keywords
                    if ($keyword.Length -gt 8) { $score++ }
                }
            }

            if ($score -gt $highestScore) {
                $highestScore = $score
                $matchedCategory = $catName
            }
        }

        return @{
            Category = $matchedCategory
            Score = $highestScore
        }
    }
    catch {
        return @{
            Category = $null
            Score = 0
        }
    }
}

# Get all recent orphan files
$allFiles = Get-ChildItem -Path $orphanPath -Filter "*.md" -ErrorAction SilentlyContinue |
    Where-Object {
        $_.CreationTime -gt $cutoffDate -and
        $_.Name -ne "20 - Permanent Notes.md"
    }

Write-Host "Found $($allFiles.Count) recent orphan files" -ForegroundColor Cyan

if ($Limit -gt 0) {
    $allFiles = $allFiles | Select-Object -First $Limit
    Write-Host "Processing first $Limit files" -ForegroundColor Yellow
}

# Process each file
$results = @()
$processed = 0
$moved = 0
$skipped = 0
$unclassified = 0

foreach ($file in $allFiles) {
    $processed++
    $classification = Get-FileCategory -FilePath $file.FullName

    if ($classification.Category -and $classification.Score -gt 0) {
        $destFolder = $categories[$classification.Category].folder
        $destPath = Join-Path $destBase $destFolder
        $destFile = Join-Path $destPath $file.Name

        # Check if destination folder exists
        if (-not (Test-Path $destPath)) {
            Write-Warning "Destination folder does not exist: $destPath"
            $skipped++
            continue
        }

        # Check if file already exists in destination
        if (Test-Path $destFile) {
            Write-Host "SKIP (exists): $($file.Name) -> 01/$destFolder" -ForegroundColor DarkYellow
            $skipped++
            continue
        }

        $result = [PSCustomObject]@{
            FileName = $file.Name
            Destination = $destFolder
            Score = $classification.Score
            Moved = $false
        }

        if (-not $DryRun) {
            try {
                Move-Item -Path $file.FullName -Destination $destFile -ErrorAction Stop
                $result.Moved = $true
                $moved++
                Write-Host "MOVED: $($file.Name) -> 01/$destFolder (score: $($classification.Score))" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to move $($file.Name): $_"
                $skipped++
            }
        }
        else {
            Write-Host "WOULD MOVE: $($file.Name) -> 01/$destFolder (score: $($classification.Score))" -ForegroundColor Cyan
        }

        $results += $result
    }
    else {
        Write-Host "NO MATCH: $($file.Name)" -ForegroundColor Yellow
        $unclassified++
    }
}

# Output summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Green
Write-Host "Files processed: $processed"
Write-Host "Files classified: $($results.Count)"
Write-Host "Files unclassified: $unclassified"
Write-Host "Files skipped: $skipped"
if (-not $DryRun) {
    Write-Host "Files moved: $moved" -ForegroundColor Green
}

# Group by destination
Write-Host "`n=== By Category ===" -ForegroundColor Cyan
$byDest = $results | Group-Object -Property Destination | Sort-Object Count -Descending
foreach ($group in $byDest) {
    Write-Host "$($group.Name): $($group.Count) files"
}

return $results
