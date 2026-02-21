# fix_moc_broken_links_v2.ps1
# Finds broken wikilinks in MOC files and fixes them by locating the actual file
# Improved version: extracts filename from paths and avoids matching to folder indexes

param(
    # Path to the Obsidian vault
    [string]$VaultPath = "D:\Obsidian\Main",

    # Actually apply fixes (otherwise dry run)
    [switch]$Fix,

    # Show only broken links without searching for matches
    [switch]$ScanOnly,

    # Minimum match score required (0-100)
    [int]$MinScore = 70
)

Write-Host "=== MOC Broken Link Fixer v2 ===" -ForegroundColor Cyan
Write-Host "Vault: $VaultPath"
Write-Host "Mode: $(if ($Fix) { 'FIX' } elseif ($ScanOnly) { 'SCAN ONLY' } else { 'DRY RUN' })"
Write-Host "Min Score: $MinScore"
Write-Host ""

# Build index of all markdown files
Write-Host "Building note index..." -ForegroundColor Gray
$noteIndex = @{}        # lowercase base name -> full file path
$noteNames = @{}        # lowercase base name -> actual base name (proper casing)
$folderIndexes = @{}    # Track files that are folder indexes (to deprioritize)

$allMdFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike "*\.obsidian*" }

foreach ($file in $allMdFiles) {
    # Get the base name without .md extension
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $key = $baseName.ToLower()

    # Check if this is a folder index file (name matches parent folder)
    $parentFolder = Split-Path $file.DirectoryName -Leaf
    $isFolderIndex = ($baseName -eq $parentFolder) -or
                     ($baseName -like "00 - *") -or
                     ($baseName -like "* - Indexes*") -or
                     ($baseName -match '^\d{2} - ')

    if ($isFolderIndex) {
        $folderIndexes[$key] = $true
    }

    # Store first occurrence, prefer non-folder-indexes and 20 - Permanent Notes
    $shouldStore = $false
    if (-not $noteIndex.ContainsKey($key)) {
        $shouldStore = $true
    } elseif ($file.FullName -like "*20 - Permanent Notes*" -and -not $folderIndexes[$key]) {
        $shouldStore = $true
    } elseif ($folderIndexes[$key] -and -not ($file.FullName -like "*20 - Permanent Notes*")) {
        # Don't overwrite with a folder index unless it's a Permanent Note
        $shouldStore = $false
    }

    if ($shouldStore) {
        $noteIndex[$key] = $file.FullName
        $noteNames[$key] = $baseName
    }
}

Write-Host "Indexed $($noteIndex.Count) notes" -ForegroundColor Gray

# Function to normalize a string for matching
function Normalize-String {
    param([string]$Text)

    $result = $Text.ToLower().Trim()
    # Normalize apostrophes
    $result = $result -replace [char]0x2019, "'"
    $result = $result -replace [char]0x2018, "'"
    # Remove trailing underscores and numbers like _1
    $result = $result -replace '_\d+$', ''
    $result = $result -replace '\s+', ' '
    return $result
}

# Function to extract just the filename from a path-like link
function Get-LinkFileName {
    param([string]$LinkTarget)

    # If it contains a /, extract the last part (the filename)
    if ($LinkTarget -match '/') {
        $parts = $LinkTarget -split '/'
        return $parts[-1].Trim()
    }
    return $LinkTarget.Trim()
}

