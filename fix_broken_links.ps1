# Find and Fix Broken Links in Obsidian Vault

param(
    [switch]$DryRun = $false,
    [switch]$ReportOnly = $false
)

$vaultPath = 'D:\Obsidian\Main'

Write-Host "=== Broken Link Finder ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

# Step 1: Build file index
Write-Host "`nBuilding file index..." -ForegroundColor Gray
$allFiles = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse | Where-Object {
    $_.FullName -notmatch '\\\.obsidian|\\\.trash|\\\.smart-env'
}

# Create lookup tables
$fileByName = @{}  # basename -> full path(s)
$fileByPath = @{}  # relative path (no extension) -> full path

foreach ($file in $allFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $relativePath = $file.FullName.Replace($vaultPath + '\', '').Replace('\', '/').Replace('.md', '')

    # By basename (case-insensitive)
    $key = $baseName.ToLower()
    if (-not $fileByName.ContainsKey($key)) {
        $fileByName[$key] = @()
    }
    $fileByName[$key] += $file.FullName

    # By relative path
    $fileByPath[$relativePath.ToLower()] = $file.FullName
}

Write-Host "Indexed $($allFiles.Count) markdown files"

# Step 2: Find all links and check if they're broken
Write-Host "`nScanning for broken links..." -ForegroundColor Gray

$linkPattern = '\[\[([^\|\]#]+)([#][^\|\]]*)?(\|[^\]]+)?\]\]'
$brokenLinks = @()
$fixableLinks = @()
$unfixableLinks = @()

$processedFiles = 0
foreach ($file in $allFiles) {
    $processedFiles++
    if ($processedFiles % 200 -eq 0) {
        Write-Host "  Processed $processedFiles / $($allFiles.Count) files..." -ForegroundColor DarkGray
    }

    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $matches = [regex]::Matches($content, $linkPattern)

    foreach ($match in $matches) {
        $linkTarget = $match.Groups[1].Value.Trim()
        $anchor = $match.Groups[2].Value  # #heading part
        $alias = $match.Groups[3].Value   # |display text part

        # Skip external links, embeds that start with !
        if ($linkTarget -match '^(http|https|mailto|file):' -or $linkTarget -match '^\!') {
            continue
        }

        # Skip image extensions
        if ($linkTarget -match '\.(png|jpg|jpeg|gif|webp|svg|pdf|mp3|mp4|wav)$') {
            continue
        }

        # Check if target exists
        $targetExists = $false
        $possibleMatches = @()

        # Try exact path match first
        $targetLower = $linkTarget.ToLower()
        if ($fileByPath.ContainsKey($targetLower)) {
            $targetExists = $true
        }
        # Try with .md extension stripped if present
        elseif ($linkTarget -match '\.md$') {
            $withoutExt = $linkTarget -replace '\.md$', ''
            if ($fileByPath.ContainsKey($withoutExt.ToLower())) {
                $targetExists = $true
            }
        }
        # Try basename match
        else {
            $baseTarget = [System.IO.Path]::GetFileName($linkTarget).ToLower()
            if ($fileByName.ContainsKey($baseTarget)) {
                $targetExists = $true
            }
        }

        if (-not $targetExists) {
            # This is a broken link - try to find possible matches
            $searchName = [System.IO.Path]::GetFileName($linkTarget).ToLower()

            # Look for partial matches
            foreach ($key in $fileByName.Keys) {
                if ($key -eq $searchName -or $key -like "*$searchName*" -or $searchName -like "*$key*") {
                    $possibleMatches += $fileByName[$key]
                }
            }

            # Also check if it's a BionicR path that needs updating
            if ($linkTarget -match 'BionicR') {
                $newPath = $linkTarget -replace 'BionicR/', '' -replace 'BionicR\\', ''
                $newPathLower = $newPath.ToLower()
                if ($fileByPath.ContainsKey($newPathLower) -or $fileByPath.ContainsKey("11 - evernote/$newPathLower")) {
                    $possibleMatches += @("11 - Evernote/$newPath")
                }
            }

            $brokenLink = @{
                File = $file.FullName
                RelativeFile = $file.FullName.Replace($vaultPath + '\', '')
                FullMatch = $match.Value
                Target = $linkTarget
                Anchor = $anchor
                Alias = $alias
                PossibleMatches = $possibleMatches | Select-Object -Unique
            }

            $brokenLinks += $brokenLink

            if ($possibleMatches.Count -eq 1) {
                $fixableLinks += $brokenLink
            } elseif ($possibleMatches.Count -gt 1) {
                # Multiple matches - pick the best one
                $brokenLink.BestMatch = $possibleMatches[0]
                $fixableLinks += $brokenLink
            } else {
                $unfixableLinks += $brokenLink
            }
        }
    }
}

Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "Total broken links found: $($brokenLinks.Count)"
Write-Host "  Fixable (match found): $($fixableLinks.Count)" -ForegroundColor Green
Write-Host "  Unfixable (no match): $($unfixableLinks.Count)" -ForegroundColor Yellow

# Group broken links by type
$byPattern = $brokenLinks | Group-Object {
    if ($_.Target -match 'BionicR') { 'BionicR paths' }
    elseif ($_.Target -match '^\[\[') { 'Double brackets' }
    elseif ($_.Target -match '^11 - Evernote') { 'Evernote paths' }
    elseif ($_.Target -match '^12 - OneNote') { 'OneNote paths' }
    elseif ($_.Target -match '^20 - Permanent') { 'Permanent Notes paths' }
    else { 'Other' }
} | Sort-Object Count -Descending

Write-Host "`nBroken links by category:"
foreach ($group in $byPattern) {
    Write-Host "  $($group.Name): $($group.Count)"
}

if ($ReportOnly) {
    Write-Host "`n=== Sample Broken Links ===" -ForegroundColor Cyan
    $brokenLinks | Select-Object -First 30 | ForEach-Object {
        Write-Host "`nFile: $($_.RelativeFile)" -ForegroundColor White
        Write-Host "  Link: $($_.FullMatch)" -ForegroundColor Gray
        Write-Host "  Target: $($_.Target)" -ForegroundColor Yellow
        if ($_.PossibleMatches.Count -gt 0) {
            Write-Host "  Possible: $($_.PossibleMatches -join ', ')" -ForegroundColor Green
        }
    }
    return
}

# Step 3: Fix the broken links
if ($fixableLinks.Count -gt 0 -and -not $ReportOnly) {
    Write-Host "`nFixing broken links..." -ForegroundColor Gray

    $fixedCount = 0
    $filesModified = @{}

    foreach ($link in $fixableLinks) {
        $filePath = $link.File

        # Get or read file content
        if (-not $filesModified.ContainsKey($filePath)) {
            $filesModified[$filePath] = Get-Content -Path $filePath -Raw -Encoding UTF8
        }

        $content = $filesModified[$filePath]

        # Determine the fix
        $newTarget = $null
        if ($link.PossibleMatches.Count -ge 1) {
            $bestMatch = $link.PossibleMatches[0]
            # Convert full path to relative path
            if ($bestMatch -match [regex]::Escape($vaultPath)) {
                $newTarget = $bestMatch.Replace($vaultPath + '\', '').Replace('\', '/').Replace('.md', '')
            } else {
                $newTarget = $bestMatch.Replace('\', '/').Replace('.md', '')
            }
        }

        if ($newTarget) {
            # Build the new link
            $oldLink = [regex]::Escape($link.FullMatch)
            $newLink = "[[$newTarget$($link.Anchor)$($link.Alias)]]"

            $newContent = $content -replace $oldLink, $newLink

            if ($newContent -ne $content) {
                $filesModified[$filePath] = $newContent
                $fixedCount++
                Write-Host "  Fixed: $($link.Target) -> $newTarget" -ForegroundColor DarkGray
            }
        }
    }

    # Write modified files
    if (-not $DryRun) {
        foreach ($filePath in $filesModified.Keys) {
            Set-Content -Path $filePath -Value $filesModified[$filePath] -Encoding UTF8 -NoNewline
        }
    }

    Write-Host "`nFixed $fixedCount links in $($filesModified.Count) files" -ForegroundColor Green
}

# Output unfixable links for manual review
if ($unfixableLinks.Count -gt 0) {
    Write-Host "`n=== Unfixable Links (need manual review) ===" -ForegroundColor Yellow
    $unfixableLinks | Group-Object RelativeFile | Select-Object -First 20 | ForEach-Object {
        Write-Host "`n$($_.Name):" -ForegroundColor White
        $_.Group | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $($_.Target)" -ForegroundColor Gray
        }
        if ($_.Group.Count -gt 5) {
            Write-Host "  ... and $($_.Group.Count - 5) more" -ForegroundColor DarkGray
        }
    }
}

Write-Host "`n=== Complete ===" -ForegroundColor Cyan
