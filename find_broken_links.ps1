# find_broken_links.ps1
# Script to find and optionally delete broken wikilinks in an Obsidian vault
# A broken link is a [[Link]] that points to a note that does not exist

param(
    # Path to the Obsidian vault root directory
    [string]$VaultPath = "D:\Obsidian\Main",

    # If specified, actually delete the broken links from files
    [switch]$Delete,

    # Limit the number of files to process (0 = no limit)
    [int]$Limit = 0,

    # If specified, only show summary without file details
    [switch]$SummaryOnly
)

# Store the start time for performance tracking
$startTime = Get-Date

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Obsidian Broken Link Finder & Remover" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vault Path: $VaultPath" -ForegroundColor Yellow
Write-Host "Delete Mode: $($Delete.IsPresent)" -ForegroundColor Yellow
Write-Host "Limit: $(if ($Limit -eq 0) { 'No limit' } else { $Limit })" -ForegroundColor Yellow
Write-Host ""

# Verify the vault path exists
if (-not (Test-Path $VaultPath)) {
    Write-Host "ERROR: Vault path does not exist: $VaultPath" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Building index of all existing notes..." -ForegroundColor Green

# Get all markdown files in the vault (these are the "existing" notes)
# We store them in a HashSet for O(1) lookup performance
$allMarkdownFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File

# Create a HashSet of all note names (without .md extension) for fast lookup
# We use lowercase for case-insensitive matching (Obsidian is case-insensitive)
$existingNotes = @{}

foreach ($file in $allMarkdownFiles) {
    # Get the note name without the .md extension
    $noteName = $file.BaseName

    # Store in hashtable with lowercase key for case-insensitive lookup
    # Value is the full path for reference
    $existingNotes[$noteName.ToLower()] = $file.FullName
}

$totalNotes = $existingNotes.Count
Write-Host "  Found $totalNotes existing notes in the vault" -ForegroundColor White

Write-Host ""
Write-Host "Step 2: Scanning files for wikilinks..." -ForegroundColor Green

# Regex pattern to match Obsidian wikilinks
# Matches: [[Note Name]] or [[Note Name|Display Text]] or [[Note Name#Heading]]
# Does NOT match image embeds: ![[image.png]]
$wikiLinkPattern = '(?<!!)\[\[([^\]|#]+)(?:[#|][^\]]+)?\]\]'

# Track statistics
$totalLinksFound = 0          # Total number of wikilinks found
$brokenLinksFound = 0         # Number of broken links found
$filesWithBrokenLinks = 0     # Number of files containing broken links
$filesProcessed = 0           # Number of files we've processed
$filesModified = 0            # Number of files we've modified (in delete mode)

# Store broken links for reporting: Key = file path, Value = array of broken link names
$brokenLinksByFile = @{}

# Process each markdown file
$filesToProcess = $allMarkdownFiles
if ($Limit -gt 0) {
    $filesToProcess = $allMarkdownFiles | Select-Object -First $Limit
}

$totalFiles = @($filesToProcess).Count
Write-Host "  Processing $totalFiles markdown files..." -ForegroundColor White

foreach ($file in $filesToProcess) {
    $filesProcessed++

    # Read the file content with UTF-8 encoding
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

    # Skip empty files
    if ([string]::IsNullOrWhiteSpace($content)) {
        continue
    }

    # Find all wikilinks in this file
    $matches = [regex]::Matches($content, $wikiLinkPattern)

    # Track broken links in this specific file
    $brokenInThisFile = @()

    foreach ($match in $matches) {
        $totalLinksFound++

        # Extract the note name from the match (group 1 contains the note name)
        $linkedNoteName = $match.Groups[1].Value.Trim()

        # Check if this note exists (case-insensitive)
        $noteExists = $existingNotes.ContainsKey($linkedNoteName.ToLower())

        if (-not $noteExists) {
            # This is a broken link!
            $brokenLinksFound++
            $brokenInThisFile += @{
                'LinkName' = $linkedNoteName
                'FullMatch' = $match.Value
                'Position' = $match.Index
            }
        }
    }

    # If we found broken links in this file, record them
    if ($brokenInThisFile.Count -gt 0) {
        $filesWithBrokenLinks++
        $brokenLinksByFile[$file.FullName] = $brokenInThisFile
    }

    # Progress indicator every 100 files
    if ($filesProcessed % 100 -eq 0) {
        Write-Host "    Processed $filesProcessed / $totalFiles files..." -ForegroundColor Gray
    }
}

Write-Host "  Scan complete!" -ForegroundColor White

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SCAN RESULTS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total files processed:    $filesProcessed" -ForegroundColor White
Write-Host "Total wikilinks found:    $totalLinksFound" -ForegroundColor White
Write-Host "Broken links found:       $brokenLinksFound" -ForegroundColor $(if ($brokenLinksFound -gt 0) { 'Red' } else { 'Green' })
Write-Host "Files with broken links:  $filesWithBrokenLinks" -ForegroundColor $(if ($filesWithBrokenLinks -gt 0) { 'Red' } else { 'Green' })
Write-Host ""

# If no broken links found, we're done
if ($brokenLinksFound -eq 0) {
    Write-Host "No broken links found! Your vault is clean." -ForegroundColor Green
    exit 0
}

# Display detailed results (unless SummaryOnly is specified)
if (-not $SummaryOnly) {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  BROKEN LINKS BY FILE" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($filePath in $brokenLinksByFile.Keys | Sort-Object) {
        # Get relative path for cleaner display
        $relativePath = $filePath.Replace($VaultPath, "").TrimStart("\")

        Write-Host "FILE: $relativePath" -ForegroundColor Yellow

        $brokenLinks = $brokenLinksByFile[$filePath]
        foreach ($link in $brokenLinks) {
            Write-Host "  -> Broken link: $($link.FullMatch)" -ForegroundColor Red
            Write-Host "     Target note '$($link.LinkName)' does not exist" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

# If Delete mode is enabled, remove the broken links
if ($Delete) {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  DELETING BROKEN LINKS" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($filePath in $brokenLinksByFile.Keys) {
        # Read the current file content
        $content = Get-Content -Path $filePath -Raw
        $originalContent = $content

        # Get the broken links for this file
        $brokenLinks = $brokenLinksByFile[$filePath]

        # Remove each broken link
        # We replace the entire [[Link]] or [[Link|Text]] with just the display text or link name
        foreach ($link in $brokenLinks) {
            $fullMatch = [regex]::Escape($link.FullMatch)

            # Extract display text if present, otherwise use link name
            if ($link.FullMatch -match '\[\[([^\]|]+)\|([^\]]+)\]\]') {
                # Link has display text: [[Note|Display]] -> Display
                $replacement = $Matches[2]
            } else {
                # No display text: [[Note]] -> Note
                $replacement = $link.LinkName
            }

            # Perform the replacement
            $content = $content -replace $fullMatch, $replacement
        }

        # Only write if content actually changed
        if ($content -ne $originalContent) {
            Set-Content -Path $filePath -Value $content -NoNewline
            $filesModified++

            $relativePath = $filePath.Replace($VaultPath, "").TrimStart("\")
            Write-Host "Modified: $relativePath" -ForegroundColor Green
            Write-Host "  Removed $($brokenLinks.Count) broken link(s)" -ForegroundColor Gray
        }
    }

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  DELETION COMPLETE" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Files modified: $filesModified" -ForegroundColor Green
    Write-Host "Broken links removed: $brokenLinksFound" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "  DRY RUN - NO CHANGES MADE" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To actually delete the broken links, run with -Delete parameter:" -ForegroundColor White
    Write-Host "  .\find_broken_links.ps1 -Delete" -ForegroundColor Cyan
}

# Calculate and display elapsed time
$endTime = Get-Date
$elapsed = $endTime - $startTime
Write-Host ""
Write-Host "Elapsed time: $($elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Gray