# Function to find a matching file for a broken link
function Find-MatchingNote {
    param([string]$LinkTarget)

    # Extract just the filename part if the link contains a path
    $fileName = Get-LinkFileName -LinkTarget $LinkTarget
    $fileNameNorm = Normalize-String -Text $fileName

    # Also try the full link as-is
    $fullLinkNorm = Normalize-String -Text $LinkTarget

    # Strategy 1: Exact match on filename
    if ($noteIndex.ContainsKey($fileNameNorm)) {
        # Don't return folder indexes for exact matches unless nothing else
        if (-not $folderIndexes[$fileNameNorm]) {
            return @{
                BaseName = $noteNames[$fileNameNorm]
                MatchType = "Exact"
                Score = 100
            }
        }
    }

    # Strategy 2: Exact match on full link (without path)
    if ($noteIndex.ContainsKey($fullLinkNorm)) {
        if (-not $folderIndexes[$fullLinkNorm]) {
            return @{
                BaseName = $noteNames[$fullLinkNorm]
                MatchType = "Exact-Full"
                Score = 98
            }
        }
    }

    # Strategy 3: Match with _1 suffix removed (for duplicates)
    $withoutSuffix = $fileNameNorm -replace '\s*1$', ''
    $withoutSuffix = $withoutSuffix.Trim()
    if ($withoutSuffix -ne $fileNameNorm -and $noteIndex.ContainsKey($withoutSuffix)) {
        if (-not $folderIndexes[$withoutSuffix]) {
            return @{
                BaseName = $noteNames[$withoutSuffix]
                MatchType = "No-Suffix"
                Score = 95
            }
        }
    }

    # Strategy 4: Match truncated names (file was truncated in link)
    $bestMatch = $null
    $bestScore = 0

    foreach ($key in $noteIndex.Keys) {
        # Skip folder indexes in fuzzy matching
        if ($folderIndexes[$key]) { continue }

        $noteName = $noteNames[$key]
        $noteLower = $key

        # Skip very short names that could match too broadly
        if ($noteLower.Length -lt 8) { continue }

        $score = 0

        # Check if the filename is a prefix of the note name (truncated link)
        # e.g., "Is Cordwood Masonry" -> "Is Cordwood Masonry Right for You"
        if ($noteLower.StartsWith($fileNameNorm) -and $fileNameNorm.Length -ge 15) {
            $matchRatio = $fileNameNorm.Length / $noteLower.Length
            if ($matchRatio -ge 0.5) {
                $score = 85 + ($matchRatio * 10)
            }
        }
        # Check if note name is prefix of filename
        elseif ($fileNameNorm.StartsWith($noteLower) -and $noteLower.Length -ge 15) {
            $matchRatio = $noteLower.Length / $fileNameNorm.Length
            if ($matchRatio -ge 0.5) {
                $score = 80 + ($matchRatio * 10)
            }
        }

        # Word-based matching for longer names
        if ($score -eq 0 -and $fileNameNorm.Length -ge 20) {
            $searchWords = $fileNameNorm -split '\s+' | Where-Object { $_.Length -gt 3 }
            $noteWords = $noteLower -split '\s+' | Where-Object { $_.Length -gt 3 }

            if ($searchWords.Count -ge 3 -and $noteWords.Count -ge 3) {
                $matchCount = 0
                foreach ($sw in $searchWords) {
                    foreach ($nw in $noteWords) {
                        if ($sw -eq $nw) {
                            $matchCount++
                            break
                        }
                    }
                }

                # Require at least 3 matching words
                if ($matchCount -ge 3) {
                    $matchRatio = $matchCount / [Math]::Max($searchWords.Count, $noteWords.Count)
                    $score = 60 + ($matchRatio * 30)
                }
            }
        }

        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestMatch = @{
                BaseName = $noteName
                MatchType = "Fuzzy"
                Score = [Math]::Round($score)
            }
        }
    }

    # Only return if score meets minimum threshold
    if ($bestScore -ge $MinScore) {
        return $bestMatch
    }

    return $null
}

# Find MOC files
$mocFolder = Join-Path $VaultPath "00 - Home Dashboard"
$mocFiles = Get-ChildItem -Path $mocFolder -Filter "*MOC*.md" -File -ErrorAction SilentlyContinue

# Also include Master MOC Index
$masterMoc = Get-Item -Path (Join-Path $mocFolder "Master MOC Index.md") -ErrorAction SilentlyContinue
if ($masterMoc) {
    $mocFiles = @($masterMoc) + @($mocFiles)
}

Write-Host "Found $($mocFiles.Count) MOC files to scan" -ForegroundColor Gray
Write-Host ""

# Regex pattern to match wikilinks (not image embeds)
$wikiLinkPattern = '(?<!!)\[\[([^\]|#]+)(?:[#|][^\]]+)?\]\]'

# Track statistics
$totalBrokenLinks = 0
$totalFixable = 0
$totalFixed = 0
$brokenLinksList = @()

