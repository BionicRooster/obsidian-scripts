# fix_malformed_tags.ps1
# Fixes malformed tags in YAML frontmatter across the Obsidian vault.
# Categories of fixes:
#   1. Inline tags: "tags: - recipe - vegan" -> proper YAML list
#   2. Inline array: "tags: [recipe]" -> proper YAML list
#   3. URL tracking params in tags -> clean tag
#   4. Broken Bahá'í tags: "Bah - books" -> separate tags
#   5. MOC references as tags -> remove from tags
#   6. clippingsauthor: artifact -> remove
#   7. Tags with spaces -> hyphenate or CamelCase
#   8. Empty/broken tags -> remove
#
# Usage:
#   -WhatIf  : Preview changes without modifying files
#   -Apply   : Actually modify files

param(
    [switch]$WhatIf,
    [switch]$Apply
)

if (-not $WhatIf -and -not $Apply) {
    Write-Host "Usage: .\fix_malformed_tags.ps1 -WhatIf   (preview)"
    Write-Host "       .\fix_malformed_tags.ps1 -Apply    (apply changes)"
    exit 1
}

# Vault path
$vaultPath = "D:\Obsidian\Main"

# Tags with spaces -> replacement mapping
$spaceTagFixes = @{
    "Eat To Live"      = "EatToLive"
    "Jay Walljasper"   = $null           # Remove (author name, not a tag)
    "walking for health" = "walking-for-health"
}

# Track all changes for reporting
$allChanges = @()

# Get all markdown files
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" -File

