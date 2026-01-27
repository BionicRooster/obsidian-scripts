# Crosslink Related Files Across MOCs
# This script identifies files with overlapping topics and creates bidirectional crosslinks

param(
    # Dry run - just output potential crosslinks without creating them
    [switch]$DryRun,
    # Maximum crosslinks per file
    [int]$MaxLinksPerFile = 5
)

# Vault configuration
$vaultPath = 'D:\Obsidian\Main'

# Cross-topic relationship patterns
# Maps topics to their related topics for crosslinking
$crossTopicPatterns = @{
    # Cognitive Science ↔ Health (brain, learning, memory)
    'cognitive_health' = @{
        Topic1Keywords = @('cognitive', 'brain', 'memory', 'learning', 'thinking', 'decision', 'attention', 'perception', 'dyslexia', 'reading')
        Topic2Keywords = @('health', 'medical', 'wellness', 'disease', 'treatment', 'nutrition', 'exercise')
        Topic1MOC = 'NLP & Psychology'
        Topic2MOC = 'Health & Nutrition'
    }

    # Race/Social Justice ↔ Bahá'í Teachings
    'race_bahai' = @{
        Topic1Keywords = @('race', 'racism', 'equity', 'diversity', 'justice', 'civil rights', 'discrimination', 'unity')
        Topic2Keywords = @('bahá''í', 'bahai', 'unity', 'oneness', 'humanity', 'spiritual', 'divine')
        Topic1MOC = 'Social Issues'
        Topic2MOC = 'Bahá''í Faith'
    }

    # Technology/AI ↔ Education/Learning
    'tech_education' = @{
        Topic1Keywords = @('ai', 'machine learning', 'automation', 'software', 'programming', 'algorithm', 'computer')
        Topic2Keywords = @('learning', 'education', 'teaching', 'study', 'student', 'training', 'knowledge')
        Topic1MOC = 'Technology & Computers'
        Topic2MOC = 'NLP & Psychology'
    }

    # Maker/DIY ↔ Sustainability/Home
    'maker_sustainability' = @{
        Topic1Keywords = @('maker', 'diy', 'build', 'create', 'project', 'arduino', 'raspberry pi', 'electronics')
        Topic2Keywords = @('sustainable', 'solar', 'green', 'eco', 'garden', 'home', 'self-sufficient', 'off-grid')
        Topic1MOC = 'Technology & Computers'
        Topic2MOC = 'Home & Practical Life'
    }

    # Science/Nature ↔ Indigenous/Cultural Knowledge
    'science_culture' = @{
        Topic1Keywords = @('science', 'nature', 'ecology', 'environment', 'wildlife', 'geology', 'astronomy')
        Topic2Keywords = @('indigenous', 'native', 'traditional', 'cultural', 'ancient', 'wisdom', 'spiritual')
        Topic1MOC = 'Science & Nature'
        Topic2MOC = 'Social Issues'
    }

    # Books/Reading ↔ PKM/Learning
    'books_pkm' = @{
        Topic1Keywords = @('book', 'reading', 'kindle', 'ebook', 'literature', 'author')
        Topic2Keywords = @('note', 'obsidian', 'zettelkasten', 'knowledge', 'organize', 'link', 'backlink')
        Topic1MOC = 'Reading & Literature'
        Topic2MOC = 'Personal Knowledge Management'
    }

    # Retro Computing ↔ History/Archaeology
    'retro_history' = @{
        Topic1Keywords = @('z80', 'retro', 'vintage', 'computer history', 'apple ii', 'commodore', '8-bit', 'altair')
        Topic2Keywords = @('history', 'historical', 'archaeology', 'ancient', 'museum', 'archive', 'preservation')
        Topic1MOC = 'Technology & Computers'
        Topic2MOC = 'Science & Nature'
    }

    # Travel ↔ Bahá'í (pilgrimage)
    'travel_bahai' = @{
        Topic1Keywords = @('travel', 'trip', 'vacation', 'visit', 'tour', 'pilgrimage')
        Topic2Keywords = @('bahá''í', 'haifa', 'acre', 'shrine', 'holy land', 'pilgrimage', 'gardens')
        Topic1MOC = 'Travel & Exploration'
        Topic2MOC = 'Bahá''í Faith'
    }

    # Narrowboat/Canal ↔ UK Travel
    'narrowboat_uk' = @{
        Topic1Keywords = @('narrowboat', 'canal', 'waterway', 'barge', 'lock', 'thames')
        Topic2Keywords = @('britain', 'england', 'uk', 'wales', 'scotland', 'london')
        Topic1MOC = 'Travel & Exploration'
        Topic2MOC = 'Travel & Exploration'
    }
}

# Function to analyze file content for topic relevance
function Get-TopicRelevance {
    param(
        [string]$Content,
        [string]$FileName,
        [array]$Keywords
    )

    # Combine filename and content for analysis
    $searchText = ($FileName + " " + $Content).ToLower()
    $score = 0

    foreach ($keyword in $Keywords) {
        $matches = [regex]::Matches($searchText, [regex]::Escape($keyword.ToLower()))
        if ($matches.Count -gt 0) {
            $weight = [Math]::Max(1, $keyword.Length / 5)
            $score += $matches.Count * $weight
        }
    }

    return $score
}

