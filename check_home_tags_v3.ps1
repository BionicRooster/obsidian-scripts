# Script to check and add "Home" tag to files linked in MOC - Home & Practical Life
# This version handles partial/truncated filenames better

param(
    [string]$VaultPath = "D:\Obsidian\Main"
)

# Counter variables
$added = 0
$alreadyHad = 0
$notFound = 0
$skipped = 0

# Read the actual MOC file and extract links
$mocPath = Join-Path $VaultPath "00 - Home Dashboard\MOC - Home & Practical Life.md"
$mocContent = Get-Content -Path $mocPath -Encoding UTF8

# Extract all [[filename]] patterns
$matches = [regex]::Matches($mocContent, '\[\[([^\]]+)\]\]')
$filesToCheck = @()
foreach ($match in $matches) {
    $filename = $match.Groups[1].Value.Trim()
    if ($filename -and $filename -notmatch '^MOC' -and $filename -ne "Master MOC Index") {
        if ($filesToCheck -notcontains $filename) {
            $filesToCheck += $filename
        }
    }
}

# People to skip (simple contact files)
$peopleToSkip = @(
    "Chuck Collins", "Angela Bryant", "Jody Patterson", "Karen Harrison", "Ricki McMillian",
    "Mindy Klein", "Sally Miculek", "Wayne Talbot", "Terrie Hahn", "Kalena Powell",
    "Diane Moukourie", "Diane Sandlin"
)

Write-Host "Starting Home tag check..."
Write-Host "Total unique links found in MOC: $($filesToCheck.Count)"
Write-Host ""

# Process each file
foreach ($filename in $filesToCheck) {
    # Skip people files
    if ($peopleToSkip -contains $filename) {
        Write-Host "SKIP (Person): $filename"
        $skipped++
        continue
    }

    # Find the file - exact match first
    $foundFiles = @()
    $searchPattern = "$filename.md"
    $foundFiles = Get-ChildItem -Path $VaultPath -Filter "$searchPattern" -Recurse -ErrorAction SilentlyContinue

    # If not found, try partial match (for truncated names)
    if ($foundFiles.Count -eq 0) {
        $foundFiles = Get-ChildItem -Path $VaultPath -Recurse -ErrorAction SilentlyContinue | Where-Object {
            $_.Extension -eq ".md" -and $_.BaseName.StartsWith($filename)
        } | Select-Object -First 1
    }

    if ($null -eq $foundFiles -or $foundFiles.Count -eq 0) {
        Write-Host "NOT FOUND: $filename"
        $notFound++
        continue
    }

    # Handle single object vs array
    if ($foundFiles -is [System.IO.FileInfo]) {
        $file = $foundFiles
    } else {
        $file = $foundFiles[0]
    }

    # Skip if in "09 - Kindle Clippings"
    if ($file.FullName -like "*09 - Kindle Clippings*") {
        Write-Host "SKIP (Kindle): $($file.Name)"
        $skipped++
        continue
    }

    # Read file with UTF-8 encoding
    $content = Get-Content -Path $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue

    if ($null -eq $content) {
        Write-Host "ERROR reading: $($file.Name)"
        $notFound++
        continue
    }

    # Convert to array if single line
    if ($content -is [string]) {
        $content = @($content)
    }

    # Check if file already has Home tag (case-insensitive)
    $hasHomeTag = $false
    $contentText = $content -join "`n"

    # Check for YAML frontmatter tags
    if ($contentText -match '(?i)tags:\s*\[.*\bhome\b.*\]') {
        $hasHomeTag = $true
    }

    # Check for inline #Home tag
    if ($contentText -match '(?i)#home\b') {
        $hasHomeTag = $true
    }

    if ($hasHomeTag) {
        Write-Host "HAS TAG: $($file.Name)"
        $alreadyHad++
        continue
    }

    # File doesn't have Home tag - need to add it
    $lines = [System.Collections.ArrayList]@($content)

    # Check if it has YAML frontmatter (starts with ---)
    if ($lines.Count -gt 0 -and $lines[0] -eq "---") {
        # Has frontmatter - find the closing --- and add/update tags
        $closingLineIndex = -1

        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -eq "---") {
                $closingLineIndex = $i
                break
            }
        }

        if ($closingLineIndex -gt 0) {
            # Search for existing tags line
            $tagsLineIndex = -1
            for ($i = 1; $i -lt $closingLineIndex; $i++) {
                if ($lines[$i] -match '^tags:\s*') {
                    $tagsLineIndex = $i
                    break
                }
            }

            if ($tagsLineIndex -ge 0) {
                # Update existing tags line - add Home if not present
                $tagsLine = $lines[$tagsLineIndex]
                if ($tagsLine -notmatch '(?i)\bhome\b') {
                    $tagsLine = $tagsLine -replace '(\])', ', Home]'
                    $lines[$tagsLineIndex] = $tagsLine
                }
            } else {
                # Add new tags line before closing ---
                $lines.Insert($closingLineIndex, "tags: [Home]")
            }
        } else {
            # No closing --- found, add after opening
            $lines.Insert(1, "tags: [Home]")
        }
    } else {
        # No frontmatter - create new YAML with Home tag
        $lines.Insert(0, "---")
        $lines.Insert(1, "tags: [Home]")
        $lines.Insert(2, "---")
    }

    # Write back with UTF-8 encoding
    $newContent = $lines -join "`n"
    Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -ErrorAction SilentlyContinue

    Write-Host "ADDED: $($file.Name)"
    $added++
}

Write-Host ""
Write-Host "========== SUMMARY =========="
Write-Host "Added Home tag: $added"
Write-Host "Already had tag: $alreadyHad"
Write-Host "Not found: $notFound"
Write-Host "Skipped: $skipped"
Write-Host "Total processed: $($added + $alreadyHad + $notFound + $skipped)"