foreach ($mocFile in $mocFiles) {
    $mocName = $mocFile.Name
    Write-Host "Scanning: $mocName" -ForegroundColor Yellow

    try {
        $content = Get-Content -Path $mocFile.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        if (-not $content) {
            Write-Host "  (empty file)" -ForegroundColor Gray
            continue
        }
    } catch {
        Write-Host "  ERROR: Could not read file - $_" -ForegroundColor Red
        continue
    }

    $originalContent = $content
    $fileChanges = @()

    # Find all wikilinks in this MOC
    $matches = [regex]::Matches($content, $wikiLinkPattern)

    foreach ($match in $matches) {
        $linkTarget = $match.Groups[1].Value.Trim()
        $fullMatch = $match.Value

        # Normalize for checking existence
        $linkNorm = Normalize-String -Text $linkTarget
        $fileNameNorm = Normalize-String -Text (Get-LinkFileName -LinkTarget $linkTarget)

        # Check if this note exists (by full link or just filename)
        $noteExists = $noteIndex.ContainsKey($linkNorm) -or $noteIndex.ContainsKey($fileNameNorm)

        if (-not $noteExists) {
            $totalBrokenLinks++

            Write-Host "  BROKEN: $fullMatch" -ForegroundColor Red

            if (-not $ScanOnly) {
                $matchResult = Find-MatchingNote -LinkTarget $linkTarget

                if ($matchResult) {
                    $totalFixable++
                    $correctName = $matchResult.BaseName
                    $matchType = $matchResult.MatchType
                    $score = $matchResult.Score

                    Write-Host "    -> MATCH ($matchType, score $score): [[$correctName]]" -ForegroundColor Green

                    # Build replacement, preserving display text or heading if present
                    if ($fullMatch -match '\[\[[^\]|]+\|([^\]]+)\]\]') {
                        $displayText = $Matches[1]
                        $replacement = "[[$correctName|$displayText]]"
                    }
                    elseif ($fullMatch -match '\[\[[^\]#]+#([^\]]+)\]\]') {
                        $heading = $Matches[1]
                        $replacement = "[[$correctName#$heading]]"
                    }
                    else {
                        $replacement = "[[$correctName]]"
                    }

                    $fileChanges += @{
                        Original = $fullMatch
                        Replacement = $replacement
                        LinkTarget = $linkTarget
                        CorrectName = $correctName
                    }

                    $brokenLinksList += [PSCustomObject]@{
                        MOC = $mocName
                        BrokenLink = $linkTarget
                        FoundMatch = $correctName
                        MatchType = $matchType
                        Score = $score
                    }
                } else {
                    Write-Host "    -> NO MATCH FOUND (score < $MinScore)" -ForegroundColor DarkYellow

                    $brokenLinksList += [PSCustomObject]@{
                        MOC = $mocName
                        BrokenLink = $linkTarget
                        FoundMatch = "(none)"
                        MatchType = "-"
                        Score = 0
                    }
                }
            }
        }
    }

    # Apply fixes
    if ($Fix -and $fileChanges.Count -gt 0) {
        $newContent = $content

        foreach ($change in $fileChanges) {
            $newContent = $newContent.Replace($change.Original, $change.Replacement)
        }

        if ($newContent -ne $originalContent) {
            Set-Content -Path $mocFile.FullName -Value $newContent -Encoding UTF8 -NoNewline
            $totalFixed += $fileChanges.Count
            Write-Host "  FIXED: $($fileChanges.Count) links" -ForegroundColor Green
        }
    }

    Write-Host ""
}

# Summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total broken links found: $totalBrokenLinks" -ForegroundColor $(if ($totalBrokenLinks -gt 0) { 'Red' } else { 'Green' })
Write-Host "Links with matches found: $totalFixable" -ForegroundColor $(if ($totalFixable -gt 0) { 'Yellow' } else { 'Gray' })
Write-Host "Links fixed:              $totalFixed" -ForegroundColor $(if ($totalFixed -gt 0) { 'Green' } else { 'Gray' })
Write-Host ""

if ($brokenLinksList.Count -gt 0 -and $brokenLinksList.Count -le 100) {
    Write-Host "Broken links details:" -ForegroundColor Yellow
    $brokenLinksList | Format-Table -AutoSize
}

if (-not $Fix -and $totalFixable -gt 0) {
    Write-Host ""
    Write-Host "Run with -Fix to apply changes" -ForegroundColor Yellow
}