# Function to add crosslinks to a file
function Add-CrossLinks {
    param(
        [string]$FilePath,
        [array]$RelatedFiles  # Array of @{Name, Path, Score}
    )

    if (-not (Test-Path $FilePath)) {
        return $false
    }

    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $modified = $false

    foreach ($related in $RelatedFiles) {
        $linkPath = $related.Path.Replace('\', '/').Replace('.md', '')
        $linkName = $related.Name

        # Check if link already exists
        if ($content -notmatch [regex]::Escape("[[$linkPath")) {
            # Add to Related Notes section
            if ($content -match '## Related Notes') {
                $content = $content -replace '(## Related Notes[^\n]*\n)', "`$1- [[$linkPath|$linkName]]`n"
            } else {
                $content = $content.TrimEnd() + "`n`n---`n## Related Notes`n- [[$linkPath|$linkName]]`n"
            }
            $modified = $true
        }
    }

    if ($modified) {
        Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
        return $true
    }
    return $false
}

# Main processing
Write-Host "=== Cross-Topic File Linker ===" -ForegroundColor Cyan
Write-Host "Vault: $vaultPath" -ForegroundColor Gray
Write-Host ""

# Folders to skip
$skipFolders = @('00 - Journal', '09 - Kindle Clippings', '.trash', '05 - Templates', '.obsidian', '.smart-env', '00 - Images')

# Get all markdown files (excluding skip folders)
$allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $relativePath = $_.FullName.Replace($vaultPath + "\", "")
    $skip = $false
    foreach ($folder in $skipFolders) {
        if ($relativePath -match "^$([regex]::Escape($folder))") {
            $skip = $true
            break
        }
    }
    -not $skip
}

Write-Host "Total files to analyze: $($allFiles.Count)" -ForegroundColor White

# Build file content cache for faster analysis
$fileCache = @{}
foreach ($file in $allFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($content) {
        $relativePath = $file.FullName.Replace($vaultPath + "\", "")
        $fileCache[$file.FullName] = @{
            Name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            RelativePath = $relativePath
            Content = $content
        }
    }
}

Write-Host "Files cached: $($fileCache.Count)" -ForegroundColor Gray

# Process each cross-topic pattern
$totalCrosslinks = 0
$crosslinkResults = @()

foreach ($patternName in $crossTopicPatterns.Keys) {
    $pattern = $crossTopicPatterns[$patternName]
    Write-Host "`n=== Processing: $patternName ===" -ForegroundColor Yellow

    # Find files matching Topic1 and Topic2
    $topic1Files = @()
    $topic2Files = @()

    foreach ($filePath in $fileCache.Keys) {
        $fileData = $fileCache[$filePath]

        $topic1Score = Get-TopicRelevance -Content $fileData.Content -FileName $fileData.Name -Keywords $pattern.Topic1Keywords
        $topic2Score = Get-TopicRelevance -Content $fileData.Content -FileName $fileData.Name -Keywords $pattern.Topic2Keywords

        if ($topic1Score -gt 5) {
            $topic1Files += @{
                Path = $filePath
                Name = $fileData.Name
                RelativePath = $fileData.RelativePath
                Score = $topic1Score
                Topic2Score = $topic2Score
            }
        }

        if ($topic2Score -gt 5) {
            $topic2Files += @{
                Path = $filePath
                Name = $fileData.Name
                RelativePath = $fileData.RelativePath
                Score = $topic2Score
                Topic1Score = $topic1Score
            }
        }
    }

    Write-Host "  Topic1 files: $($topic1Files.Count), Topic2 files: $($topic2Files.Count)" -ForegroundColor Gray

    # Find files that bridge both topics (high score in both)
    $bridgeFiles = @()
    foreach ($file in $topic1Files) {
        if ($file.Topic2Score -gt 3) {
            $bridgeFiles += $file
        }
    }

    Write-Host "  Bridge files (both topics): $($bridgeFiles.Count)" -ForegroundColor Gray

    # Create crosslinks from Topic1 files to relevant Topic2 files
    foreach ($t1File in $topic1Files) {
        # Skip if it's a MOC file
        if ($t1File.Name -match '^MOC - ') { continue }

        # Find related Topic2 files (excluding self and MOCs)
        $relatedFiles = $topic2Files | Where-Object {
            $_.Path -ne $t1File.Path -and
            $_.Name -notmatch '^MOC - ' -and
            $_.Score -gt 8
        } | Sort-Object Score -Descending | Select-Object -First $MaxLinksPerFile

        if ($relatedFiles.Count -gt 0) {
            Write-Host "  [$($t1File.Name)] -> $($relatedFiles.Count) related files" -ForegroundColor Green

            if (-not $DryRun) {
                $linkResult = Add-CrossLinks -FilePath $t1File.Path -RelatedFiles $relatedFiles
                if ($linkResult) {
                    $totalCrosslinks += $relatedFiles.Count
                }
            }

            $crosslinkResults += @{
                Source = $t1File.Name
                Pattern = $patternName
                Targets = ($relatedFiles | ForEach-Object { $_.Name }) -join ", "
            }
        }
    }
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Cross-topic patterns processed: $($crossTopicPatterns.Count)" -ForegroundColor White
Write-Host "Crosslink relationships found: $($crosslinkResults.Count)" -ForegroundColor White
if (-not $DryRun) {
    Write-Host "Total crosslinks created: $totalCrosslinks" -ForegroundColor Green
}

# Output top crosslinks
Write-Host "`n=== Sample Crosslinks ===" -ForegroundColor Cyan
$crosslinkResults | Select-Object -First 20 | ForEach-Object {
    Write-Host "  $($_.Source) -> $($_.Targets)" -ForegroundColor Gray
}
