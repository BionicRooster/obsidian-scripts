# Comprehensive script to find unlinked connections in Obsidian vault
# Outputs results in batches for user review

param(
    [int]$BatchSize = 50,  # Number of connections per batch
    [int]$BatchNumber = 1  # Which batch to display (1-indexed)
)

$vaultPath = "D:\Obsidian\Main"  # Path to Obsidian vault
$cacheFile = "C:\Users\awt\PowerShell\connection_cache.json"  # Cache file for storing results

# Function to check if a mention is NOT linked
function Test-UnlinkedMention {
    param(
        [string]$Content,  # Full content of the file
        [string]$Title     # Title to search for
    )

    # Escape regex special characters in title
    $escaped = [regex]::Escape($Title)

    # Pattern for unlinked mention (whole word, not in brackets)
    # Negative lookbehind for [[ and negative lookahead for ]]
    $unlinkedPattern = "(?<!\[\[)(?<!\[\[[^\]]*\|)\b$escaped\b(?!\]\])(?!\|[^\]]*\]\])"

    # Pattern for linked mention
    $linkedPattern = "\[\[$escaped\]\]|\[\[[^\]]*\|$escaped\]\]|\[\[$escaped\|"

    # Check for unlinked mentions
    $hasUnlinked = [regex]::IsMatch($Content, $unlinkedPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # Check if already fully linked
    $isLinked = [regex]::IsMatch($Content, $linkedPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # Return true if there's an unlinked mention (even if some are linked)
    return $hasUnlinked
}

# Check if cache exists and is recent (less than 1 hour old)
$useCache = $false  # Flag to determine if we should use cached results
if (Test-Path $cacheFile) {
    $cacheAge = (Get-Date) - (Get-Item $cacheFile).LastWriteTime  # Calculate cache age
    if ($cacheAge.TotalHours -lt 1) {
        $useCache = $true  # Cache is fresh, use it
    }
}

if ($useCache) {
    Write-Host "Using cached results..."
    $allConnections = Get-Content $cacheFile | ConvertFrom-Json
} else {
    Write-Host "Scanning vault for unlinked connections..."

    # Get all markdown files
    $allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse

    # Build note title index (map title to path)
    $noteIndex = @{}  # Hashtable mapping title to file path
    foreach ($file in $allFiles) {
        $noteIndex[$file.BaseName] = $file.FullName
    }

    # Filter to meaningful titles (exclude dates, truncated, generic)
    $meaningfulTitles = @()  # Array of titles worth searching for

    foreach ($title in $noteIndex.Keys) {
        # Skip date-based titles
        if ($title -match '^\d{4}-\d{2}-\d{2}') { continue }

        # Skip truncated titles (exactly 20-21 chars often means truncation)
        if ($title.Length -eq 20 -or $title.Length -eq 21) { continue }

        # Skip folder-like names
        if ($title -match '^\d+\s*-\s*') { continue }

        # Skip very short titles
        if ($title.Length -lt 5) { continue }

        # Skip screen clippings and untitled
        if ($title -match '^(Screen clipping|Untitled)') { continue }

        # Skip resource files
        if ($title -match '\.(resources|md)$|_resources$') { continue }

        # Skip numeric-only titles
        if ($title -match '^\d+$') { continue }

        # Skip titles that are too generic (single common words)
        if ($title -match '^(Home|Food|Music|Books|Movies|Travel|Health|Science|Nature|Religion|Politics|Finance|Library|Misc|Recipe|Methods|Replies|Checkout|Swipe|Windows|Linux|Hardware|Japan|Geology|Solar|README|Clippings|attachments)$') { continue }

        $meaningfulTitles += $title
    }

    Write-Host "Found $($meaningfulTitles.Count) meaningful note titles"

    # Collect all connections
    $allConnections = @()  # Array to store found connections
    $processedFiles = 0  # Counter for progress tracking
    $totalFiles = $allFiles.Count  # Total files to process

    foreach ($file in $allFiles) {
        $processedFiles++  # Increment counter

        # Progress update every 200 files
        if ($processedFiles % 200 -eq 0) {
            Write-Host "Processed $processedFiles of $totalFiles files... Found $($allConnections.Count) connections so far"
        }

        # Read file content
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }  # Skip empty/unreadable files

        $sourceTitle = $file.BaseName  # Current file's title

        # Check each meaningful title against this file
        foreach ($targetTitle in $meaningfulTitles) {
            # Skip self-references
            if ($targetTitle -eq $sourceTitle) { continue }

            # Quick check: does the title appear at all?
            if ($content -notmatch [regex]::Escape($targetTitle)) { continue }

            # Detailed check: is it unlinked?
            if (Test-UnlinkedMention -Content $content -Title $targetTitle) {
                # Extract context around the mention
                $escaped = [regex]::Escape($targetTitle)
                $contextMatch = [regex]::Match($content, ".{0,50}$escaped.{0,50}", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                $context = ""  # Variable to hold context snippet
                if ($contextMatch.Success) {
                    $context = ($contextMatch.Value -replace "`r`n|`n", " ").Trim()
                    # Truncate if too long
                    if ($context.Length -gt 120) {
                        $context = $context.Substring(0, 120) + "..."
                    }
                }

                # Create connection record
                $connection = [PSCustomObject]@{
                    SourceFile = $sourceTitle
                    TargetNote = $targetTitle
                    SourcePath = $file.FullName
                    TargetPath = $noteIndex[$targetTitle]
                    Context = $context
                }

                $allConnections += $connection
            }
        }
    }

    Write-Host "`nTotal connections found: $($allConnections.Count)"

    # Cache results
    $allConnections | ConvertTo-Json -Depth 3 | Out-File -FilePath $cacheFile -Encoding UTF8
    Write-Host "Results cached to $cacheFile"
}

# Calculate batch parameters
$totalConnections = $allConnections.Count  # Total number of connections found
$totalBatches = [math]::Ceiling($totalConnections / $BatchSize)  # Total batches needed
$startIndex = ($BatchNumber - 1) * $BatchSize  # Starting index for current batch
$endIndex = [math]::Min($startIndex + $BatchSize, $totalConnections)  # Ending index

Write-Host "`n=========================================="
Write-Host "BATCH $BatchNumber of $totalBatches"
Write-Host "Showing connections $($startIndex + 1) to $endIndex of $totalConnections"
Write-Host "==========================================`n"

# Display this batch
for ($i = $startIndex; $i -lt $endIndex; $i++) {
    $conn = $allConnections[$i]  # Current connection
    $num = $i + 1  # 1-indexed number for display

    Write-Host "$num. [$($conn.SourceFile)] -> [$($conn.TargetNote)]"
    Write-Host "   Context: $($conn.Context)"
    Write-Host ""
}

# Output for next batch command
if ($BatchNumber -lt $totalBatches) {
    Write-Host "`nTo see next batch, run:"
    Write-Host "  .\analyze_connections.ps1 -BatchNumber $($BatchNumber + 1)"
}
