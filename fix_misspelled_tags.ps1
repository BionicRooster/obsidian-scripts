# fix_misspelled_tags.ps1
# Finds and fixes misspelled tags in YAML frontmatter across the Obsidian vault.
# Usage:
#   -WhatIf  : Preview changes without modifying files
#   -Apply   : Actually modify files

param(
    [switch]$WhatIf,   # Preview mode - show what would change
    [switch]$Apply     # Apply mode - modify files
)

# Validate that exactly one mode is specified
if (-not $WhatIf -and -not $Apply) {
    Write-Host "Usage: .\fix_misspelled_tags.ps1 -WhatIf   (preview)"
    Write-Host "       .\fix_misspelled_tags.ps1 -Apply    (apply changes)"
    exit 1
}

# Vault path
$vaultPath = "D:\Obsidian\Main"

# Misspelled tag -> correct tag mapping
# Each key is the misspelled tag, value is the correct replacement
$fixMap = @{
    "vegsn"         = "vegan"          # Typo: vegsn -> vegan (136 existing uses)
    "revipe"        = "recipe"         # Typo: revipe -> recipe (336 existing uses)
    "Longivity"     = "longevity"      # Misspelling: Longivity -> longevity (2 existing uses)
    "Judiasm"       = "Judaism"        # Transposed letters: Judiasm -> Judaism
    "IsaacAsamov"   = "IsaacAsimov"    # Misspelled surname: Asamov -> Asimov
    "ClassStrugle"  = "ClassStruggle"  # Missing letter: Strugle -> Struggle
}

# Track changes for reporting
$changes = @()

# Get all markdown files
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" -File

foreach ($file in $files) {
    # Read file content with UTF-8 encoding
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Split into lines preserving original line endings
    $hasCarriageReturn = $content.Contains("`r`n")
    $lines = $content -split "`r?`n"

    # State tracking for YAML parsing
    $inFrontmatter = $false       # Whether we are inside the frontmatter block
    $frontmatterStart = $false    # Whether we have seen the first ---
    $currentKey = ""              # The current top-level YAML key
    $modified = $false            # Whether this file was modified
    $fileChanges = @()            # Changes made to this file

    # Collect all tags in this file (for duplicate detection)
    $existingTags = @()
    $tagLineIndices = @()

    # First pass: collect existing tags and their line indices
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^\s*---\s*$') {
            if (-not $frontmatterStart) {
                $frontmatterStart = $true
                $inFrontmatter = $true
                continue
            } else {
                break
            }
        }

        if (-not $inFrontmatter) { continue }

        # Detect new YAML key
        if ($line -match '^([a-zA-Z_][a-zA-Z0-9_-]*)\s*:') {
            $currentKey = $Matches[1]
            continue
        }

        # Collect tag list items
        if ($currentKey -eq 'tags' -and $line -match '^\s+-\s+(.+)$') {
            $tag = $Matches[1].Trim().Trim('"').Trim("'")
            $existingTags += $tag
            $tagLineIndices += $i
        }
    }

    # Second pass: fix misspelled tags
    # Reset state
    $inFrontmatter = $false
    $frontmatterStart = $false
    $currentKey = ""
    $linesToRemove = @()  # Indices of lines to remove (duplicates)

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match '^\s*---\s*$') {
            if (-not $frontmatterStart) {
                $frontmatterStart = $true
                $inFrontmatter = $true
                continue
            } else {
                break
            }
        }

        if (-not $inFrontmatter) { continue }

        # Detect new YAML key
        if ($line -match '^([a-zA-Z_][a-zA-Z0-9_-]*)\s*:') {
            $currentKey = $Matches[1]
            continue
        }

        # Process tag list items
        if ($currentKey -eq 'tags' -and $line -match '^\s+-\s+(.+)$') {
            $rawTag = $Matches[1].Trim()
            # Strip quotes for comparison
            $tag = $rawTag.Trim('"').Trim("'")

            # Check if this tag is misspelled
            if ($fixMap.ContainsKey($tag)) {
                $correctTag = $fixMap[$tag]

                # Check if the correct tag already exists in this file (case-insensitive)
                $alreadyExists = $existingTags | Where-Object { $_ -ieq $correctTag }

                if ($alreadyExists) {
                    # Correct tag already exists - remove this misspelled line entirely
                    $linesToRemove += $i
                    $fileChanges += "  Removed duplicate: '$tag' (correct '$correctTag' already exists)"
                } else {
                    # Replace the misspelled tag with the correct one
                    # Preserve the original quoting style
                    $isQuoted = $rawTag.StartsWith('"') -or $rawTag.StartsWith("'")
                    if ($isQuoted) {
                        $newTag = "`"$correctTag`""
                    } else {
                        $newTag = $correctTag
                    }

                    # Preserve indentation
                    if ($line -match '^(\s+-\s+)') {
                        $prefix = $Matches[1]
                        $lines[$i] = "$prefix$newTag"
                    }

                    $fileChanges += "  Changed: '$tag' -> '$correctTag'"
                }
                $modified = $true
            }
        }
    }

    # Remove lines marked for deletion (in reverse order to preserve indices)
    if ($linesToRemove.Count -gt 0) {
        $linesList = [System.Collections.Generic.List[string]]::new($lines)
        $sorted = $linesToRemove | Sort-Object -Descending
        foreach ($idx in $sorted) {
            $linesList.RemoveAt($idx)
        }
        $lines = $linesList.ToArray()
    }

    # Also check for inline #tags in the body (after frontmatter)
    $inBody = $false
    $frontmatterCount = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*---\s*$') {
            $frontmatterCount++
            if ($frontmatterCount -ge 2) {
                $inBody = $true
                continue
            }
        }

        if ($inBody) {
            foreach ($entry in $fixMap.GetEnumerator()) {
                $bad = [regex]::Escape($entry.Key)
                $good = $entry.Value
                # Match #tag that is not part of a larger word
                $pattern = "(?<=\s|^)#$bad(?=\s|$|[,;.\)\]\}])"
                if ($lines[$i] -match $pattern) {
                    $lines[$i] = $lines[$i] -replace $pattern, "#$good"
                    $fileChanges += "  Inline: '#$($entry.Key)' -> '#$good' (line $($i + 1))"
                    $modified = $true
                }
            }
        }
    }

    # Write changes if file was modified
    if ($modified) {
        # Reconstruct content with original line ending style
        $lineEnding = if ($hasCarriageReturn) { "`r`n" } else { "`n" }
        $newContent = $lines -join $lineEnding

        # Preserve BOM if original had one
        $hasBom = $content.StartsWith([char]0xFEFF)

        $relativePath = $file.FullName.Substring($vaultPath.Length + 1)

        if ($Apply) {
            # Write with UTF-8 encoding (no BOM unless original had BOM)
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

        $changes += [PSCustomObject]@{
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
Write-Host "Files affected: $($changes.Count)"
Write-Host "Total changes: $(($changes | ForEach-Object { $_.Changes.Count } | Measure-Object -Sum).Sum)"
Write-Host ""
Write-Host "Fix map used:"
foreach ($entry in $fixMap.GetEnumerator() | Sort-Object Key) {
    Write-Host "  $($entry.Key) -> $($entry.Value)"
}
