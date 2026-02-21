# Find and fix broken image links in Obsidian vault
# Searches for image embeds that point to non-existent paths and finds the correct location
# Handles character encoding mismatches (like » vs _ _) common in Evernote exports

param(
    [switch]$Fix = $false,
    [int]$Limit = 100
)

$vaultPath = 'D:\Obsidian\Main'
$brokenLinks = @()

# Helper function to normalize a filename for fuzzy matching
function Normalize-ImageFileName {
    param([string]$Name)

    # Convert to lowercase first
    $normalized = $Name.ToLower()

    # Replace common problem characters with underscores
    # » (U+00BB), « (U+00AB), various dashes, special quotes, etc.
    $normalized = $normalized -replace '[\u00AB\u00BB\u2013\u2014\u2018\u2019\u201C\u201D\u2026]', '_'

    # Collapse multiple underscores/spaces into single underscore
    $normalized = $normalized -replace '[\s_]+', '_'

    # Remove any remaining non-ASCII characters
    $normalized = $normalized -replace '[^\x00-\x7F]', ''

    return $normalized
}

# Helper function to extract base prefix for fuzzy matching
function Get-ImageBasePrefix {
    param([string]$Name)

    try {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Name)
    } catch {
        # If path has illegal characters, just use the name directly
        $baseName = $Name -replace '\.[^.]+$', ''
    }

    if (-not $baseName) { return "" }

    # If filename contains _img followed by digits, get everything before it
    if ($baseName -match '^(.+?)_img\d+$') {
        return $Matches[1].ToLower()
    }

    # Otherwise return first 25 chars (if long enough) for prefix matching
    if ($baseName.Length -gt 25) {
        return $baseName.Substring(0, 25).ToLower()
    }

    return $baseName.ToLower()
}

# Get all markdown files
$mdFiles = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse -ErrorAction SilentlyContinue

# Build multiple indices for image lookup
Write-Host 'Building image indices...' -ForegroundColor Gray
$imageIndex = @{}           # Exact filename -> full path
$normalizedIndex = @{}      # Normalized filename -> full path
$prefixIndex = @{}          # Base prefix -> list of full paths

$imageExtensions = @('*.jpg', '*.jpeg', '*.png', '*.gif', '*.webp', '*.svg', '*.ico')

foreach ($ext in $imageExtensions) {
    $imageList = Get-ChildItem -Path $vaultPath -Filter $ext -Recurse -ErrorAction SilentlyContinue
    foreach ($img in $imageList) {
        $fullPath = $img.FullName

        # 1. Exact filename match
        $exactKey = $img.Name.ToLower()
        if (-not $imageIndex.ContainsKey($exactKey)) {
            $imageIndex[$exactKey] = $fullPath
        }

        # 2. Normalized filename match
        $normalizedKey = Normalize-ImageFileName $img.Name
        if (-not $normalizedIndex.ContainsKey($normalizedKey)) {
            $normalizedIndex[$normalizedKey] = $fullPath
        }

        # 3. Prefix-based index
        $prefix = Get-ImageBasePrefix $img.Name
        if ($prefix.Length -ge 15) {
            if (-not $prefixIndex.ContainsKey($prefix)) {
                $prefixIndex[$prefix] = [System.Collections.ArrayList]@()
            }
            [void]$prefixIndex[$prefix].Add($fullPath)
        }
    }
}
Write-Host "Indexed $($imageIndex.Count) images (exact), $($normalizedIndex.Count) (normalized), $($prefixIndex.Count) (prefix)" -ForegroundColor Gray

# Function to find correct image path using multiple strategies
function Find-CorrectImagePath {
    param([string]$imageFileName)

    # Handle filenames with illegal characters (URLs mistakenly parsed as filenames)
    try {
        $imageExtension = [System.IO.Path]::GetExtension($imageFileName).ToLower()
    } catch {
        return $null
    }

    # Strategy 1: Exact filename match
    $fileNameKey = $imageFileName.ToLower()
    if ($imageIndex.ContainsKey($fileNameKey)) {
        return $imageIndex[$fileNameKey]
    }

    # Strategy 2: Normalized filename match
    $normalizedKey = Normalize-ImageFileName $imageFileName
    if ($normalizedIndex.ContainsKey($normalizedKey)) {
        return $normalizedIndex[$normalizedKey]
    }

    # Strategy 3: Prefix-based fuzzy match
    $searchPrefix = Get-ImageBasePrefix $imageFileName
    $normalizedSearchPrefix = Normalize-ImageFileName $searchPrefix

    foreach ($indexPrefix in $prefixIndex.Keys) {
        $normalizedIndexPrefix = Normalize-ImageFileName $indexPrefix

        # Check if prefixes are similar
        if ($normalizedIndexPrefix -like "*$normalizedSearchPrefix*" -or
            $normalizedSearchPrefix -like "*$normalizedIndexPrefix*" -or
            ($normalizedSearchPrefix.Length -ge 15 -and $normalizedIndexPrefix.StartsWith($normalizedSearchPrefix.Substring(0, 15)))) {

            $candidates = $prefixIndex[$indexPrefix]
            foreach ($candidate in $candidates) {
                if ($candidate.ToLower().EndsWith($imageExtension)) {
                    # If filename contains _imgN pattern, try to match the number
                    if ($imageFileName -match '_img(\d+)\.') {
                        $wantedNum = $Matches[1]
                        if ($candidate -match "_img${wantedNum}\.") {
                            return $candidate
                        }
                        # Don't return a mismatched image number
                    } else {
                        return $candidate
                    }
                }
            }
        }
    }

    return $null
}

