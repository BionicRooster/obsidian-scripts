# fix_moc_broken_links.ps1
# Finds broken wikilinks in MOC files and fixes them by locating the actual file
# A broken link is [[Some Note]] where "Some Note.md" doesn't exist, but a similar file does elsewhere

param(
    # Path to the Obsidian vault
    [string]$VaultPath = "D:\Obsidian\Main",

    # Actually apply fixes (otherwise dry run)
    [switch]$Fix,

    # Show only broken links without searching for matches
    [switch]$ScanOnly
)

Write-Host "=== MOC Broken Link Fixer ===" -ForegroundColor Cyan
Write-Host "Vault: $VaultPath"
Write-Host "Mode: $(if ($Fix) { 'FIX' } elseif ($ScanOnly) { 'SCAN ONLY' } else { 'DRY RUN' })"
Write-Host ""

# Build index of all markdown files
# Key: lowercase base name (without .md), Value: full path
Write-Host "Building note index..." -ForegroundColor Gray
$noteIndex = @{}        # lowercase base name -> full file path
$noteNames = @{}        # lowercase base name -> actual base name (proper casing)
$notesByPartial = @{}   # partial name lookups for fuzzy matching

$allMdFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike "*\.obsidian*" }

foreach ($file in $allMdFiles) {
    # Get the base name without .md extension
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $key = $baseName.ToLower()

    # Store first occurrence, prefer files in 20 - Permanent Notes
    if (-not $noteIndex.ContainsKey($key) -or $file.FullName -like "*20 - Permanent Notes*") {
        $noteIndex[$key] = $file.FullName
        $noteNames[$key] = $baseName
    }

    # Build partial name index for fuzzy matching
    # Store all words longer than 3 chars
    $words = $baseName -split '\s+' | Where-Object { $_.Length -gt 3 }
    foreach ($word in $words) {
        $wordLower = $word.ToLower()
        if (-not $notesByPartial.ContainsKey($wordLower)) {
            $notesByPartial[$wordLower] = @()
        }
        $notesByPartial[$wordLower] += @{
            BaseName = $baseName
            FullPath = $file.FullName
        }
    }
}

Write-Host "Indexed $($noteIndex.Count) notes" -ForegroundColor Gray

# Function to find a matching file for a broken link
function Find-MatchingNote {
    param([string]$LinkName)

    $searchLower = $LinkName.ToLower().Trim()

    # Strategy 1: Exact match (case insensitive)
    if ($noteIndex.ContainsKey($searchLower)) {
        return @{
            BaseName = $noteNames[$searchLower]
            MatchType = "Exact"
            Score = 100
        }
    }

    # Strategy 2: Match with trimmed whitespace variations
    $trimmed = $searchLower -replace '\s+', ' '
    if ($noteIndex.ContainsKey($trimmed)) {
        return @{
            BaseName = $noteNames[$trimmed]
            MatchType = "Trimmed"
            Score = 95
        }
    }

    # Strategy 3: Match ignoring smart apostrophes vs straight apostrophes
    $apostropheNormalized = $searchLower -replace [char]0x2019, "'"
    $apostropheNormalized = $apostropheNormalized -replace [char]0x2018, "'"
    if ($noteIndex.ContainsKey($apostropheNormalized)) {
        return @{
            BaseName = $noteNames[$apostropheNormalized]
            MatchType = "Apostrophe"
            Score = 90
        }
    }

    # Strategy 4: Search for partial matches
    $bestMatch = $null
    $bestScore = 0

    foreach ($key in $noteIndex.Keys) {
        $noteName = $noteNames[$key]
        $noteLower = $key

        # Skip very short names
        if ($noteLower.Length -lt 5) { continue }

        $score = 0

        # Check if link starts with note name (truncated link)
        if ($searchLower -like "$noteLower*") {
            $score = 80 + ($noteLower.Length / $searchLower.Length * 15)
        }
        # Check if note starts with link name
        elseif ($noteLower -like "$searchLower*") {
            $score = 75 + ($searchLower.Length / $noteLower.Length * 15)
        }
        # Check if note contains link name
        elseif ($noteLower -like "*$searchLower*") {
            $score = 70 + ($searchLower.Length / $noteLower.Length * 15)
        }
        # Check if link contains note name
        elseif ($searchLower -like "*$noteLower*") {
            $score = 65 + ($noteLower.Length / $searchLower.Length * 15)
        }
        # Word overlap matching
        else {
            $searchWords = $searchLower -split '\s+' | Where-Object { $_.Length -gt 2 }
            $noteWords = $noteLower -split '\s+' | Where-Object { $_.Length -gt 2 }

            if ($searchWords.Count -gt 0 -and $noteWords.Count -gt 0) {
                $matchCount = 0
                foreach ($sw in $searchWords) {
                    foreach ($nw in $noteWords) {
                        # Exact word match or prefix match
                        if ($sw -eq $nw -or $sw -like "$nw*" -or $nw -like "$sw*") {
                            $matchCount++
                            break
                        }
                    }
                }

                # Need significant word overlap
                $minRequired = [Math]::Max(2, [Math]::Ceiling($searchWords.Count * 0.5))
                if ($matchCount -ge $minRequired) {
                    $score = 50 + ($matchCount / [Math]::Max($searchWords.Count, $noteWords.Count) * 30)
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

    # Only return if score is good enough
    if ($bestScore -ge 60) {
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
# Matches [[Note Name]] or [[Note Name|Display Text]] or [[Note Name#Heading]]
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
        # Extract the link target (note name)
        $linkTarget = $match.Groups[1].Value.Trim()
        $fullMatch = $match.Value

        # Check if this note exists
        $linkLower = $linkTarget.ToLower()
        $noteExists = $noteIndex.ContainsKey($linkLower)

        # Also check with apostrophe normalization
        if (-not $noteExists) {
            $normalized = $linkLower -replace [char]0x2019, "'"
            $normalized = $normalized -replace [char]0x2018, "'"
            $noteExists = $noteIndex.ContainsKey($normalized)
        }

        if (-not $noteExists) {
            # This is a broken link!
            $totalBrokenLinks++

            Write-Host "  BROKEN: $fullMatch" -ForegroundColor Red

            if (-not $ScanOnly) {
                # Try to find a matching file
                $matchResult = Find-MatchingNote -LinkName $linkTarget

                if ($matchResult) {
                    $totalFixable++
                    $correctName = $matchResult.BaseName
                    $matchType = $matchResult.MatchType
                    $score = $matchResult.Score

                    Write-Host "    -> MATCH ($matchType, score $score): [[$correctName]]" -ForegroundColor Green

                    # Build the replacement
                    # If original had |display text, preserve it
                    if ($fullMatch -match '\[\[[^\]|]+\|([^\]]+)\]\]') {
                        $displayText = $Matches[1]
                        $replacement = "[[$correctName|$displayText]]"
                    }
                    # If original had #heading, preserve it
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
                    Write-Host "    -> NO MATCH FOUND" -ForegroundColor DarkYellow

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

    # Apply fixes if in Fix mode
    if ($Fix -and $fileChanges.Count -gt 0) {
        $newContent = $content

        foreach ($change in $fileChanges) {
            # Use exact string replacement to avoid regex issues
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

if ($brokenLinksList.Count -gt 0) {
    Write-Host "Broken links details:" -ForegroundColor Yellow
    $brokenLinksList | Format-Table -AutoSize
}

if (-not $Fix -and $totalFixable -gt 0) {
    Write-Host ""
    Write-Host "Run with -Fix to apply changes" -ForegroundColor Yellow
}
