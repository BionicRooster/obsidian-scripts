<#
.SYNOPSIS
    Converts inline hashtags in Obsidian markdown files to YAML frontmatter tags.

.DESCRIPTION
    Scans .md files in the vault, finds inline #tags in the body,
    merges them into YAML frontmatter tags, and removes inline occurrences.
    Handles existing YAML, missing YAML, body `tags: [X]` markers, etc.

.PARAMETER WhatIf
    Preview mode - shows what would change without modifying files.

.PARAMETER Apply
    Actually apply changes to files.

.PARAMETER Limit
    Max number of files to process (0 = unlimited).

.EXAMPLE
    .\convert_inline_tags.ps1 -WhatIf
    .\convert_inline_tags.ps1 -Apply
    .\convert_inline_tags.ps1 -Apply -Limit 10
#>
param(
    [switch]$WhatIf,    # Preview mode - no files modified
    [switch]$Apply,     # Apply mode - files are modified
    [int]$Limit = 0     # Max files to process (0 = all)
)

# Require exactly one mode
if (-not $WhatIf -and -not $Apply) {
    Write-Host "ERROR: Specify -WhatIf or -Apply" -ForegroundColor Red
    exit 1
}

# Vault root path
$vaultRoot = "D:\Obsidian\Main"

# Folders to exclude from processing
$excludeFolders = @(
    "00 - Journal",
    "09 - Kindle Clippings",
    "13 - People",
    "Templates"
)

# Specific files to exclude
$excludeFiles = @(
    "To-Do List.md",
    "MOC Subsections and Keywords.md",      # Tag reference file - not real inline tags
    "MOC Subsection Tags Reference.md"      # Tag reference file - not real inline tags
)

# Tags that are false positives (too short, common words, social share buttons, etc.)
# Minimum tag length: 2 characters
$minTagLength = 2

# Short tags (2 chars) that ARE valid and should be kept (lowercase)
$validShortTags = @(
    'ai', 'rv', 'tv', 'hp', 'pc', 'uk', 'us', 'eu', 'dc', 'db', 'os', 'it'
)

# Explicit false-positive tags to ignore (lowercase)
$falsePositiveTags = @(
    'the', 'tab', 'define', 'bp', 'sms', 'email', 'print', 'top',
    'via', 'new', 'all', 'get', 'set', 'let', 'var', 'end', 'add',
    'run', 'use', 'map', 'key', 'log', 'not', 'and', 'for', 'but',
    'has', 'was', 'are', 'its', 'can', 'did', 'had', 'his', 'her',
    'how', 'may', 'our', 'own', 'say', 'she', 'too', 'who', 'why',
    'yes', 'yet', 'day', 'way', 'man', 'old', 'see', 'now', 'one',
    'two', 'big', 'got', 'put', 'try', 'ask', 'few', 'ago', 'red',
    'sub', 'raw', 'ref', 'src', 'img', 'div', 'btn', 'nav', 'pre'
)

# Counters for summary
$filesProcessed = 0   # Total files scanned
$filesModified = 0    # Files that had changes
$totalTagsFound = 0   # Total inline tags discovered
$totalBodyMarkers = 0 # Total body `tags: [X]` markers found

# Get all .md files, excluding specified folders and .resources dirs
$allFiles = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" | Where-Object {
    $relativePath = $_.FullName.Substring($vaultRoot.Length + 1)

    # Check folder exclusions
    $excluded = $false
    foreach ($folder in $excludeFolders) {
        if ($relativePath -like "$folder\*" -or $relativePath -like "$folder/*") {
            $excluded = $true
            break
        }
    }
    # Check .resources folder exclusion
    if ($relativePath -match '[\\/]\.resources[\\/]') { $excluded = $true }
    if ($relativePath -like ".resources\*" -or $relativePath -like ".resources/*") { $excluded = $true }

    # Check specific file exclusions
    if ($_.Name -in $excludeFiles) { $excluded = $true }

    -not $excluded
}

