# fix_onenote_image_paths.ps1
# Fixes broken OneNote image paths by searching for images by timestamp
# The actual images are in .md folders under 20 - Permanent Notes/

param(
    # Path to the Obsidian vault
    [string]$VaultPath = "D:\Obsidian\Main",

    # Limit the number of files to process (0 = no limit)
    [int]$Limit = 0,

    # Actually apply fixes (otherwise dry run)
    [switch]$Fix
)

# Build an index of all "Exported image" files by their timestamp-based filename
Write-Host "Building image index..." -ForegroundColor Cyan
$imageIndex = @{}

# Search recursively for all Exported image files using -Filter (works better than -Include)
$allImages = Get-ChildItem -Path $VaultPath -Recurse -File -Filter "Exported*" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike "*\.obsidian*" -and $_.Name -like "Exported image*" }

Write-Host "Found $($allImages.Count) Exported image files" -ForegroundColor Cyan

foreach ($img in $allImages) {
    # Store by the filename (e.g., "Exported image 20240909143651-0.png")
    $key = $img.Name
    if (-not $imageIndex.ContainsKey($key)) {
        $imageIndex[$key] = @()
    }
    # Store the relative path from vault root
    $relativePath = $img.FullName.Substring($VaultPath.Length + 1).Replace('\', '/')
    $imageIndex[$key] += $relativePath
}
Write-Host "Indexed $($imageIndex.Count) unique image filenames" -ForegroundColor Cyan

# Find all markdown files (excluding directories named .md)
$mdFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notlike "*\.obsidian*" -and
        -not (Test-Path -Path $_.FullName -PathType Container)
    }

Write-Host "Found $($mdFiles.Count) markdown files to check" -ForegroundColor Cyan

$processedCount = 0
$fixedFiles = 0
$fixedLinks = 0
$notFoundImages = @()

foreach ($file in $mdFiles) {
    # Check limit
    if ($Limit -gt 0 -and $fixedFiles -ge $Limit) {
        break
    }

    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
    } catch {
        continue
    }
    if (-not $content) { continue }

    # Check if file contains broken OneNote paths (URL-encoded)
    # Pattern: 12%20-%20OneNote ... .md/Exported%20image
    if ($content -notmatch '12%20-%20OneNote.*?\.md/Exported%20image') {
        continue
    }

    $processedCount++
    $originalContent = $content
    $fileFixCount = 0

    # Find all URL-encoded image references with the broken OneNote path
    # Match: 12%20-%20OneNote/.../Something.md/Exported%20image%20TIMESTAMP.ext
    # Use .*? to match any path segment (including parentheses in folder names)
    $pattern = '12%20-%20OneNote/.*?\.md/Exported%20image%20\d{14}-\d+\.(png|jpg|jpeg|gif|webp)'
    $allMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    foreach ($match in $allMatches) {
        $brokenPath = $match.Value

        # URL-decode the entire path
        $decodedPath = [System.Uri]::UnescapeDataString($brokenPath)

        # Extract just the image filename from the decoded path
        # Pattern: Exported image TIMESTAMP.ext
        if ($decodedPath -match '(Exported image \d{14}-\d+\.(png|jpg|jpeg|gif|webp))$') {
            $imageFileName = $Matches[1]

            # Look up this image in our index
            if ($imageIndex.ContainsKey($imageFileName)) {
                $possiblePaths = $imageIndex[$imageFileName]

                # Prefer paths in "20 - Permanent Notes"
                $bestPath = $possiblePaths | Where-Object { $_ -like "20 - Permanent Notes/*" } | Select-Object -First 1
                if (-not $bestPath) {
                    $bestPath = $possiblePaths[0]
                }

                if ($bestPath) {
                    # URL-encode the new path (but keep forward slashes)
                    $encodedNewPath = [System.Uri]::EscapeDataString($bestPath) -replace '%2F', '/'

                    # Replace in content
                    $content = $content.Replace($brokenPath, $encodedNewPath)
                    $fileFixCount++
                    Write-Host "  Fixed: $imageFileName" -ForegroundColor Green
                }
            } else {
                Write-Host "  Image not indexed: $imageFileName" -ForegroundColor Yellow
                $notFoundImages += @{
                    File = $file.FullName
                    ImageName = $imageFileName
                    OriginalLink = $brokenPath
                }
            }
        } else {
            Write-Host "  Could not extract filename from: $decodedPath" -ForegroundColor Red
        }
    }

    # Save changes if any fixes were made
    if ($fileFixCount -gt 0 -and $content -ne $originalContent) {
        if ($Fix) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
            Write-Host "Updated: $($file.Name) ($fileFixCount fixes)" -ForegroundColor Green
        } else {
            Write-Host "Would update: $($file.Name) ($fileFixCount fixes)" -ForegroundColor Yellow
        }
        $fixedFiles++
        $fixedLinks += $fileFixCount
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Files scanned: $processedCount"
Write-Host "Files with fixes: $fixedFiles"
Write-Host "Total links fixed: $fixedLinks"
if ($notFoundImages.Count -gt 0) {
    Write-Host "Images not found: $($notFoundImages.Count)" -ForegroundColor Yellow
    Write-Host "Sample missing images:"
    $notFoundImages | Select-Object -First 10 | ForEach-Object {
        Write-Host "  - $($_.ImageName)" -ForegroundColor Yellow
    }
}

if (-not $Fix -and $fixedLinks -gt 0) {
    Write-Host ""
    Write-Host "Run with -Fix to apply changes" -ForegroundColor Yellow
}
