# extract_unique_tags.ps1
# Scans all .md files in the Obsidian vault and extracts unique tags
# from YAML frontmatter only (not author, source, or other YAML keys).
# Outputs sorted list with file counts.

# Vault path
$vaultPath = "D:\Obsidian\Main"

# Output file
$outputFile = "C:\Users\awt\vault_tags.txt"

# Hashtable to track tag -> set of files using it
$tagFiles = @{}

# Get all markdown files
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" -File

$fileCount = 0

foreach ($file in $files) {
    $fileCount++

    # Read file content with UTF-8 encoding
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    # Split into lines
    $lines = $content -split "`r?`n"

    # State tracking for YAML parsing
    $inFrontmatter = $false       # Whether we are inside the frontmatter block
    $frontmatterStart = $false    # Whether we have seen the first ---
    $currentKey = ""              # The current top-level YAML key
    $fileTags = @()               # Tags found in this file

    foreach ($line in $lines) {
        # Check for frontmatter delimiter
        if ($line -match '^\s*---\s*$') {
            if (-not $frontmatterStart) {
                # First --- : entering frontmatter
                $frontmatterStart = $true
                $inFrontmatter = $true
                continue
            } else {
                # Second --- : exiting frontmatter, stop parsing
                break
            }
        }

        # Only process lines inside frontmatter
        if (-not $inFrontmatter) { continue }

        # Check if this line starts a new top-level YAML key (not indented, has colon)
        if ($line -match '^([a-zA-Z_][a-zA-Z0-9_-]*)\s*:\s*(.*)$') {
            $currentKey = $Matches[1]
            $valueAfterColon = $Matches[2].Trim()

            # If this is the tags key with an inline value
            if ($currentKey -eq 'tags' -and $valueAfterColon -ne '') {
                # Handle inline array format: tags: [tag1, tag2]
                if ($valueAfterColon -match '^\[(.+)\]$') {
                    $inlineItems = $Matches[1] -split ','
                    foreach ($item in $inlineItems) {
                        $tag = $item.Trim().Trim('"').Trim("'")
                        if ($tag -ne '') {
                            $fileTags += $tag
                        }
                    }
                }
                # Handle single inline value: tags: recipe
                elseif ($valueAfterColon -notmatch '^\s*$') {
                    $tag = $valueAfterColon.Trim('"').Trim("'")
                    if ($tag -ne '') {
                        $fileTags += $tag
                    }
                }
            }
            continue
        }

        # Check for list items (indented with - )
        if ($currentKey -eq 'tags' -and $line -match '^\s+-\s+(.+)$') {
            $tag = $Matches[1].Trim().Trim('"').Trim("'")
            if ($tag -ne '') {
                $fileTags += $tag
            }
        }
        # If the line is indented but NOT a list item and NOT empty,
        # it might be a continuation or different structure - skip
        elseif ($line -match '^\s+\S' -and $currentKey -ne 'tags') {
            # Still under a non-tags key, skip
        }
        elseif ($line -match '^\s*$') {
            # Empty line, currentKey remains
        }
    }

    # Add this file's tags to the global collection
    foreach ($tag in $fileTags) {
        if (-not $tagFiles.ContainsKey($tag)) {
            $tagFiles[$tag] = [System.Collections.Generic.List[string]]::new()
        }
        # Avoid duplicate file entries for same tag
        if (-not $tagFiles[$tag].Contains($file.FullName)) {
            $tagFiles[$tag].Add($file.FullName)
        }
    }
}

# Build output
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("Obsidian Vault Tag Inventory")
[void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$sb.AppendLine("Files scanned: $fileCount")
[void]$sb.AppendLine("Unique tags: $($tagFiles.Count)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Count  Tag")
[void]$sb.AppendLine("-----  ---")

# Sort by tag name alphabetically
$sorted = $tagFiles.GetEnumerator() | Sort-Object { $_.Key }

foreach ($entry in $sorted) {
    $count = $entry.Value.Count.ToString().PadLeft(5)
    $tag = $entry.Key
    [void]$sb.AppendLine("$count  $tag")
}

# Write output
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), $utf8NoBom)

Write-Host "Done. $($tagFiles.Count) unique tags found across $fileCount files."
Write-Host "Output written to: $outputFile"
