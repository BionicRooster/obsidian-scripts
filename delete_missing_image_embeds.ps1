# Delete embeds for images that don't exist anywhere in the vault
# These are truly missing files (not just wrong paths)
# Usage: .\delete_missing_image_embeds.ps1 [-Fix] [-Limit 100]

param(
    [switch]$Fix = $false,  # Actually delete the embeds (default: dry run)
    [int]$Limit = 0         # Limit number of files to process (0 = all)
)

$vaultPath = 'D:\Obsidian\Main'

Write-Host "=== Delete Missing Image Embeds ===" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Fix) { 'FIX' } else { 'DRY RUN' })" -ForegroundColor $(if ($Fix) { 'Yellow' } else { 'Gray' })

# Build index of ALL image files in the vault (by filename only)
Write-Host "`nBuilding image index..." -ForegroundColor Gray
$imageIndex = @{}  # filename (lowercase) -> exists
$imageExtensions = @('*.jpg', '*.jpeg', '*.png', '*.gif', '*.webp', '*.svg', '*.ico', '*.bmp')

foreach ($ext in $imageExtensions) {
    $images = Get-ChildItem -Path $vaultPath -Filter $ext -Recurse -ErrorAction SilentlyContinue
    foreach ($img in $images) {
        $key = $img.Name.ToLower()
        $imageIndex[$key] = $true
    }
}
Write-Host "Indexed $($imageIndex.Count) image files" -ForegroundColor Gray

# Scan markdown files for image embeds
Write-Host "Scanning markdown files..." -ForegroundColor Gray
$mdFiles = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse -ErrorAction SilentlyContinue

$totalMissingEmbeds = 0
$totalFilesWithMissing = 0
$filesProcessed = 0
$embedsRemoved = 0

# Track missing images for summary
$missingImages = @{}

foreach ($file in $mdFiles) {
    # Skip .obsidian and other system folders
    if ($file.FullName -match '\\\.obsidian\\|\\\.smart-env\\|\\\.trash\\') { continue }

    try {
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        if (-not $content) { continue }
    } catch {
        continue
    }

    # Find all image embeds: ![[path/to/image.ext]] or ![[image.ext]]
    # Also match embeds inside markdown links: [![[image.ext]]](url)
    $imagePattern = '\!?\[\[([^\]]+\.(jpg|jpeg|png|gif|webp|svg|ico|bmp))\]\]'
    $matches = [regex]::Matches($content, $imagePattern, 'IgnoreCase')

    if ($matches.Count -eq 0) { continue }

    $missingInFile = @()

    foreach ($match in $matches) {
        $imagePath = $match.Groups[1].Value
        $imageFileName = Split-Path $imagePath -Leaf
        $fileNameKey = $imageFileName.ToLower()

        # Check if this image exists ANYWHERE in the vault
        if (-not $imageIndex.ContainsKey($fileNameKey)) {
            $missingInFile += $match.Value
            $totalMissingEmbeds++

            # Track for summary
            if (-not $missingImages.ContainsKey($imageFileName)) {
                $missingImages[$imageFileName] = 0
            }
            $missingImages[$imageFileName]++
        }
    }

    if ($missingInFile.Count -gt 0) {
        $totalFilesWithMissing++
        $relativePath = $file.FullName.Replace($vaultPath + '\', '')

        Write-Host "`n[$totalFilesWithMissing] $relativePath" -ForegroundColor Cyan
        Write-Host "  Missing embeds: $($missingInFile.Count)" -ForegroundColor Yellow

        foreach ($embed in $missingInFile) {
            # Truncate long embeds for display
            $displayEmbed = if ($embed.Length -gt 80) { $embed.Substring(0, 77) + '...' } else { $embed }
            Write-Host "    - $displayEmbed" -ForegroundColor Red
        }

        if ($Fix) {
            $newContent = $content
            foreach ($embed in $missingInFile) {
                # Remove the embed and any surrounding whitespace/newlines
                # Handle cases like: [![[image]]](url) - remove entire construct
                $escapedEmbed = [regex]::Escape($embed)

                # First try to remove markdown link containing the embed: [![[...]]](url)
                $markdownLinkPattern = '\[' + $escapedEmbed + '\]\([^\)]*\)\s*'
                if ($newContent -match $markdownLinkPattern) {
                    $newContent = $newContent -replace $markdownLinkPattern, ''
                } else {
                    # Just remove the embed itself (and trailing whitespace/newline)
                    $newContent = $newContent -replace ($escapedEmbed + '\s*'), ''
                }
                $embedsRemoved++
            }

            # Clean up any resulting blank lines (more than 2 consecutive)
            $newContent = $newContent -replace '(\r?\n){3,}', "`n`n"

            if ($newContent -ne $content) {
                Set-Content -LiteralPath $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
                Write-Host "  FIXED - Removed $($missingInFile.Count) embeds" -ForegroundColor Green
            }
        }

        $filesProcessed++
        if ($Limit -gt 0 -and $filesProcessed -ge $Limit) {
            Write-Host "`nLimit of $Limit files reached" -ForegroundColor Yellow
            break
        }
    }
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Files with missing image embeds: $totalFilesWithMissing" -ForegroundColor White
Write-Host "Total missing image embeds: $totalMissingEmbeds" -ForegroundColor White

if ($Fix) {
    Write-Host "Embeds removed: $embedsRemoved" -ForegroundColor Green
} else {
    Write-Host "`nRun with -Fix to remove these embeds" -ForegroundColor Yellow
}

# Show top missing images
if ($missingImages.Count -gt 0) {
    Write-Host "`nTop missing images:" -ForegroundColor Gray
    $missingImages.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object {
        Write-Host "  $($_.Value)x  $($_.Key)" -ForegroundColor DarkGray
    }
}
