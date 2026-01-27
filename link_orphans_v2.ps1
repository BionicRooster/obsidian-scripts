# Obsidian Orphan File Linker v2
# More targeted linking based on file names and specific content

param(
    [switch]$DryRun = $false,
    [int]$MaxFiles = 0  # 0 = no limit
)

# Vault configuration
$vaultPath = 'D:\Obsidian\Main'
$reportPath = 'D:\Obsidian\Main\00 - Home Dashboard\Orphan File Connection Report.md'

# More targeted category definitions - requires strong matches
$categories = @{
    'Recipes' = @{
        MOC = '00 - Home Dashboard/MOC - Recipes'
        TitleKeywords = @('recipe', 'soup', 'salad', 'cake', 'bread', 'cookie', 'muffin', 'stew', 'curry', 'bean', 'lentil', 'tofu', 'vegan', 'hummus', 'falafel', 'tempeh', 'granola', 'smoothie', 'brownie', 'pie', 'chili', 'burrito', 'taco', 'enchilada', 'lasagna', 'risotto', 'couscous', 'millet', 'barley', 'focaccia', 'tortilla', 'burger', 'casserole', 'gnocchi', 'spaghetti', 'pasta', 'noodle', 'sauce', 'dip', 'chutney', 'compote', 'ketchup', 'catchup', 'marinade', 'dressing', 'marmalade', 'sauerkraut', 'kimchi', 'daal', 'dal', 'masala', 'tagine', 'colcannon', 'quinoa', 'tabbouleh', 'fudgy', 'meatball', 'meatloaf', 'loaf', 'fried rice', 'spring roll', 'lettuce cup', 'kichadi', 'tempeh', 'chickpea', 'spinach', 'cauliflower', 'carrot', 'potato', 'sweet potato', 'pumpkin', 'apple', 'banana', 'strawberry', 'raspberry', 'blackberry', 'blueberry', 'gingerbread', 'oatmeal', 'oat', 'chocolate', 'peanut butter', 'graham cracker', 'pecan', 'hazelnut', 'ginger tea', 'turmeric tea')
        ContentPatterns = @('## Ingredients', '## Instructions', '## Directions', 'cups of', 'tablespoon', 'teaspoon', 'preheat oven', 'bake for', 'simmer for', 'serves \d+', 'servings', 'prep time', 'cook time')
        Section = 'Recipes'
    }
    'NLP' = @{
        MOC = '00 - Home Dashboard/MOC - NLP & Psychology'
        TitleKeywords = @('NLP', 'neuro-linguistic', 'anchoring', 'reframe', 'reframing', 'phobia cure', 'rapport', 'timeline therapy', 'presupposition', 'meta-model', 'metamodel', 'milton model', 'sleight of mouth', 'submodality', 'swish', 'circle of excellence', 'logical levels', 'well-formed outcome', 'outcome specification', 'ROET', 'SCORE', 'embedded command', 'anchor', 'calibration', 'pacing', 'leading', 'perceptual position', 'strategy elicitation', 'modeling', 'six step', 'change history', 'reimprinting', 'prove the theorem', 'ramblings', 'moreno challenge', 'transderivational', 'ecology check', 'future pace')
        ContentPatterns = @('representational system', 'V-K dissociation', 'visual kinesthetic', 'auditory digital', 'eye accessing', 'predicates', 'deletion.*distortion.*generalization', 'logical level', 'neurological level')
        Section = 'NLP & Psychology'
    }
    'Bahai' = @{
        MOC = "00 - Home Dashboard/MOC - Bahá'í Faith"
        TitleKeywords = @("Bahá'í", "Bahai", "Baha'i", "Bahá'u'lláh", "Bahaullah", "'Abdu'l-Bahá", "Abdul-Baha", "Shoghi Effendi", "LSA", "NSA", "Feast", "Nineteen Day", "Ridván", "Ridvan", "Naw-Rúz", "Ayyám-i-Há", "Báb", "Tablet", "Kitáb", "Hidden Words", "Seven Valleys", "Gleanings", "Ruhi", "institute process", "devotional", "GCCMA", "spiritual assembly", "House of Justice", "UHJ", "race amity", "race unity", "unity", "consultation", "coherence", "nine year plan", "bicentenary")
        ContentPatterns = @("Universal House of Justice", "beloved friends", "the Blessed Beauty", "progressive revelation", "oneness of mankind", "oneness of humanity", "administrative order")
        Section = "Bahá'í Faith"
    }
    'Technology' = @{
        MOC = '00 - Home Dashboard/MOC - Technology & Computing'
        TitleKeywords = @('programming', 'code', 'coding', 'software', 'hardware', 'Linux', 'Windows', 'macOS', 'Python', 'Java', 'JavaScript', 'PowerShell', 'bash', 'shell', 'script', 'API', 'database', 'SQL', 'server', 'network', 'Arduino', 'Raspberry Pi', 'circuit', 'PCB', 'USB', 'HDMI', 'WiFi', 'Ethernet', 'router', 'Excel', 'spreadsheet', 'VBA', 'macro', 'plugin', 'extension', 'app', 'mobile', 'Android', 'iOS', 'web', 'HTML', 'CSS', 'git', 'GitHub', 'Docker', 'cloud', 'AWS', 'Azure', 'VM', 'virtual machine', 'Obsidian', 'Evernote', 'note-taking', 'automation', 'Perl', 'regex', 'batch file', 'command line', 'terminal', 'ChromeOS', 'Chromebook', 'Google Apps', 'Office 365')
        ContentPatterns = @('```.*```', 'function\s+\w+\s*\(', 'class\s+\w+', 'def\s+\w+\s*\(', 'import\s+\w+', '#include', 'SELECT.*FROM', 'INSERT INTO', 'CREATE TABLE', 'const\s+\w+\s*=', 'var\s+\w+\s*=', 'let\s+\w+\s*=')
        Section = 'Technology'
    }
    'Health' = @{
        MOC = '00 - Home Dashboard/MOC - Health & Nutrition'
        TitleKeywords = @('health', 'nutrition', 'diet', 'vegan', 'vegetarian', 'plant-based', 'WFPB', 'whole food', 'Esselstyn', 'Ornish', 'McDougall', 'Barnard', 'Greger', 'Fuhrman', 'Campbell', 'China Study', 'Forks Over Knives', 'Engine 2', 'Blue Zone', 'protein', 'vitamin', 'mineral', 'supplement', 'antioxidant', 'inflammation', 'cholesterol', 'blood pressure', 'diabetes', 'heart disease', 'cancer', 'obesity', 'weight loss', 'exercise', 'fitness', 'yoga', 'meditation', 'mindfulness', 'sleep', 'stress', 'mental health', 'wellness', 'preventive', 'holistic', 'medical', 'doctor', 'physician')
        ContentPatterns = @('clinical trial', 'randomized', 'placebo', 'peer-reviewed', 'meta-analysis', 'systemic review', 'cardiovascular', 'glycemic', 'BMI', 'body mass')
        Section = 'Health & Nutrition'
    }
    'Genealogy' = @{
        MOC = '00 - Home Dashboard/MOC - Home & Practical Life'
        TitleKeywords = @('genealogy', 'ancestry', 'ancestor', 'descendant', 'family tree', 'pedigree', 'DNA', 'genetic genealogy', 'census', 'birth certificate', 'death certificate', 'marriage certificate', 'obituary', 'cemetery', 'grave', 'headstone', 'probate', 'will', 'deed', 'land record', 'Talbot', 'Horn', 'White', 'Joiner', 'Fillingim', 'Dewey', 'FamilySearch', 'Ancestry', 'FindMyPast', 'MyHeritage', 'GEDmatch', 'FTDNA', '23andMe', 'AncestryDNA', 'haplogroup', 'mitochondrial', 'Y-DNA', 'autosomal', 'ethnicity', 'immigration', 'Ellis Island', 'naturalization', 'passenger list', 'ship manifest')
        ContentPatterns = @('born\s+\d{4}', 'died\s+\d{4}', 'married\s+\d{4}', 'b\.\s*\d{4}', 'd\.\s*\d{4}', 'm\.\s*\d{4}', 'son of', 'daughter of', 'wife of', 'husband of', 'father of', 'mother of')
        Section = 'Genealogy'
    }
    'Travel' = @{
        MOC = '00 - Home Dashboard/MOC - Travel & Exploration'
        TitleKeywords = @('travel', 'trip', 'vacation', 'journey', 'adventure', 'exploration', 'destination', 'itinerary', 'narrowboat', 'canal', 'waterway', 'lock', 'mooring', 'RV', 'motorhome', 'camper', 'caravan', 'camping', 'national park', 'Yellowstone', 'Grand Canyon', 'Yosemite', 'Zion', 'Bryce', 'Arches', 'Rocky Mountain', 'Great Smoky', 'Petrified Forest', 'state park', 'hiking', 'trail', 'England', 'Scotland', 'Wales', 'Ireland', 'UK', 'Europe', 'Hollywood', 'Washington State')
        ContentPatterns = @('miles from', 'kilometers from', 'visited\s+\w+\s+on', 'flew to', 'drove to', 'stayed at', 'checked into', 'hotel', 'motel', 'Airbnb')
        Section = 'Travel & Exploration'
    }
    'Science' = @{
        MOC = '00 - Home Dashboard/MOC - Science & Nature'
        TitleKeywords = @('science', 'scientific', 'research', 'experiment', 'discovery', 'archaeology', 'archaeologist', 'fossil', 'dinosaur', 'ancient', 'prehistoric', 'geology', 'rock', 'mineral', 'meteorite', 'micrometeorite', 'astronomy', 'space', 'planet', 'star', 'galaxy', 'NASA', 'Smithsonian', 'paleontology', 'evolution', 'biology', 'chemistry', 'physics', 'environment', 'climate', 'nature', 'wildlife', 'ecosystem', 'conservation', 'gardening', 'permaculture', 'botany', 'plant', 'tree', 'flower', 'seed')
        ContentPatterns = @('researchers found', 'scientists discovered', 'study shows', 'according to research', 'peer-reviewed', 'journal of', 'published in')
        Section = 'Science & Nature'
    }
    'Music' = @{
        MOC = '00 - Home Dashboard/MOC - Music & Recorders'
        TitleKeywords = @('music', 'musical', 'song', 'melody', 'recorder', 'flute', 'clarinet', 'saxophone', 'trumpet', 'violin', 'guitar', 'piano', 'keyboard', 'orchestra', 'band', 'choir', 'symphony', 'concerto', 'sonata', 'baroque', 'classical', 'jazz', 'blues', 'folk', 'ukulele', 'banjo', 'mandolin', 'practice', 'performance', 'concert', 'recital')
        ContentPatterns = @('music theory', 'fingering', 'technique', 'notation', 'sheet music', 'time signature', 'key signature', 'major scale', 'minor scale', 'chord progression')
        Section = 'Music & Recorders'
    }
    'Reading' = @{
        MOC = '00 - Home Dashboard/MOC - Reading & Literature'
        TitleKeywords = @('book', 'novel', 'author', 'reading', 'Kindle', 'clipping', 'highlight', 'chapter', 'biography', 'autobiography', 'memoir', 'fiction', 'non-fiction', 'literature', 'poetry', 'poem')
        ContentPatterns = @('## Kindle Clipping', '## Book Notes', 'Page \d+', 'Location \d+', 'Highlight on Page', 'Note on Page')
        Section = 'Reading & Literature'
    }
    'Finance' = @{
        MOC = '00 - Home Dashboard/MOC - Finance & Investment'
        TitleKeywords = @('finance', 'financial', 'investment', 'investing', 'stock', 'bond', 'dividend', 'yield', 'portfolio', 'Buffett', 'Graham', 'value investing', 'index fund', 'ETF', 'mutual fund', '401k', 'IRA', 'retirement', 'budget', 'savings', 'USAA', 'Vanguard', 'Fidelity', 'Schwab')
        ContentPatterns = @('P/E ratio', 'earnings per share', 'dividend yield', 'return on equity', 'market cap', 'price target', 'buy rating', 'sell rating', 'hold rating')
        Section = 'Finance & Investment'
    }
    'Soccer' = @{
        MOC = '00 - Home Dashboard/MOC - Soccer'
        TitleKeywords = @('soccer', 'football', 'futbol', 'Premier League', 'La Liga', 'Serie A', 'Bundesliga', 'MLS', 'World Cup', 'Champions League', 'Ted Lasso', 'AFC Richmond', 'Manchester', 'Liverpool', 'Chelsea', 'Arsenal', 'Barcelona', 'Real Madrid', 'Bayern', 'FC Dallas', 'Houston Dynamo', 'Austin FC')
        ContentPatterns = @('goal scored', 'match result', 'final score', 'league table', 'transfer window', 'starting lineup')
        Section = 'Soccer'
    }
    'Social' = @{
        MOC = '00 - Home Dashboard/MOC - Social Issues & Culture'
        TitleKeywords = @('social issue', 'racism', 'racial', 'civil rights', 'human rights', 'voting rights', 'discrimination', 'prejudice', 'diversity', 'inclusion', 'equity', 'equality', 'justice', 'injustice', 'Black Lives Matter', 'BLM', 'NAACP', 'ACLU', 'activism', 'activist', 'advocate', 'protest', 'march', 'rally', 'immigration', 'immigrant', 'refugee', 'indigenous', 'Native American', 'tribal', 'poverty', 'homelessness', 'inequality', 'climate', 'environment', 'sustainability')
        ContentPatterns = @('systemic racism', 'structural inequality', 'racial justice', 'social justice', 'human rights violation', 'civil disobedience', 'peaceful protest')
        Section = 'Social Issues & Culture'
    }
}

