# Script to find potential unlinked connections in Obsidian vault
# This script searches for note titles mentioned in other notes that aren't already linked

# Parameters
$vaultPath = "D:\Obsidian\Main"  # Path to the Obsidian vault
$outputFile = "C:\Users\awt\PowerShell\unlinked_connections.csv"  # Output file path

# Get all markdown files in the vault
$allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse

# Build a hashtable of note titles (basename without extension) to their full paths
$noteTitles = @{}  # Hashtable mapping note title to file path
foreach ($file in $allFiles) {
    $title = $file.BaseName  # Get the file name without extension
    if (-not $noteTitles.ContainsKey($title)) {
        $noteTitles[$title] = $file.FullName  # Store first occurrence
    }
}

# Filter note titles to only meaningful ones (exclude dates, truncated names, etc.)
$meaningfulTitles = @()  # Array to hold filtered meaningful titles
foreach ($title in $noteTitles.Keys) {
    # Skip titles that are just dates (YYYY-MM-DD format)
    if ($title -match '^\d{4}-\d{2}-\d{2}') { continue }

    # Skip titles that look truncated (end abruptly, likely OS limit)
    if ($title.Length -eq 20 -or $title.Length -eq 21) { continue }

    # Skip generic folder names
    if ($title -match '^(\d+\s*-\s*(Evernote|OneNote|Journal|Home|Images|Working|Completed|Indexes|Templates|Kanban|Kindle|Clippings|Bases|People|Organizations|Permanent|attachments))') { continue }

    # Skip very short titles (likely not meaningful for linking)
    if ($title.Length -lt 4) { continue }

    # Skip titles starting with "Screen clipping" or "Untitled"
    if ($title -match '^(Screen clipping|Untitled)') { continue }

    # Skip titles that are mostly numbers
    if ($title -match '^\d+$') { continue }

    # Skip titles with .resources or _resources suffix
    if ($title -match '\.(resources|md)$|_resources$') { continue }

    # Add to meaningful titles
    $meaningfulTitles += $title
}

Write-Host "Found $($meaningfulTitles.Count) meaningful note titles to search for"

# Results collection
$connections = @()  # Array to hold discovered unlinked connections

# Search each file for mentions of meaningful titles
$fileCount = 0  # Counter for progress tracking
$totalFiles = $allFiles.Count  # Total number of files to process

foreach ($file in $allFiles) {
    $fileCount++  # Increment file counter

    # Show progress every 100 files
    if ($fileCount % 100 -eq 0) {
        Write-Host "Processing file $fileCount of $totalFiles..."
    }

    # Read file content
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }  # Skip empty files or files that couldn't be read

    $sourceTitle = $file.BaseName  # Title of the current file being searched

    # Search for each meaningful title in this file's content
    foreach ($targetTitle in $meaningfulTitles) {
        # Skip self-references (don't link a note to itself)
        if ($targetTitle -eq $sourceTitle) { continue }

        # Skip if target title is too generic (common words)
        if ($targetTitle -match '^(Home|Books|Movies|Music|Food|Travel|Health|Finance|Science|Nature|Religion|Politics|Entertainment|Library|Misc|Clippings|Recipes|Methods|Replies|Recipe|PT|DNA|NLP|FOL|README|Checkout|Swipe|Buddhism|Christianity|Judaism|Geology|Genealogy|Geneology|Contracting|Investing|Programming|Windows|Linux|Hardware|Desktops|Hypnosis|Japan|Archaeology|Pilgrimage|Vacations|Solar|ChatGPT|Perplexity|Google|Mylio)$') { continue }

        # Escape special regex characters in the title
        $escapedTitle = [regex]::Escape($targetTitle)

        # Check if the title is mentioned but NOT already linked
        # Look for the title as a whole word, case insensitive
        # But exclude if it's inside [[ ]] brackets

        # Pattern to find the title as a whole word
        $wordPattern = "(?<!\[\[)(?<!\|)\b$escapedTitle\b(?!\]\])(?!\|)"

        # Check if there's an unlinked mention
        if ($content -match $wordPattern) {
            # Verify it's not already linked by checking for [[title]] pattern
            $linkedPattern = "\[\[$escapedTitle\]\]|\[\[[^\]]*\|$escapedTitle\]\]|\[\[$escapedTitle\|"

            # Only add if there's an unlinked mention
            if ($content -match $wordPattern -and -not ($content -match "^\s*#.*$escapedTitle" -and $content -notmatch $wordPattern)) {
                # Get a snippet of context around the mention
                $match = [regex]::Match($content, ".{0,50}$escapedTitle.{0,50}", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                $context = if ($match.Success) { $match.Value -replace "`r`n|`n", " " } else { "" }

                # Create connection object
                $connection = [PSCustomObject]@{
                    SourceFile = $sourceTitle  # The file containing the mention
                    TargetNote = $targetTitle  # The note being mentioned
                    SourcePath = $file.FullName  # Full path to source file
                    TargetPath = $noteTitles[$targetTitle]  # Full path to target note
                    Context = $context.Substring(0, [Math]::Min(100, $context.Length))  # Snippet of text around mention
                }

                $connections += $connection
            }
        }
    }
}

Write-Host "Found $($connections.Count) potential unlinked connections"

# Export results to CSV
$connections | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Results exported to $outputFile"