foreach ($file in $files) {
    # Read file content with UTF-8
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Detect line ending style
    $hasCarriageReturn = $content.Contains("`r`n")
    $lineEnding = if ($hasCarriageReturn) { "`r`n" } else { "`n" }

    # Detect BOM
    $hasBom = $content.StartsWith([char]0xFEFF)

    # Split into lines
    $lines = $content -split "`r?`n"

    # State tracking
    $inFrontmatter = $false
    $frontmatterStart = $false
    $currentKey = ""
    $modified = $false
    $fileChanges = @()

    # Track lines to replace/remove/insert
    # We'll rebuild the lines array with fixes applied
    $newLines = [System.Collections.Generic.List[string]]::new()

    # Track tag indent (usually "  " = 2 spaces)
    $tagIndent = "  "

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Check for frontmatter delimiter
        if ($line -match '^\s*---\s*$') {
            if (-not $frontmatterStart) {
                $frontmatterStart = $true
                $inFrontmatter = $true
                $newLines.Add($line)
                continue
            } else {
                # End of frontmatter
                $inFrontmatter = $false
                $newLines.Add($line)
                continue
            }
        }

        # If not in frontmatter, pass through unchanged
        if (-not $inFrontmatter) {
            $newLines.Add($line)
            continue
        }

        # === INSIDE FRONTMATTER ===

        # Check if this line is a new YAML key
        if ($line -match '^([a-zA-Z_][a-zA-Z0-9_-]*)\s*:\s*(.*)$') {
            $currentKey = $Matches[1]
            $valueAfterColon = $Matches[2].Trim()

            # --- FIX: Inline tags with dash separators ---
            # Pattern: "tags: - recipe - email-recipe"
            if ($currentKey -eq 'tags' -and $valueAfterColon -match '^-\s+') {
                # Split by ' - ' pattern (space-dash-space) to get individual tags
                # But we need to handle quoted versions too: "recipe" - "vegan"
                $rawItems = $valueAfterColon -split '\s+-\s+'
                $expandedTags = @()
                foreach ($item in $rawItems) {
                    $tag = $item.Trim().Trim('"').Trim("'")
                    if ($tag -ne '') {
                        $expandedTags += $tag
                    }
                }

                # Write expanded tags as proper YAML list
                $newLines.Add("tags:")
                foreach ($tag in $expandedTags) {
                    $newLines.Add("$tagIndent- $tag")
                }

                $modified = $true
                $fileChanges += "  Split inline tags: '$valueAfterColon' -> $($expandedTags.Count) separate tags"
                continue
            }

            # --- FIX: Inline array format ---
            # Pattern: "tags: [recipe]"
            if ($currentKey -eq 'tags' -and $valueAfterColon -match '^\[(.+)\]$') {
                $arrayContent = $Matches[1]
                $items = $arrayContent -split ','
                $expandedTags = @()
                foreach ($item in $items) {
                    $tag = $item.Trim().Trim('"').Trim("'")
                    if ($tag -ne '') {
                        $expandedTags += $tag
                    }
                }

                $newLines.Add("tags:")
                foreach ($tag in $expandedTags) {
                    $newLines.Add("$tagIndent- $tag")
                }

                $modified = $true
                $fileChanges += "  Expanded array tags: [$arrayContent] -> $($expandedTags.Count) separate tags"
                continue
            }

            # Normal key line, pass through
            $newLines.Add($line)
            continue
        }

        # Check for list items under the tags key
        if ($currentKey -eq 'tags' -and $line -match '^(\s+-\s+)(.+)$') {
            $prefix = $Matches[1]
            $tagValue = $Matches[2].Trim().Trim('"').Trim("'")

            # Detect tag indent from first tag line
            if ($prefix -match '^(\s+)') {
                $tagIndent = $Matches[1]
            }

            # --- FIX: URL tracking params ---
            if ($tagValue -match '^(\w+)\?utm_') {
                $cleanTag = $Matches[1]
                $newLines.Add("${prefix}$cleanTag")
                $modified = $true
                $fileChanges += "  Cleaned URL params: '$tagValue' -> '$cleanTag'"
                continue
            }

            # --- FIX: MOC references as tags ---
            if ($tagValue -match '^MOC - ') {
                # Remove this line entirely - MOC references shouldn't be tags
                $modified = $true
                $fileChanges += "  Removed MOC tag: '$tagValue'"
                continue
            }

            # --- FIX: clippingsauthor: artifact ---
            if ($tagValue -match '^clippingsauthor:') {
                # Remove this malformed tag entirely
                $modified = $true
                $fileChanges += "  Removed malformed tag: '$tagValue'"
                continue
            }

            # --- FIX: Broken Bahá'í tags ---
            # "Bah - Bah - religion" -> just "religion" (bahai already exists as separate tag)
            # "Bah - books" -> just "books" (bahai already exists)
            if ($tagValue -match '^Bah\s*-\s*(.+)$') {
                $remainder = $Matches[1].Trim()
                # Split remainder by ' - ' in case of "Bah - religion"
                $parts = $remainder -split '\s*-\s*'
                foreach ($part in $parts) {
                    $part = $part.Trim()
                    # Skip "Bah" parts (already have bahai tag)
                    if ($part -ieq 'Bah' -or $part -ieq 'bahai') { continue }
                    if ($part -ne '') {
                        $newLines.Add("${prefix}$part")
                    }
                }
                $modified = $true
                $fileChanges += "  Fixed broken Bah tag: '$tagValue' -> extracted non-Bah parts"
                continue
            }

            # --- FIX: Tags with spaces ---
            if ($spaceTagFixes.ContainsKey($tagValue)) {
                $replacement = $spaceTagFixes[$tagValue]
                if ($null -eq $replacement) {
                    # Remove tag entirely
                    $modified = $true
                    $fileChanges += "  Removed author-as-tag: '$tagValue'"
                    continue
                } else {
                    $newLines.Add("${prefix}$replacement")
                    $modified = $true
                    $fileChanges += "  Fixed spaced tag: '$tagValue' -> '$replacement'"
                    continue
                }
            }

            # --- FIX: Empty/broken tags ---
            if ($tagValue -eq '#' -or $tagValue -eq '' -or $tagValue -eq 'none') {
                $modified = $true
                $fileChanges += "  Removed empty/broken tag: '$tagValue'"
                continue
            }

            # No fix needed, pass through
            $newLines.Add($line)
            continue
        }

        # All other frontmatter lines, pass through
        $newLines.Add($line)
    }

    # If file was modified, write it back
    if ($modified) {
        $newContent = $newLines -join $lineEnding

        $relativePath = $file.FullName.Substring($vaultPath.Length + 1)

        if ($Apply) {
            if ($hasBom) {
                $utf8Bom = [System.Text.UTF8Encoding]::new($true)
                [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8Bom)
            } else {
                $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
                [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
            }
            Write-Host "FIXED: $relativePath"
        } else {
            Write-Host "WOULD FIX: $relativePath"
        }

        foreach ($change in $fileChanges) {
            Write-Host $change
        }

        $allChanges += [PSCustomObject]@{
            File    = $relativePath
            Changes = $fileChanges
        }
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ==="
$mode = if ($Apply) { "Applied" } else { "Preview (no changes made)" }
Write-Host "Mode: $mode"
Write-Host "Files affected: $($allChanges.Count)"
Write-Host "Total changes: $(($allChanges | ForEach-Object { $_.Changes.Count } | Measure-Object -Sum).Sum)"