# Skip these folders - they have their own natural organization
$skipFolders = @('00 - Journal', '05 - Templates', '00 - Images', 'attachments', '.trash', '.obsidian', '.smart-env')

# Initialize tracking
$changes = @{
    FilesProcessed = 0
    LinksAdded = 0
    MOCsUpdated = @{}
    Connections = @()
    Errors = @()
    Skipped = @()
}

# Function to check if file matches a category
function Test-FileCategory {
    param(
        [string]$FileName,
        [string]$Content,
        [hashtable]$Category
    )

    $searchName = $FileName.ToLower()

    # Check title keywords first (most reliable)
    foreach ($keyword in $Category.TitleKeywords) {
        if ($searchName -match [regex]::Escape($keyword.ToLower())) {
            return @{ Match = $true; Reason = "Title: $keyword" }
        }
    }

    # Check content patterns (more reliable than broad keywords)
    if ($Content -and $Category.ContentPatterns) {
        foreach ($pattern in $Category.ContentPatterns) {
            if ($Content -match $pattern) {
                return @{ Match = $true; Reason = "Content: $pattern" }
            }
        }
    }

    return @{ Match = $false; Reason = $null }
}

# Function to add link to file
function Add-RelatedLink {
    param(
        [string]$FilePath,
        [string]$LinkTarget,
        [string]$LinkText
    )

    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $content) { $content = "" }

        # Check if link already exists
        if ($content -match [regex]::Escape("[[$LinkTarget")) {
            return $false
        }

        # Find or create Related Notes section
        if ($content -match '## Related Notes') {
            $content = $content -replace '(## Related Notes[^\n]*\n)', "`$1- [[$LinkTarget|$LinkText]]`n"
        } else {
            $content = $content.TrimEnd() + "`n`n---`n## Related Notes`n- [[$LinkTarget|$LinkText]]`n"
        }

        if (-not $DryRun) {
            Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
        }
        return $true
    }
    catch {
        return $false
    }
}

