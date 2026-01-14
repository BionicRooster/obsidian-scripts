# Script to move #clippings tag to last position in files with multiple tags
# Works with both inline hashtag format and YAML frontmatter format

# Path to the Clippings folder
$clippingsPath = "D:\Obsidian\Main\10 - Clippings"

# Counter for tracking changes
$filesModified = 0
$filesChecked = 0

# Get all markdown files in the Clippings folder (recursively)
$mdFiles = Get-ChildItem -Path $clippingsPath -Filter "*.md" -Recurse

Write-Host "Found $($mdFiles.Count) markdown files in Clippings folder`n"

foreach ($file in $mdFiles) {
    $filesChecked++

    # Read file content with UTF-8 encoding
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    # Flag to track if we modified this file
    $modified = $false
    $originalContent = $content

    # Check for YAML frontmatter
    if ($content -match '^---\r?\n([\s\S]*?)\r?\n---') {
        $yamlBlock = $Matches[0]
        $yamlContent = $Matches[1]

        # Check for YAML array format: tags: [tag1, tag2, clippings]
        if ($yamlContent -match 'tags:\s*\[([^\]]+)\]') {
            $tagsMatch = $Matches[0]
            $tagsList = $Matches[1]

            # Parse the tags (handle both quoted and unquoted)
            $tags = $tagsList -split '\s*,\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") }

            # Check if clippings tag exists and there are multiple tags
            if ($tags.Count -gt 1 -and ($tags -contains 'clippings' -or $tags -contains '#clippings')) {
                # Remove clippings from its current position
                $clippingsTag = if ($tags -contains '#clippings') { '#clippings' } else { 'clippings' }
                $otherTags = $tags | Where-Object { $_ -ne 'clippings' -and $_ -ne '#clippings' }

                # Only modify if clippings isn't already last
                $lastTag = $tags[-1]
                if ($lastTag -ne 'clippings' -and $lastTag -ne '#clippings') {
                    # Rebuild tags array with clippings at the end
                    $newTagsList = ($otherTags + 'clippings') -join ', '
                    $newTagsLine = "tags: [$newTagsList]"

                    # Replace in YAML content
                    $newYamlContent = $yamlContent -replace 'tags:\s*\[[^\]]+\]', $newTagsLine
                    $newYamlBlock = "---`n$newYamlContent`n---"
                    $content = $content -replace [regex]::Escape($yamlBlock), $newYamlBlock
                    $modified = $true
                    Write-Host "YAML array: $($file.Name)"
                    Write-Host "  Before: $tagsList"
                    Write-Host "  After:  $newTagsList`n"
                }
            }
        }
        # Check for YAML list format: tags:\n  - tag1\n  - tag2
        elseif ($yamlContent -match 'tags:\s*\r?\n((?:\s*-\s*[^\r\n]+\r?\n?)+)') {
            $tagsSection = $Matches[0]
            $tagLines = $Matches[1]

            # Parse tags from list format
            $tags = @()
            $tagLines -split '\r?\n' | ForEach-Object {
                if ($_ -match '^\s*-\s*(.+)$') {
                    $tags += $Matches[1].Trim().Trim('"').Trim("'")
                }
            }

            # Check if clippings tag exists and there are multiple tags
            if ($tags.Count -gt 1 -and ($tags -contains 'clippings' -or $tags -contains '#clippings')) {
                # Check if clippings is already last
                $lastTag = $tags[-1]
                if ($lastTag -ne 'clippings' -and $lastTag -ne '#clippings') {
                    # Remove clippings from its current position
                    $otherTags = $tags | Where-Object { $_ -ne 'clippings' -and $_ -ne '#clippings' }

                    # Rebuild tags section with clippings at the end
                    $newTagLines = ($otherTags | ForEach-Object { "  - $_" }) -join "`n"
                    $newTagLines += "`n  - clippings"
                    $newTagsSection = "tags:`n$newTagLines"

                    # Replace in content
                    $content = $content -replace [regex]::Escape($tagsSection), $newTagsSection
                    $modified = $true
                    Write-Host "YAML list: $($file.Name)"
                    Write-Host "  Moved clippings to last position`n"
                }
            }
        }
    }

    # Check for inline hashtag format (outside YAML): #clippings #othertag
    # Look for lines with multiple hashtags where one is #clippings
    $lines = $content -split '\r?\n'
    $newLines = @()

    foreach ($line in $lines) {
        # Skip if inside YAML frontmatter (we already handled that)
        # Match lines with multiple hashtags
        if ($line -match '(?:^|\s)(#\w+(?:\s+#\w+)+)') {
            $hashtagsMatch = $Matches[1]
            $hashtags = [regex]::Matches($hashtagsMatch, '#\w+') | ForEach-Object { $_.Value }

            if ($hashtags.Count -gt 1 -and $hashtags -contains '#clippings') {
                # Check if #clippings is already last
                if ($hashtags[-1] -ne '#clippings') {
                    $otherHashtags = $hashtags | Where-Object { $_ -ne '#clippings' }
                    $newHashtags = ($otherHashtags + '#clippings') -join ' '
                    $newLine = $line -replace [regex]::Escape($hashtagsMatch), $newHashtags
                    $newLines += $newLine

                    if (-not $modified) {
                        Write-Host "Inline tags: $($file.Name)"
                    }
                    Write-Host "  Before: $hashtagsMatch"
                    Write-Host "  After:  $newHashtags`n"
                    $modified = $true
                    continue
                }
            }
        }
        $newLines += $line
    }

    if ($modified) {
        # Reconstruct content from lines if we modified inline tags
        if ($newLines.Count -gt 0 -and ($newLines -join "`n") -ne $originalContent) {
            $content = $newLines -join "`n"
        }

        # Write back with UTF-8 encoding (no BOM)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
        $filesModified++
    }
}

Write-Host "=========================================="
Write-Host "Summary:"
Write-Host "  Files checked: $filesChecked"
Write-Host "  Files modified: $filesModified"
