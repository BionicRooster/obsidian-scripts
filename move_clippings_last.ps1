# Script to move "clippings" tag to last position in YAML frontmatter
# Only processes files that are linked from MOC files
# Excludes contact/Person files
# Preserves UTF-8 encoding

param(
    [string]$VaultPath = "D:\Obsidian\Main",
    [switch]$DryRun = $false
)

# Set UTF-8 encoding for output
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Get all MOC files
$mocFiles = Get-ChildItem -Path "$VaultPath\00 - Home Dashboard" -Filter "*MOC*.md" -File

# Extract all wikilinks from MOC files
$linkedFiles = @{}
foreach ($moc in $mocFiles) {
    $content = Get-Content -Path $moc.FullName -Raw -Encoding UTF8
    # Match [[LinkName]] or [[LinkName|Alias]] patterns
    $matches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
    foreach ($match in $matches) {
        $linkName = $match.Groups[1].Value
        # Skip folder references and MOC self-references
        if ($linkName -notmatch '^\d+ - ' -and $linkName -notmatch '^MOC') {
            $linkedFiles[$linkName] = $true
        }
    }
}

Write-Host "Found $($linkedFiles.Count) unique links in MOC files"

# Find all files with clippings tag where it's not last
$processedCount = 0
$modifiedCount = 0

# Search for files with clippings tag
$allMdFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File

foreach ($file in $allMdFiles) {
    # Skip contact/Person files
    if ($file.FullName -match '\\16 - Organizations\\' -or
        $file.FullName -match '\\Contacts\\' -or
        $file.FullName -match '\\People\\' -or
        $file.DirectoryName -match 'Person') {
        continue
    }

    # Get base filename without extension for matching
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

    # Check if this file is linked from any MOC
    $isLinked = $false
    foreach ($link in $linkedFiles.Keys) {
        if ($link -eq $baseName -or $link -like "$baseName*" -or $baseName -like "$link*") {
            $isLinked = $true
            break
        }
    }

    if (-not $isLinked) {
        continue
    }

    # Read file content
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    if (-not $content) { continue }

    # Check if file has YAML frontmatter with clippings tag
    if ($content -match '^---\r?\n([\s\S]*?)\r?\n---') {
        $yaml = $matches[1]

        # Check if tags section exists with clippings
        if ($yaml -match 'tags:\s*\r?\n((?:- .+\r?\n)+)') {
            $tagsSection = $matches[1]

            # Check if clippings exists and is not last
            if ($tagsSection -match '- "?clippings"?\r?\n- ') {
                $processedCount++

                # Parse tags into array
                $tagLines = $tagsSection -split '\r?\n' | Where-Object { $_ -match '^- ' }
                $tags = @()
                $hasClippings = $false

                foreach ($tagLine in $tagLines) {
                    if ($tagLine -match '^- "?clippings"?$') {
                        $hasClippings = $true
                    } else {
                        $tags += $tagLine
                    }
                }

                if ($hasClippings -and $tags.Count -gt 0) {
                    # Rebuild tags section with clippings at end
                    $newTagsSection = ($tags -join "`n") + "`n- `"clippings`"`n"

                    # Replace old tags section with new one
                    $newYaml = $yaml -replace 'tags:\s*\r?\n((?:- .+\r?\n)+)', "tags:`n$newTagsSection"
                    $newContent = $content -replace '^---\r?\n[\s\S]*?\r?\n---', "---`n$newYaml`n---"

                    if (-not $DryRun) {
                        # Write back with UTF-8 encoding (no BOM for most files, preserve if exists)
                        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
                    }

                    $modifiedCount++
                    Write-Host "Modified: $($file.Name)"
                }
            }
        }
    }
}

Write-Host "`nProcessed $processedCount files with clippings not last"
Write-Host "Modified $modifiedCount files"
if ($DryRun) {
    Write-Host "(DRY RUN - no files were actually changed)"
}