# Function to add backlink to MOC
function Add-BacklinkToMOC {
    param(
        [string]$MOCPath,
        [string]$OrphanName,
        [string]$OrphanRelPath
    )

    $fullMOCPath = Join-Path $vaultPath "$MOCPath.md"
    if (-not (Test-Path $fullMOCPath)) { return $false }

    try {
        $content = Get-Content -Path $fullMOCPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $content) { return $false }

        # Check if already linked
        $escapedName = [regex]::Escape($OrphanName)
        if ($content -match "\[\[$escapedName") {
            return $false
        }

        # Add to Recently Connected Orphans section
        $sectionHeader = "## Recently Connected Orphans"
        if ($content -notmatch [regex]::Escape($sectionHeader)) {
            $content = $content.TrimEnd() + "`n`n---`n$sectionHeader`n"
        }

        $linkPath = $OrphanRelPath.Replace('\', '/').Replace('.md', '')
        $newLink = "- [[$linkPath|$OrphanName]]"
        $content = $content -replace "($([regex]::Escape($sectionHeader))[^\n]*\n)", "`$1$newLink`n"

        if (-not $DryRun) {
            Set-Content -Path $fullMOCPath -Value $content -Encoding UTF8 -NoNewline
        }
        return $true
    }
    catch {
        return $false
    }
}

