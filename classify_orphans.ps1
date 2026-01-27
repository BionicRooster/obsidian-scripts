# Classify and Link Orphan Files to MOCs
# This script reads orphan files, classifies them by content, and creates links

param(
    # Maximum files to process (0 = all)
    [int]$Limit = 0,
    # Dry run - just output classifications without linking
    [switch]$DryRun,
    # Output classification results to JSON
    [switch]$OutputJson
)

# Vault configuration
$vaultPath = 'D:\Obsidian\Main'
$mocFolder = '00 - Home Dashboard'

# Folders to exclude from orphan processing (journal files should never be considered orphans)
$excludeFolders = @(
    '00 - Journal',
    '09 - Kindle Clippings',
    '.trash',
    '05 - Templates',
    '.obsidian',
    '.smart-env'
)

# MOC classification keywords - maps keywords to MOC and subsection
$mocClassification = @{
    # Technology & Computers
    'Technology' = @{
        'Programming & Development' = @('python', 'javascript', 'code', 'programming', 'script', 'api', 'github', 'developer', 'software', 'algorithm', 'function', 'variable', 'loop', 'class', 'object', 'json', 'xml', 'html', 'css', 'regex', 'perl', 'bash', 'powershell', 'vba', 'macro')
        'AI & Machine Learning' = @('ai', 'artificial intelligence', 'machine learning', 'neural', 'gpt', 'chatgpt', 'claude', 'llm', 'deep learning', 'model', 'training')
        'Linux Resources & Guides' = @('linux', 'ubuntu', 'debian', 'fedora', 'centos', 'bash', 'terminal', 'command line', 'sudo', 'apt', 'yum')
        'Databases & Access' = @('sql', 'database', 'access', 'query', 'table', 'mysql', 'postgresql', 'sqlite', 'vba', 'acspreadsheet')
        'Hardware & Electronics' = @('arduino', 'raspberry pi', 'circuit', 'pcb', 'electronics', 'hardware', 'cpu', 'memory', 'storage', 'ssd', 'hdd', 'usb', 'gpio', 'solder')
        'Retro Computing & Hardware' = @('z80', 'apple ii', '8-bit', 'commodore', 'atari', 'retro', 'vintage computer', 'cp/m', 's100', 'rc2014', 'altair', 'digicomp')
        'Networking & Systems' = @('network', 'dhcp', 'dns', 'tcp', 'ip', 'router', 'firewall', 'server', 'admin', 'sysadmin', 'windows server', 'active directory')
        'Software & Tools' = @('software', 'app', 'tool', 'utility', 'freeware', 'open source', 'firefox', 'chrome', 'browser', 'extension', 'plugin')
        'Troubleshooting & Guides' = @('troubleshoot', 'fix', 'error', 'problem', 'solution', 'how to', 'guide', 'tutorial', 'step by step', 'malware', 'virus', 'security')
        'Maker Projects' = @('maker', 'diy', '3d print', 'cnc', 'laser', 'robot', 'project', 'build', 'construct')
    }

    # Health & Nutrition
    'Health' = @{
        'Plant-Based Nutrition' = @('vegan', 'plant-based', 'vegetarian', 'wfpb', 'whole food', 'plant protein', 'veggie burger')
        'Medical & Health' = @('doctor', 'medical', 'health', 'disease', 'treatment', 'symptom', 'diagnosis', 'medicine', 'hospital', 'surgery', 'eye', 'dental', 'vision')
        'Exercise & Wellness' = @('exercise', 'fitness', 'workout', 'yoga', 'meditation', 'wellness', 'running', 'walking', 'gym')
        'Key Research & Books' = @('research', 'study', 'clinical', 'trial', 'greger', 'esselstyn', 'ornish', 'campbell')
    }

    # Bahá'í Faith
    'Bahá''í' = @{
        'Central Figures' = @('bahá''u''lláh', 'báb', '''abdu''l-bahá', 'shoghi effendi', 'guardian', 'manifestation')
        'Core Teachings' = @('unity', 'oneness', 'progressive revelation', 'covenant', 'consultation', 'bahá''í', 'bahai')
        'Administrative Guidance' = @('lsa', 'nsa', 'uhj', 'assembly', 'feast', 'administrative')
        'Nine Year Plan' = @('nine year plan', 'cluster', 'growth', 'expansion')
        'Bahá''í Books & Resources' = @('tablet', 'prayers', 'writings', 'kitáb', 'hidden words', 'seven valleys')
    }

    # Social Issues
    'Social' = @{
        'Race & Equity' = @('race', 'racism', 'equity', 'diversity', 'inclusion', 'black', 'white', 'discrimination', 'justice', 'civil rights')
        'Justice & Politics' = @('politics', 'political', 'government', 'policy', 'law', 'legal', 'court', 'vote', 'election', 'democracy')
        'Religion & Society' = @('religion', 'religious', 'faith', 'spiritual', 'church', 'christian', 'islam', 'jewish', 'hindu', 'buddhist')
        'Cultural Commentary' = @('culture', 'society', 'social', 'community', 'media', 'news', 'commentary')
    }

    # Recipes
    'Recipes' = @{
        'Main Dishes' = @('main dish', 'dinner', 'lunch', 'entrée', 'chicken', 'beef', 'fish', 'tofu', 'tempeh', 'seitan', 'burger', 'sandwich', 'rice', 'pasta', 'casserole')
        'Soups & Stews' = @('soup', 'stew', 'chili', 'broth', 'bisque', 'chowder')
        'Sides & Salads' = @('side', 'salad', 'vegetable', 'coleslaw', 'slaw', 'potato')
        'Desserts & Sweets' = @('dessert', 'sweet', 'cake', 'cookie', 'pie', 'brownie', 'chocolate', 'sugar', 'candy')
        'Breads & Baked Goods' = @('bread', 'bake', 'muffin', 'biscuit', 'roll', 'loaf', 'flour', 'dough', 'yeast')
        'Sauces/Dips & Condiments' = @('sauce', 'dip', 'condiment', 'dressing', 'marinade', 'gravy', 'pesto', 'hummus', 'salsa')
        'Beverages' = @('drink', 'beverage', 'smoothie', 'juice', 'tea', 'coffee', 'cocktail')
    }

    # Home & Practical Life
    'Home' = @{
        'Home Projects & Repairs' = @('home', 'house', 'repair', 'fix', 'maintenance', 'plumbing', 'electrical', 'renovation', 'remodel', 'water heater')
        'Sustainable Building & Alternative Homes' = @('sustainable', 'green building', 'solar', 'alternative home', 'tiny house', 'off-grid', 'sip', 'insulation')
        'Gardening & Urban Farming' = @('garden', 'plant', 'grow', 'soil', 'compost', 'vegetable garden', 'fruit', 'seed', 'harvest')
        'Life Productivity & Organization' = @('productivity', 'organize', 'declutter', 'minimize', 'efficient', 'gtd', 'to do', 'task', 'schedule')
        'Practical Tips & Life Hacks' = @('tip', 'hack', 'shortcut', 'trick', 'lifehack', 'save money', 'save time', 'portable', 'travel tip')
        'Entertainment & Film' = @('movie', 'film', 'tv', 'television', 'show', 'series', 'netflix', 'streaming', 'entertainment')
    }

    # Science & Nature
    'Science' = @{
        'Earth Sciences & Geology' = @('geology', 'earth', 'rock', 'mineral', 'volcano', 'earthquake', 'fossil', 'dinosaur', 'meteor', 'tsunami')
        'Archaeology & Anthropology' = @('archaeology', 'ancient', 'civilization', 'artifact', 'excavation', 'history', 'prehistoric', 'maya', 'roman', 'egyptian')
        'Space & Planetary Science' = @('space', 'mars', 'moon', 'planet', 'star', 'galaxy', 'nasa', 'astronomy', 'astronaut', 'satellite', 'cosmos')
        'Life Sciences' = @('biology', 'evolution', 'species', 'animal', 'bird', 'insect', 'ecosystem', 'ecology', 'nature')
        'Gardening & Nature' = @('nature', 'wildlife', 'forest', 'tree', 'flower', 'outdoor', 'hiking', 'camping', 'national park')
        'Micrometeorites' = @('micrometeorite', 'cosmic dust', 'space dust', 'meteor')
    }

    # NLP & Psychology
    'NLP_Psy' = @{
        'Cognitive Science' = @('cognitive', 'brain', 'mind', 'thinking', 'decision', 'bias', 'heuristic', 'kahneman', 'memory', 'attention', 'perception')
        'Learning & Memory' = @('learning', 'memory', 'recall', 'retention', 'study', 'education', 'teaching', 'dyslexia', 'reading')
        'Core NLP Concepts' = @('nlp', 'neuro-linguistic', 'anchoring', 'reframing', 'rapport', 'modeling', 'strategy', 'submodality')
        'Communication & Influence' = @('communication', 'persuasion', 'influence', 'negotiation', 'language pattern', 'hypnosis', 'milton model', 'meta model')
    }

    # Travel & Exploration
    'Travel' = @{
        'Narrowboat & Canal Travel' = @('narrowboat', 'canal', 'barge', 'waterway', 'lock', 'thames', 'britain canal')
        'National Parks & Nature' = @('national park', 'park', 'hiking', 'trail', 'camping', 'wilderness', 'big bend')
        'Specific Locations' = @('vacation', 'trip', 'itinerary', 'visit', 'atlanta', 'fort worth', 'moscow', 'santa fe', 'ireland', 'japan', 'europe', 'washington state')
        'RV & Alternative Living' = @('rv', 'camper', 'mobile', 'van life', 'nomad', 'road trip')
    }

    # Music & Record
    'Music' = @{
        'Recorder Resources' = @('recorder', 'flute', 'baroque', 'renaissance music', 'wind instrument')
        'Music Theory & Performance' = @('music', 'song', 'instrument', 'play', 'practice', 'chord', 'scale', 'melody', 'rhythm', 'sheet music')
        'Songs & Hymns' = @('hymn', 'song', 'lyrics', 'bahá''í song', 'choral')
    }

    # Personal Knowledge Management
    'PKM' = @{
        'Obsidian Integration' = @('obsidian', 'vault', 'note', 'zettelkasten', 'backlink', 'graph', 'plugin')
        'Note-Taking & Learning' = @('note-taking', 'notes', 'organize', 'knowledge', 'learn', 'research', 'reference')
        'Productivity Philosophy' = @('productivity', 'workflow', 'system', 'method', 'process', 'automation')
    }

    # Reading & Literature
    'Reading' = @{
        'Key Books by Topic' = @('book', 'author', 'read', 'reading', 'literature', 'novel', 'kindle', 'ebook', 'e-reader')
        'Kindle Clippings' = @('highlight', 'clipping', 'quote', 'excerpt', 'annotation')
    }

    # Finance & Investment
    'Finance' = @{
        'Investing Strategies' = @('invest', 'stock', 'bond', 'portfolio', 'dividend', 'index fund', 'etf', 'retirement', '401k', 'ira')
        'Financial Management' = @('budget', 'finance', 'money', 'save', 'expense', 'income', 'debt', 'credit', 'loan', 'mortgage')
        'Tax Software' = @('tax', 'irs', 'deduction', 'turbotax', 'form', 'filing')
    }

    # Genealogy
    'Genealogy' = @{
        'Talbot Family Members' = @('talbot', 'talbott', 'family', 'ancestor', 'genealogy', 'family tree', 'lineage')
        'Obituaries & Death Records' = @('obituary', 'death', 'funeral', 'memorial', 'cemetery', 'grave')
        'DNA & Genetic Genealogy' = @('dna', 'genetic', 'ancestry', '23andme', 'familytree dna', 'haplogroup')
    }

    # Soccer
    'Soccer' = @{
        'Learning the Game' = @('soccer', 'football', 'goal', 'kick', 'world cup', 'team', 'league', 'match', 'premier league', 'fifa')
    }
}

# MOC file mapping
$mocFiles = @{
    'Technology' = '00 - Home Dashboard\MOC - Technology & Computers.md'
    'Health' = '00 - Home Dashboard\MOC - Health & Nutrition.md'
    'Bahá''í' = '00 - Home Dashboard\MOC - Bahá''í Faith.md'
    'Social' = '00 - Home Dashboard\MOC - Social Issues.md'
    'Recipes' = '00 - Home Dashboard\MOC - Recipes.md'
    'Home' = '00 - Home Dashboard\MOC - Home & Practical Life.md'
    'Science' = '00 - Home Dashboard\MOC - Science & Nature.md'
    'NLP_Psy' = '00 - Home Dashboard\MOC - NLP & Psychology.md'
    'Travel' = '00 - Home Dashboard\MOC - Travel & Exploration.md'
    'Music' = '00 - Home Dashboard\MOC - Music & Record.md'
    'PKM' = '00 - Home Dashboard\MOC - Personal Knowledge Management.md'
    'Reading' = '00 - Home Dashboard\MOC - Reading & Literature.md'
    'Finance' = '00 - Home Dashboard\MOC - Finance & Investment.md'
    'Genealogy' = '00 - Home Dashboard\MOC - Genealogy.md'
    'Soccer' = '00 - Home Dashboard\MOC - Soccer.md'
}

# Function to classify a file based on its content
function Get-FileClassification {
    param(
        [string]$FilePath,
        [string]$FileName
    )

    # Read file content
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) {
        return $null
    }

    # Combine filename and content for analysis (lowercase for matching)
    $searchText = ($FileName + " " + $content).ToLower()

    # Track best match
    $bestMoc = $null
    $bestSubsection = $null
    $bestScore = 0

    # Score each MOC and subsection
    foreach ($mocName in $mocClassification.Keys) {
        $mocData = $mocClassification[$mocName]

        foreach ($subsection in $mocData.Keys) {
            $keywords = $mocData[$subsection]
            $score = 0

            foreach ($keyword in $keywords) {
                # Count keyword occurrences (weighted by specificity)
                $matches = [regex]::Matches($searchText, [regex]::Escape($keyword.ToLower()))
                if ($matches.Count -gt 0) {
                    # Longer keywords are more specific and get higher weight
                    $weight = [Math]::Max(1, $keyword.Length / 5)
                    $score += $matches.Count * $weight
                }
            }

            # Update best match if this score is higher
            if ($score -gt $bestScore) {
                $bestScore = $score
                $bestMoc = $mocName
                $bestSubsection = $subsection
            }
        }
    }

    # Return classification if score is above threshold
    if ($bestScore -gt 2) {
        return @{
            MOC = $bestMoc
            Subsection = $bestSubsection
            Score = $bestScore
            MOCPath = $mocFiles[$bestMoc]
        }
    }

    return $null
}

# Function to add bidirectional link
function Add-BidirectionalLink {
    param(
        [string]$OrphanRelPath,
        [string]$MOCRelPath,
        [string]$SubsectionName
    )

    $orphanFullPath = Join-Path $vaultPath $OrphanRelPath
    $mocFullPath = Join-Path $vaultPath $MOCRelPath

    if (-not (Test-Path $orphanFullPath)) {
        Write-Warning "Orphan file not found: $OrphanRelPath"
        return $false
    }
    if (-not (Test-Path $mocFullPath)) {
        Write-Warning "MOC file not found: $MOCRelPath"
        return $false
    }

    $orphanName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $OrphanRelPath -Leaf))
    $mocName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $MOCRelPath -Leaf))

    # === Add link from orphan to MOC ===
    $orphanContent = Get-Content -Path $orphanFullPath -Raw -Encoding UTF8
    $mocLinkPath = $MOCRelPath.Replace('\', '/').Replace('.md', '')

    # Check if link already exists
    if ($orphanContent -notmatch [regex]::Escape("[[$mocLinkPath")) {
        # Find or create Related Notes section
        if ($orphanContent -match '## Related Notes') {
            $orphanContent = $orphanContent -replace '(## Related Notes[^\n]*\n)', "`$1- [[$mocLinkPath|$mocName]]`n"
        } else {
            $orphanContent = $orphanContent.TrimEnd() + "`n`n---`n## Related Notes`n- [[$mocLinkPath|$mocName]]`n"
        }
        Set-Content -Path $orphanFullPath -Value $orphanContent -Encoding UTF8 -NoNewline
    }

    # === Add link from MOC to orphan under the subsection ===
    $mocContent = Get-Content -Path $mocFullPath -Raw -Encoding UTF8
    $orphanLinkPath = $OrphanRelPath.Replace('\', '/').Replace('.md', '')

    # Check if orphan already linked in MOC
    if ($mocContent -notmatch [regex]::Escape("[[$orphanLinkPath")) {
        # Find the subsection and add the link after it
        $escapedSubsection = [regex]::Escape($SubsectionName)
        $subsectionPattern = "(?m)(^## $escapedSubsection[^\n]*\n)"

        if ($mocContent -match $subsectionPattern) {
            $newLink = "- [[$orphanLinkPath|$orphanName]]`n"
            $mocContent = $mocContent -replace $subsectionPattern, "`$1$newLink"
            Set-Content -Path $mocFullPath -Value $mocContent -Encoding UTF8 -NoNewline
            return $true
        } else {
            # Try level 3 headers
            $subsectionPattern = "(?m)(^### $escapedSubsection[^\n]*\n)"
            if ($mocContent -match $subsectionPattern) {
                $newLink = "- [[$orphanLinkPath|$orphanName]]`n"
                $mocContent = $mocContent -replace $subsectionPattern, "`$1$newLink"
                Set-Content -Path $mocFullPath -Value $mocContent -Encoding UTF8 -NoNewline
                return $true
            }
        }
    }

    return $false
}

# Main processing
Write-Host "=== Orphan File Classifier and Linker ===" -ForegroundColor Cyan
Write-Host "Vault: $vaultPath" -ForegroundColor Gray
Write-Host ""

# Load orphan list
$orphanListPath = "C:\Users\awt\orphan_list.json"
if (-not (Test-Path $orphanListPath)) {
    Write-Error "Orphan list not found. Run 'moc_orphan_linker.ps1 -Action get-orphans' first."
    exit 1
}

$orphans = Get-Content -Path $orphanListPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Filter out excluded folders
$filteredOrphans = @()
foreach ($orphan in $orphans) {
    $skip = $false
    foreach ($folder in $excludeFolders) {
        if ($orphan.RelativePath -match "^$([regex]::Escape($folder))") {
            $skip = $true
            break
        }
    }
    if (-not $skip) {
        $filteredOrphans += $orphan
    }
}

Write-Host "Total orphans after filtering: $($filteredOrphans.Count)" -ForegroundColor White

# Apply limit if specified
if ($Limit -gt 0 -and $Limit -lt $filteredOrphans.Count) {
    $filteredOrphans = $filteredOrphans | Select-Object -First $Limit
    Write-Host "Processing first $Limit files" -ForegroundColor Yellow
}

# Process each orphan
$classifications = @()
$linked = 0
$unclassified = 0

foreach ($orphan in $filteredOrphans) {
    $fullPath = $orphan.FullPath

    # Skip if file doesn't exist
    if (-not (Test-Path $fullPath)) {
        continue
    }

    # Get classification
    $classification = Get-FileClassification -FilePath $fullPath -FileName $orphan.Name

    if ($classification) {
        $result = @{
            File = $orphan.Name
            RelativePath = $orphan.RelativePath
            MOC = $classification.MOC
            Subsection = $classification.Subsection
            Score = $classification.Score
            MOCPath = $classification.MOCPath
        }
        $classifications += $result

        Write-Host "[$($classification.MOC)] $($orphan.Name) -> $($classification.Subsection) (score: $($classification.Score))" -ForegroundColor Green

        # Create links if not dry run
        if (-not $DryRun) {
            $linkResult = Add-BidirectionalLink -OrphanRelPath $orphan.RelativePath -MOCRelPath $classification.MOCPath -SubsectionName $classification.Subsection
            if ($linkResult) {
                $linked++
            }
        }
    } else {
        $unclassified++
        Write-Host "[UNCLASSIFIED] $($orphan.Name)" -ForegroundColor Yellow
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Classified: $($classifications.Count)" -ForegroundColor Green
Write-Host "Unclassified: $unclassified" -ForegroundColor Yellow
if (-not $DryRun) {
    Write-Host "Links created: $linked" -ForegroundColor Green
}

# Output JSON if requested
if ($OutputJson) {
    $jsonOutput = @{
        TotalProcessed = $filteredOrphans.Count
        Classified = $classifications.Count
        Unclassified = $unclassified
        Classifications = $classifications
    } | ConvertTo-Json -Depth 4

    $outputPath = "C:\Users\awt\orphan_classifications.json"
    $jsonOutput | Set-Content -Path $outputPath -Encoding UTF8
    Write-Host "Classifications saved to: $outputPath" -ForegroundColor Gray
}

# Group by MOC for summary
Write-Host ""
Write-Host "=== By MOC ===" -ForegroundColor Cyan
$byMoc = $classifications | Group-Object -Property MOC | Sort-Object Count -Descending
foreach ($group in $byMoc) {
    Write-Host "$($group.Name): $($group.Count) files" -ForegroundColor White
}