# Scan markdown files for image embeds
Write-Host 'Scanning for broken image links...' -ForegroundColor Gray
$scanned = 0
foreach ($file in $mdFiles) {
    $scanned++
    if ($scanned % 200 -eq 0) {
        Write-Host "  Scanned $scanned files..." -ForegroundColor DarkGray
    }

    try {
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        if (-not $content) { continue }
    } catch {
        continue
    }

    # Find image embeds: ![[path/to/image.jpg]] or ![[image.jpg]]
    $linkMatches = [regex]::Matches($content, '\!\[\[([^\]]+\.(jpg|jpeg|png|gif|webp|svg|ico))\]\]', 'IgnoreCase')

    foreach ($match in $linkMatches) {
        $imagePath = $match.Groups[1].Value
        $imageFileName = Split-Path $imagePath -Leaf

        # Check if the linked file exists at the specified path
        $fullImagePath = Join-Path $vaultPath $imagePath
        $noteFolder = Split-Path $file.FullName -Parent
        $relativeImagePath = Join-Path $noteFolder $imagePath

        $exists = $false
        try {
            $exists = (Test-Path -LiteralPath $fullImagePath) -or (Test-Path -LiteralPath $relativeImagePath)
        } catch {
            $exists = $false
        }

        if (-not $exists) {
            # Use multiple strategies to find the correct path
            $foundPath = Find-CorrectImagePath $imageFileName
            if ($foundPath) {
                $brokenLinks += @{
                    NoteFile = $file.FullName
                    NoteRelative = $file.FullName.Replace($vaultPath + '\', '')
                    BrokenLink = $imagePath
                    FullMatch = $match.Value
                    ImageFileName = $imageFileName
                    CorrectFullPath = $foundPath
                    CorrectRelPath = $foundPath.Replace($vaultPath + '\', '')
                }
            }
        }
    }
}

Write-Host "`nScan complete. Scanned $scanned files." -ForegroundColor Gray
Write-Host "Found $($brokenLinks.Count) broken image links with available fixes" -ForegroundColor Yellow

if ($brokenLinks.Count -eq 0) {
    Write-Host "No broken image links found!" -ForegroundColor Green
    exit 0
}

# Process the first N broken links
$toProcess = $brokenLinks | Select-Object -First $Limit
$fixed = 0

Write-Host "`n=== Processing first $Limit broken links ===" -ForegroundColor Cyan

foreach ($link in $toProcess) {
    Write-Host "`n[$($fixed + 1)] Note: $($link.NoteRelative)" -ForegroundColor Cyan
    Write-Host "    Broken:  $($link.BrokenLink)" -ForegroundColor Red
    Write-Host "    Correct: $($link.CorrectRelPath)" -ForegroundColor Green

    if ($Fix) {
        # Read file content
        $content = Get-Content -LiteralPath $link.NoteFile -Raw -Encoding UTF8

        # Replace the broken link with the correct one (use forward slashes for Obsidian)
        $oldEmbed = "![[" + $link.BrokenLink + "]]"
        $correctPath = $link.CorrectRelPath.Replace('\', '/')
        $newEmbed = "![[" + $correctPath + "]]"

        $newContent = $content.Replace($oldEmbed, $newEmbed)

        if ($newContent -ne $content) {
            Set-Content -LiteralPath $link.NoteFile -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "    FIXED!" -ForegroundColor Green
            $fixed++
        } else {
            Write-Host "    Could not replace (pattern mismatch)" -ForegroundColor Yellow
        }
    }
}

if ($Fix) {
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Fixed $fixed of $($toProcess.Count) broken links" -ForegroundColor Green
} else {
    Write-Host "`n=== Dry Run ===" -ForegroundColor Yellow
    Write-Host "Run with -Fix parameter to apply corrections" -ForegroundColor Yellow
}