# Main processing
Write-Host "=== Obsidian Orphan File Linker v2 ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
}

# Read filtered orphan list (only .md files)
$orphanList = Get-Content 'C:\Users\awt\orphan_filtered.txt' | Where-Object { $_ -like "*.md" }
Write-Host "Found $($orphanList.Count) orphan .md files" -ForegroundColor Gray

# Filter out skip folders
$orphanList = $orphanList | Where-Object {
    $path = $_
    $skip = $false
    foreach ($folder in $skipFolders) {
        if ($path -match "^$([regex]::Escape($folder))") {
            $skip = $true
            break
        }
    }
    -not $skip
}

Write-Host "After filtering skip folders: $($orphanList.Count)" -ForegroundColor Gray

if ($MaxFiles -gt 0) {
    $orphanList = $orphanList | Select-Object -First $MaxFiles
    Write-Host "Processing first $MaxFiles files" -ForegroundColor Yellow
}

$processed = 0
foreach ($orphanPath in $orphanList) {
    $fullPath = Join-Path $vaultPath $orphanPath

    if (-not (Test-Path $fullPath)) {
        $changes.Errors += "File not found: $orphanPath"
        continue
    }

    $processed++
    if ($processed % 50 -eq 0) {
        Write-Progress -Activity "Processing orphan files" -Status "$processed / $($orphanList.Count)" -PercentComplete (($processed / $orphanList.Count) * 100)
    }

    $fileName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $orphanPath -Leaf))
    $content = Get-Content -Path $fullPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

    $matchedCategories = @()

    foreach ($catName in $categories.Keys) {
        $cat = $categories[$catName]
        $result = Test-FileCategory -FileName $fileName -Content $content -Category $cat

        if ($result.Match) {
            $matchedCategories += @{
                Name = $catName
                MOC = $cat.MOC
                Section = $cat.Section
                Reason = $result.Reason
            }
        }
    }

    if ($matchedCategories.Count -eq 0) {
        $changes.Skipped += $orphanPath
        continue
    }

    $connections = @()

    foreach ($match in $matchedCategories) {
        $mocName = Split-Path $match.MOC -Leaf

        # Add link from orphan to MOC
        if (Add-RelatedLink -FilePath $fullPath -LinkTarget $match.MOC -LinkText $mocName) {
            $changes.LinksAdded++
            $connections += $mocName
        }

        # Add backlink from MOC to orphan
        if (Add-BacklinkToMOC -MOCPath $match.MOC -OrphanName $fileName -OrphanRelPath $orphanPath) {
            $changes.LinksAdded++
            if (-not $changes.MOCsUpdated.ContainsKey($match.MOC)) {
                $changes.MOCsUpdated[$match.MOC] = @()
            }
            $changes.MOCsUpdated[$match.MOC] += $fileName
        }
    }

    if ($connections.Count -gt 0) {
        $changes.Connections += @{
            File = $orphanPath
            Categories = ($matchedCategories | ForEach-Object { $_.Name }) -join ', '
            MOCs = $connections -join ', '
            Reasons = ($matchedCategories | ForEach-Object { $_.Reason }) -join '; '
        }
    }

    $changes.FilesProcessed++
}

