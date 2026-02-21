<#
.SYNOPSIS
    Fixes files that ended up with two YAML frontmatter blocks after inline tag conversion.

.DESCRIPTION
    Finds .md files where convert_inline_tags.ps1 created a new frontmatter block
    before an existing one, resulting in two --- blocks. Merges tags from the first
    block into the second and removes the duplicate.

.PARAMETER WhatIf
    Preview mode - shows what would change without modifying files.

.PARAMETER Apply
    Actually apply changes to files.
#>
param(
    [switch]$WhatIf,
    [switch]$Apply
)

if (-not $WhatIf -and -not $Apply) {
    Write-Host "ERROR: Specify -WhatIf or -Apply" -ForegroundColor Red
    exit 1
}

$vaultRoot = "D:\Obsidian\Main"
$fixed = 0      # Count of files fixed

# Scan all .md files in the vault
Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" | ForEach-Object {
    $file = $_
    $rawContent = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $lines = $rawContent -split "`r?`n"

    # Find all --- delimiter positions (exact match for opening/mid, allow trailing text for closing)
    $dashPositions = @()  # Line indices of --- delimiters
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') {
            $dashPositions += $i
        }
    }

    # If we found exactly 3 dashes, check if there's a closing --- with trailing content (e.g., "---**text**")
    if ($dashPositions.Count -eq 3) {
        # Look for a line starting with --- after the 3rd dash position
        for ($i = $dashPositions[2] + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^---\S') {
                $dashPositions += $i
                break
            }
        }
    }

    # Need at least 4 dashes for double frontmatter pattern
    if ($dashPositions.Count -lt 4) { return }

    # Check for pattern: ---block1--- immediately followed by ---block2---
    # The closing --- of block1 and opening --- of block2 should be adjacent (or 1 line apart)
    $d0 = $dashPositions[0]  # Opening --- of first block
    $d1 = $dashPositions[1]  # Closing --- of first block
    $d2 = $dashPositions[2]  # Opening --- of second block
    $d3 = $dashPositions[3]  # Closing --- of second block

    # First block must start at line 0 (or very near top)
    if ($d0 -gt 1) { return }

    # Second block must start right after first block closes (adjacent or 1 blank line)
    $gap = $d2 - $d1
    if ($gap -gt 2) { return }  # Too far apart - not a double frontmatter issue
    # Check that any lines between d1 and d2 are blank
    $gapClean = $true
    for ($i = $d1 + 1; $i -lt $d2; $i++) {
        if ($lines[$i].Trim() -ne '') { $gapClean = $false; break }
    }
    if (-not $gapClean) { return }

    # Validate first block is tags-only (created by convert_inline_tags.ps1)
    # It should contain only "tags:" and "  - tagname" lines, nothing else
    $block1IsTagsOnly = $true  # Flag: first block has only tags content
    $block1HasTagsKey = $false # Flag: first block has a tags: key
    $block1Tags = @()          # Tags parsed from first block
    for ($i = $d0 + 1; $i -lt $d1; $i++) {
        $trimLine = $lines[$i].Trim()
        if ($trimLine -eq '') { continue }  # Skip blank lines
        if ($trimLine -eq 'tags:') {
            $block1HasTagsKey = $true
        } elseif ($lines[$i] -match '^\s+-\s+(.+)$') {
            $block1Tags += $Matches[1].Trim().Trim('"').Trim("'")
        } else {
            # Non-tag content found - this is a real frontmatter block, not script-created
            $block1IsTagsOnly = $false
            break
        }
    }
    # Skip if first block isn't a pure tags block or has no tags key
    if (-not $block1IsTagsOnly -or -not $block1HasTagsKey) { return }

    # Parse tags from second block
    $block2TagsStart = -1  # Line index of tags: key in block 2
    $block2TagsEnd = -1    # Last line of tags list in block 2
    $block2Tags = @()      # Existing tags in block 2
    for ($i = $d2 + 1; $i -lt $d3; $i++) {
        if ($lines[$i] -match '^\s*tags\s*:') {
            $block2TagsStart = $i
            # Check for bracket format
            if ($lines[$i] -match '^\s*tags\s*:\s*\[([^\]]*)\]') {
                $block2Tags = @($Matches[1] -split '\s*,\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ -ne '' })
                $block2TagsEnd = $i
            }
            # Check for list format
            else {
                $block2TagsEnd = $i
                for ($k = $i + 1; $k -lt $d3; $k++) {
                    if ($lines[$k] -match '^\s*-\s+(.+)$') {
                        $block2Tags += $Matches[1].Trim().Trim('"').Trim("'")
                        $block2TagsEnd = $k
                    } elseif ($lines[$k].Trim() -eq '') {
                        continue
                    } else {
                        break
                    }
                }
            }
            break
        }
    }

    # Merge tags: block1 tags + block2 tags, deduplicated case-insensitively
    $mergedTags = @()
    $seenLower = @{}
    # Block1 tags first (these were the inline/body marker tags)
    foreach ($t in $block1Tags) {
        $lower = $t.ToLower()
        if (-not $seenLower.ContainsKey($lower)) {
            $seenLower[$lower] = $true
            $mergedTags += $t
        }
    }
    # Then block2 tags
    foreach ($t in $block2Tags) {
        $lower = $t.ToLower()
        if (-not $seenLower.ContainsKey($lower)) {
            $seenLower[$lower] = $true
            $mergedTags += $t
        }
    }

    # Build new file: skip first block entirely, update tags in second block
    $newLines = [System.Collections.Generic.List[string]]::new()

    # Skip lines 0 through d1 (first frontmatter block) and any blank lines between blocks
    $bodyStartLine = $d2  # Start from second block's opening ---

    for ($i = $bodyStartLine; $i -lt $lines.Count; $i++) {
        if ($i -ge $d2 -and $i -le $d3) {
            # Inside second YAML block
            if ($i -eq $d2 -or $i -eq $d3) {
                $newLines.Add($lines[$i])  # Keep --- delimiters
            }
            elseif ($block2TagsStart -ge 0 -and $i -ge $block2TagsStart -and $i -le $block2TagsEnd) {
                # Replace tags section with merged tags
                if ($i -eq $block2TagsStart) {
                    $newLines.Add("tags:")
                    foreach ($t in $mergedTags) {
                        $newLines.Add("  - $t")
                    }
                }
                # Skip other lines of old tags block
            }
            elseif ($block2TagsStart -lt 0 -and $i -eq $d3) {
                # No tags key in block2 - insert merged tags before closing ---
                # (closing --- already added above, so insert before it)
                $newLines.RemoveAt($newLines.Count - 1)
                $newLines.Add("tags:")
                foreach ($t in $mergedTags) {
                    $newLines.Add("  - $t")
                }
                $newLines.Add($lines[$i])  # Re-add closing ---
            }
            else {
                $newLines.Add($lines[$i])
            }
        }
        else {
            $newLines.Add($lines[$i])
        }
    }

    $relativePath = $file.FullName.Substring($vaultRoot.Length + 1)
    $fixed++

    if ($WhatIf) {
        Write-Host "WOULD FIX: $relativePath" -ForegroundColor Yellow
        Write-Host "  Block1 tags: $($block1Tags -join ', ')" -ForegroundColor White
        Write-Host "  Block2 tags: $($block2Tags -join ', ')" -ForegroundColor White
        Write-Host "  Merged tags: $($mergedTags -join ', ')" -ForegroundColor Green
    }
    else {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $newContent = $newLines -join "`r`n"
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
        Write-Host "FIXED: $relativePath  |  Tags: $($mergedTags -join ', ')" -ForegroundColor Green
    }
}

Write-Host "`n========== SUMMARY ==========" -ForegroundColor Cyan
Write-Host "Files fixed: $fixed"
if ($WhatIf) {
    Write-Host "This was a DRY RUN. Use -Apply to make changes." -ForegroundColor Yellow
}