# Apply limit if specified
if ($Limit -gt 0) {
    $allFiles = $allFiles | Select-Object -First $Limit
}

Write-Host "Found $($allFiles.Count) files to scan." -ForegroundColor Cyan

foreach ($file in $allFiles) {
    $filesProcessed++

    # Read file content as UTF-8 (preserving encoding)
    $rawContent = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $lines = $rawContent -split "`r?`n"

    # --- STEP 1: Parse existing YAML frontmatter ---
    $hasYaml = $false          # Whether file has YAML frontmatter
    $yamlStart = -1            # Line index of opening ---
    $yamlEnd = -1              # Line index of closing ---
    $existingTags = @()        # Tags already in YAML
    $yamlTagsLineStart = -1   # First line of tags in YAML
    $yamlTagsLineEnd = -1     # Last line of tags in YAML
    $yamlIsMalformed = $false # Whether existing YAML tags need reformatting

    # Check if first non-empty line is ---
    for ($i = 0; $i -lt $lines.Count; $i++) {
        # Skip BOM or empty lines at very start
        $trimmed = $lines[$i].Trim()
        # Strip UTF-8 BOM if present
        if ($trimmed.Length -gt 0 -and $trimmed[0] -eq [char]0xFEFF) { $trimmed = $trimmed.Substring(1) }
        if ($trimmed -eq '---') {
            $yamlStart = $i
            # Find closing ---
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j].Trim() -eq '---') {
                    $yamlEnd = $j
                    $hasYaml = $true
                    break
                }
            }
            break
        } elseif ($trimmed -ne '') {
            break  # First non-empty line is not ---, no YAML
        }
    }

    # Parse existing tags from YAML if present
    if ($hasYaml) {
        for ($i = $yamlStart + 1; $i -lt $yamlEnd; $i++) {
            $line = $lines[$i]
            # Match `tags:` key
            if ($line -match '^\s*tags\s*:') {
                $yamlTagsLineStart = $i
                # Check for bracket format: tags: [tag1, tag2]
                if ($line -match '^\s*tags\s*:\s*\[([^\]]*)\]') {
                    $bracketContent = $Matches[1]
                    $existingTags = @($bracketContent -split '\s*,\s*' | ForEach-Object {
                        $_.Trim().Trim('"').Trim("'") -replace '\[\[|\]\]', ''  # Strip [[wikilink]] brackets
                    } | Where-Object { $_ -ne '' })
                    $yamlTagsLineEnd = $i
                    $yamlIsMalformed = $true  # Bracket format needs normalization to list format
                }
                # Check for malformed "tags: - val1 - val2" or "tags: - - val" (dashes on same line)
                elseif ($line -match '^\s*tags\s*:\s*-\s+') {
                    # Extract everything after "tags:" and split on " - " boundaries
                    $rawTagsPart = $line -replace '^\s*tags\s*:\s*', ''
                    # Split on " - " pattern, then split each token on spaces, then clean
                    $tokens = $rawTagsPart -split '\s*-\s+' | ForEach-Object {
                        $_.Trim().Trim('"').Trim("'") -replace '\[\[|\]\]', ''  # Strip [[wikilink]] brackets
                    } | Where-Object { $_ -ne '' } | ForEach-Object {
                        # Further split space-separated values (e.g., "permaculture science" -> two tags)
                        $_ -split '\s+' | Where-Object { $_ -ne '' }
                    }
                    $existingTags = @($tokens)
                    $yamlTagsLineEnd = $i
                    $yamlIsMalformed = $true  # Flag to force rewrite
                }
                # Check for inline single value: tags: sometag
                elseif ($line -match '^\s*tags\s*:\s+(\S.*)$') {
                    $val = $Matches[1].Trim().Trim('"').Trim("'") -replace '\[\[|\]\]', ''
                    if ($val -ne '' -and $val -ne '[]') {
                        # Could be space-separated tags like "tags: permaculture science"
                        $existingTags = @($val -split '\s+' | Where-Object { $_ -ne '' })
                    }
                    $yamlTagsLineEnd = $i
                    $yamlIsMalformed = $true  # Inline format needs normalization to list format
                }
                else {
                    # List format: tags: followed by   - items
                    $yamlTagsLineEnd = $i
                    for ($k = $i + 1; $k -lt $yamlEnd; $k++) {
                        if ($lines[$k] -match '^\s*-\s+(.+)$') {
                            $tagVal = $Matches[1].Trim().Trim('"').Trim("'") -replace '\[\[|\]\]', ''  # Strip all [[wikilink]] brackets
                            $existingTags += $tagVal
                            $yamlTagsLineEnd = $k
                        } elseif ($lines[$k].Trim() -eq '') {
                            continue  # Skip blank lines within YAML tags block
                        } else {
                            break
                        }
                    }
                }
                break
            }
        }
    }

    # --- STEP 2: Find inline tags in body ---
    # Determine where body starts (after YAML or from line 0)
    $bodyStart = if ($hasYaml) { $yamlEnd + 1 } else { 0 }

    # Collect inline tags and track which lines have them
    $inlineTags = @()           # All inline tags found
    $lineModifications = @{}    # line index -> modified line text
    $bodyMarkerLines = @()      # lines with `tags: [X]` body markers

    # Regex for inline hashtags: #TagName (must start with letter, not preceded by & or word char)
    $tagRegex = '(?<![&\w])#([A-Za-z\u00C0-\u00FF][A-Za-z0-9_/\u00C0-\u00FF]*)'

    for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $modified = $line
        $foundOnLine = @()

        # Skip lines that are markdown headings (## Heading)
        if ($line -match '^\s*#{1,6}\s+') { continue }

        # Skip checklist lines (preserve #task and any other tags on checklists)
        if ($line -match '^\s*-\s*\[[ x]\]') { continue }

        # Skip lines inside code blocks (``` fenced blocks)
        # Simple approach: skip lines that look like they're in code
        if ($line -match '^\s*```') { continue }

        # Skip HTML comment lines
        if ($line -match '^\s*<!--') { continue }

        # Skip lines that are URLs or image embeds with fragment identifiers
        if ($line -match '^\s*!\[') { continue }

        # Handle body `tags: [X]` markers (not in YAML)
        if ($line -match '^\s*tags\s*:\s*\[([^\]]*)\]') {
            $markerTags = @($Matches[1] -split '\s*,\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ -ne '' })
            # Validate each marker tag against false positive list
            $validMarkerTags = @()
            foreach ($mt in $markerTags) {
                if (($mt.Length -ge 3 -or $mt.ToLower() -in $validShortTags) -and $mt.ToLower() -notin $falsePositiveTags) {
                    $validMarkerTags += $mt
                }
            }
            if ($validMarkerTags.Count -gt 0) {
                $inlineTags += $validMarkerTags
                $bodyMarkerLines += $i
                $totalBodyMarkers++
            }
            continue
        }

        # Find all #tag occurrences on this line
        $matches_found = [regex]::Matches($line, $tagRegex)
        if ($matches_found.Count -gt 0) {
            foreach ($m in $matches_found) {
                $tagName = $m.Groups[1].Value

                # Skip numeric-only matches (HTML entities like &#123;)
                if ($tagName -match '^\d+$') { continue }

                # Skip tags shorter than 3 chars unless in the valid short tags allowlist
                if ($tagName.Length -lt 3 -and $tagName.ToLower() -notin $validShortTags) { continue }

                # Skip known false positives
                if ($tagName.ToLower() -in $falsePositiveTags) { continue }

                # Skip if followed by [[ (wikilink pattern like #[[Link]])
                $afterPos = $m.Index + $m.Length
                if ($afterPos + 1 -lt $line.Length -and $line.Substring($afterPos, 2) -eq '[[') {
                    continue
                }

                # Skip tags inside URLs (check if preceded by common URL patterns)
                $beforeStr = if ($m.Index -gt 0) { $line.Substring(0, $m.Index) } else { '' }
                if ($beforeStr -match 'https?://\S*$' -or $beforeStr -match '\]\([^\)]*$') {
                    continue
                }

                $foundOnLine += $tagName
            }

            if ($foundOnLine.Count -gt 0) {
                # Remove inline tags from the line
                foreach ($tag in $foundOnLine) {
                    # Remove #tag with optional trailing space; match only when not part of larger word
                    $modified = $modified -replace "(?<![&\w])#$([regex]::Escape($tag))(?=\s|$|[,;.\)\]\}])", ''
                }
                # Clean up multiple spaces left behind
                $modified = $modified -replace '  +', ' '
                $modified = $modified.TrimEnd()

                $lineModifications[$i] = $modified
                $inlineTags += $foundOnLine
            }
        }
    }

    # Skip files with no inline tags found AND no malformed YAML to fix
    if ($inlineTags.Count -eq 0 -and $bodyMarkerLines.Count -eq 0 -and -not $yamlIsMalformed) { continue }

    $totalTagsFound += $inlineTags.Count

    # --- STEP 3: Deduplicate tags (case-insensitive, keep first casing) ---
    $seenLower = @{}        # Track lowercase versions already seen
    $uniqueNewTags = @()    # New tags not already in YAML

    # Build set of existing tags (lowercase) for dedup
    $existingLower = @{}
    foreach ($t in $existingTags) {
        $existingLower[$t.ToLower()] = $true
    }

    foreach ($tag in $inlineTags) {
        $lower = $tag.ToLower()
        if (-not $existingLower.ContainsKey($lower) -and -not $seenLower.ContainsKey($lower)) {
            $seenLower[$lower] = $true
            $uniqueNewTags += $tag
        }
    }

    # --- STEP 4: Build new file content ---
    $newLines = [System.Collections.Generic.List[string]]::new()

    # Merge all tags (existing + new)
    $allTags = @()
    $allTags += $existingTags
    $allTags += $uniqueNewTags

    # Deduplicate allTags case-insensitively (keep first occurrence)
    $dedupSeen = @{}
    $dedupTags = @()
    foreach ($t in $allTags) {
        $lower = $t.ToLower()
        if (-not $dedupSeen.ContainsKey($lower)) {
            $dedupSeen[$lower] = $true
            $dedupTags += $t
        }
    }
    $allTags = $dedupTags

    # Build the tags YAML block as lines
    $tagsYamlLines = @("tags:")
    foreach ($t in $allTags) {
        $tagsYamlLines += "  - $t"
    }

    if ($hasYaml) {
        # File has existing YAML - modify it
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -ge $yamlStart -and $i -le $yamlEnd) {
                # Inside YAML block (including delimiters)
                if ($i -eq $yamlStart -or $i -eq $yamlEnd) {
                    # Keep --- delimiters
                    $newLines.Add($lines[$i])
                    # If closing delimiter and no tags key existed, insert tags before it
                    if ($i -eq $yamlEnd -and $yamlTagsLineStart -lt 0) {
                        # Remove the closing --- we just added, insert tags, re-add ---
                        $newLines.RemoveAt($newLines.Count - 1)
                        foreach ($tl in $tagsYamlLines) {
                            $newLines.Add($tl)
                        }
                        $newLines.Add($lines[$i])  # Re-add closing ---
                    }
                }
                elseif ($yamlTagsLineStart -ge 0 -and $i -ge $yamlTagsLineStart -and $i -le $yamlTagsLineEnd) {
                    # Replace existing tags block with merged version
                    if ($i -eq $yamlTagsLineStart) {
                        foreach ($tl in $tagsYamlLines) {
                            $newLines.Add($tl)
                        }
                    }
                    # Skip other lines of old tags block (they're replaced)
                } else {
                    $newLines.Add($lines[$i])
                }
            }
            elseif ($i -in $bodyMarkerLines) {
                # Skip body `tags: [X]` marker lines entirely
                continue
            }
            elseif ($lineModifications.ContainsKey($i)) {
                $modLine = $lineModifications[$i]
                # Only add if line isn't empty after tag removal
                if ($modLine.Trim() -ne '') {
                    $newLines.Add($modLine)
                }
                # If line became empty after removing tags, skip it
            }
            else {
                $newLines.Add($lines[$i])
            }
        }
    }
    else {
        # No YAML frontmatter - need to create one
        # Check if file starts with # Title within first 5 lines
        $titleLineIdx = -1
        for ($i = 0; $i -lt [Math]::Min(5, $lines.Count); $i++) {
            if ($lines[$i] -match '^#\s+\S') {
                $titleLineIdx = $i
                break
            }
        }

        if ($titleLineIdx -ge 0) {
            # Add lines before title
            for ($i = 0; $i -lt $titleLineIdx; $i++) {
                if ($i -in $bodyMarkerLines) { continue }
                if ($lineModifications.ContainsKey($i)) {
                    $mod = $lineModifications[$i]
                    if ($mod.Trim() -ne '') { $newLines.Add($mod) }
                } else {
                    $newLines.Add($lines[$i])
                }
            }
            # Add the title line (with inline tag removal if needed)
            if ($lineModifications.ContainsKey($titleLineIdx)) {
                $newLines.Add($lineModifications[$titleLineIdx])
            } else {
                $newLines.Add($lines[$titleLineIdx])
            }
            # Insert YAML block after title
            $newLines.Add("---")
            foreach ($tl in $tagsYamlLines) { $newLines.Add($tl) }
            $newLines.Add("---")
            # Add rest of body
            for ($i = $titleLineIdx + 1; $i -lt $lines.Count; $i++) {
                if ($i -in $bodyMarkerLines) { continue }
                if ($lineModifications.ContainsKey($i)) {
                    $mod = $lineModifications[$i]
                    if ($mod.Trim() -ne '') { $newLines.Add($mod) }
                } else {
                    $newLines.Add($lines[$i])
                }
            }
        }
        else {
            # No title line - insert YAML at top
            $newLines.Add("---")
            foreach ($tl in $tagsYamlLines) { $newLines.Add($tl) }
            $newLines.Add("---")
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($i -in $bodyMarkerLines) { continue }
                if ($lineModifications.ContainsKey($i)) {
                    $mod = $lineModifications[$i]
                    if ($mod.Trim() -ne '') { $newLines.Add($mod) }
                } else {
                    $newLines.Add($lines[$i])
                }
            }
        }
    }

    # --- STEP 5: Write or preview ---
    $relativePath = $file.FullName.Substring($vaultRoot.Length + 1)
    $filesModified++

    if ($WhatIf) {
        Write-Host "`n--- $relativePath ---" -ForegroundColor Yellow
        Write-Host "  Inline tags found: $($inlineTags -join ', ')" -ForegroundColor White
        Write-Host "  New tags to add:   $($uniqueNewTags -join ', ')" -ForegroundColor Green
        if ($bodyMarkerLines.Count -gt 0) {
            Write-Host "  Body markers removed: $($bodyMarkerLines.Count)" -ForegroundColor Magenta
        }
        Write-Host "  Final YAML tags:   $($allTags -join ', ')" -ForegroundColor Cyan
    }
    else {
        # Write modified content back to file with UTF-8 (no BOM)
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $newContent = $newLines -join "`r`n"
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)

        Write-Host "UPDATED: $relativePath  |  Tags: $($allTags -join ', ')" -ForegroundColor Green
    }
}

# --- Summary ---
Write-Host "`n========== SUMMARY ==========" -ForegroundColor Cyan
Write-Host "Files scanned:    $filesProcessed"
Write-Host "Files modified:   $filesModified"
Write-Host "Inline tags found: $totalTagsFound"
Write-Host "Body markers found: $totalBodyMarkers"
if ($WhatIf) {
    Write-Host "`nThis was a DRY RUN. Use -Apply to make changes." -ForegroundColor Yellow
}