Write-Progress -Activity "Processing orphan files" -Completed

# Results summary
Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "Files processed: $($changes.FilesProcessed)" -ForegroundColor White
Write-Host "Links added: $($changes.LinksAdded)" -ForegroundColor Green
Write-Host "MOCs updated: $($changes.MOCsUpdated.Count)" -ForegroundColor Green
Write-Host "Connections made: $($changes.Connections.Count)" -ForegroundColor Green
Write-Host "Files skipped (no match): $($changes.Skipped.Count)" -ForegroundColor Yellow

# Generate markdown report
$reportContent = @"
# Orphan File Connection Report

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Mode:** $(if ($DryRun) { "Dry Run (no changes made)" } else { "Live Run" })

## Summary

| Metric | Count |
|--------|-------|
| Files Processed | $($changes.FilesProcessed) |
| Links Added | $($changes.LinksAdded) |
| MOCs Updated | $($changes.MOCsUpdated.Count) |
| Connections Made | $($changes.Connections.Count) |
| Files Skipped | $($changes.Skipped.Count) |
| Errors | $($changes.Errors.Count) |

---

## MOCs Updated

"@

foreach ($moc in $changes.MOCsUpdated.Keys | Sort-Object) {
    $files = $changes.MOCsUpdated[$moc]
    $mocShortName = Split-Path $moc -Leaf
    $reportContent += "`n### $mocShortName`n"
    $reportContent += "Connected $($files.Count) orphan files:`n"
    foreach ($file in $files | Sort-Object | Select-Object -First 30) {
        $reportContent += "- [[$file]]`n"
    }
    if ($files.Count -gt 30) {
        $reportContent += "- *... and $($files.Count - 30) more*`n"
    }
}

$reportContent += @"

---

## All Connections

"@

foreach ($conn in $changes.Connections | Sort-Object { $_.Categories } | Select-Object -First 200) {
    $fileName = Split-Path $conn.File -Leaf
    $filePath = $conn.File.Replace('.md','').Replace('\', '/')
    $reportContent += "- [[$filePath|$fileName]] → **$($conn.Categories)**`n"
}

if ($changes.Connections.Count -gt 200) {
    $reportContent += "`n*... and $($changes.Connections.Count - 200) more connections*`n"
}

$reportContent += @"

---

*Report generated by Obsidian Orphan Linker v2*
"@

# Save or display report
if (-not $DryRun) {
    Set-Content -Path $reportPath -Value $reportContent -Encoding UTF8
    Write-Host "`nReport saved to: $reportPath" -ForegroundColor Cyan
} else {
    Write-Host "`n=== REPORT PREVIEW ===" -ForegroundColor Yellow
    Write-Host $reportContent
}
