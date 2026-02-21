# Remove citation reference and auto-generated tags from Obsidian vault
# Patterns to remove:
# - #B1, #B2, ... #B140 (numbered citations)
# - #b1, #b2, ... #b29 (lowercase numbered citations)
# - #CITEREF* (citation references)
# - #cite_note-* (Wikipedia-style citations)
# - #axzz* (URL fragments)
# - #c followed by long numbers (comment IDs like #c3758288697004962176)
# - #author-0, #appliesto, #article__start, #BVRRWidgetID, etc. (metadata tags)
# - #GR-0 (Goodreads IDs)
# - Various HTML anchor-like tags

param(
    [switch]$WhatIf,  # Preview changes without modifying files
    [switch]$Verbose  # Show detailed output
)

$vaultPath = "D:\Obsidian\Main"

# Regex patterns for junk tags to remove
# Each pattern matches #tagname but not ##heading
$junkPatterns = @(
    # Numbered citation tags (B1-B999, b1-b999)
    '(?<![#\w])#[Bb]\d{1,3}(?!\w)',

    # CITEREF tags (Wikipedia citations)
    '(?<![#\w])#CITEREF[A-Za-z0-9_-]+(?!\w)',

    # cite_note tags (Wikipedia-style)
    '(?<![#\w])#cite_note-[A-Za-z0-9_-]+(?!\w)',

    # axzz URL fragments
    '(?<![#\w])#axzz[A-Za-z0-9]+(?!\w)',

    # Long numeric comment IDs (c followed by 10+ digits)
    '(?<![#\w])#c\d{10,}(?!\w)',

    # Metadata/auto-generated tags
    '(?<![#\w])#author-\d+(?!\w)',
    '(?<![#\w])#appliesto(?!\w)',
    '(?<![#\w])#article__start(?!\w)',
    '(?<![#\w])#BVRRWidgetID(?!\w)',
    '(?<![#\w])#GR-\d+(?!\w)',

    # by-clicking agreement tags
    '(?<![#\w])#by-clicking-[a-zA-Z0-9-]+(?!\w)',

    # Check/boot related auto-generated tags
    '(?<![#\w])#check-for-unusual-installed-programs(?!\w)',
    '(?<![#\w])#check-task-scheduler(?!\w)',
    '(?<![#\w])#check-the-integrity-of-the-iso-file(?!\w)',
    '(?<![#\w])#check-your-browser-for-signs-of-infection(?!\w)',
    '(?<![#\w])#boot-into-safe-mode(?!\w)',

    # Chaining/bool property tags (from Dataview queries)
    '(?<![#\w])#chaining-resources(?!\w)',
    '(?<![#\w])#bool-property-to-custom-display-value(?!\w)',

    # Areas vs projects type tags
    '(?<![#\w])#actionable-vs-non-actionable(?!\w)',
    '(?<![#\w])#areas-vs-projects(?!\w)'
)

# Combine all patterns into one regex
$combinedPattern = $junkPatterns -join '|'

# Track statistics
$filesModified = 0
$totalTagsRemoved = 0
$fileDetails = @()

# Get all markdown files
$files = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Find all matches in this file
    $matches = [regex]::Matches($content, $combinedPattern)

    if ($matches.Count -gt 0) {
        $tagsInFile = $matches | ForEach-Object { $_.Value } | Sort-Object -Unique

        if ($Verbose) {
            $relativePath = $file.FullName -replace [regex]::Escape($vaultPath + "\"), ""
            Write-Host "File: $relativePath" -ForegroundColor Cyan
            Write-Host "  Tags to remove: $($tagsInFile -join ', ')" -ForegroundColor Yellow
        }

        if (-not $WhatIf) {
            # Remove all junk tags
            $newContent = [regex]::Replace($content, $combinedPattern, '')

            # Clean up any double spaces left behind
            $newContent = $newContent -replace '  +', ' '

            # Only write if content actually changed
            if ($newContent -ne $content) {
                Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
                $filesModified++
                $totalTagsRemoved += $matches.Count

                $fileDetails += [PSCustomObject]@{
                    File = $file.FullName -replace [regex]::Escape($vaultPath + "\"), ""
                    TagsRemoved = $matches.Count
                    Tags = ($tagsInFile -join ', ')
                }
            }
        } else {
            $filesModified++
            $totalTagsRemoved += $matches.Count

            $fileDetails += [PSCustomObject]@{
                File = $file.FullName -replace [regex]::Escape($vaultPath + "\"), ""
                TagsRemoved = $matches.Count
                Tags = ($tagsInFile -join ', ')
            }
        }
    }
}

# Output summary
Write-Host "`n========== SUMMARY ==========" -ForegroundColor Green
if ($WhatIf) {
    Write-Host "PREVIEW MODE - No files were modified" -ForegroundColor Yellow
}
Write-Host "Files affected: $filesModified"
Write-Host "Total tags removed: $totalTagsRemoved"

if ($fileDetails.Count -gt 0) {
    Write-Host "`nFiles with removed tags:" -ForegroundColor Cyan
    $fileDetails | Format-Table -AutoSize -Wrap
}
