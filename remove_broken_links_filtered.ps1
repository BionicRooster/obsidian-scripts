# remove_broken_links_filtered.ps1
# Extended broken-link remover for Obsidian vault.
# Improvements over find_broken_links.ps1:
#   - UTF-8 safe read/write via [System.IO.File] (preserves diacriticals)
#   - Skips date refs ([[2026-05-19]]) and numeric folder refs ([[01]], [[10 - Clippings]])
#   - Handles path-qualified links ([[folder/Note]] -> basename lookup)
#   - Removes entire bullet lines when the link is the only content on the line
#   - Delinks (removes brackets, keeps display text) for all other occurrences

param(
    # Root path of the Obsidian vault
    [string]$VaultPath = "C:\Users\awt\Sync\Obsidian",

    # When present, actually modify files; without it, only scans and reports
    [switch]$Delete,

    # Cap the number of files processed (0 = unlimited); useful for testing
    [int]$Limit = 0,

    # Suppress per-file detail; show only totals
    [switch]$SummaryOnly
)

# Start time for elapsed reporting
$startTime = Get-Date

# --- Exclusion patterns (compiled once for efficiency) ---
# Date refs like [[2026-05-19]] — will exist as daily notes
$excludeDateRegex = [regex]'^\\d{4}-\\d{2}-\\d{2}$'

# Numeric folder/section refs like [[01]], [[00 - Home Dashboard]], [[10 - Clippings]]
# Pattern: starts with 1-2 digits optionally followed by space-dash or end of string
$excludeFolderRegex = [regex]'^\\d{1,2}(\\s*-|\\s*$)'

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Broken Link Remover (Filtered + UTF-8)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Vault:   $VaultPath" -ForegroundColor Yellow
Write-Host "Delete:  $($Delete.IsPresent)" -ForegroundColor Yellow
Write-Host "Limit:   $(if ($Limit -eq 0) { 'None' } else { $Limit })" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $VaultPath)) {
    Write-Host "ERROR: Vault path does not exist: $VaultPath" -ForegroundColor Red
    exit 1
}

# -------------------------------------------------------
# Step 1: Build the note name index
# All .md basenames stored lowercase for case-insensitive O(1) lookup
# -------------------------------------------------------
Write-Host "Building note index..." -ForegroundColor Green
$allMarkdownFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File

# Hashtable: lowercase basename -> full path
$existingNotes = @{}
foreach ($file in $allMarkdownFiles) {
    $existingNotes[$file.BaseName.ToLower()] = $file.FullName
}

Write-Host "  $($existingNotes.Count) notes indexed" -ForegroundColor White
Write-Host ""

# -------------------------------------------------------
# Step 2: Scan all files for broken wikilinks
# -------------------------------------------------------
# Regex: matches [[Note]], [[Note|Alias]], [[Note#Heading]]
# Negative lookbehind (?<!!) excludes image embeds like ![[image.png]]
$wikiLinkPattern = '(?<!!)\[\[([^\]|#]+)(?:[#|][^\]]+)?\]\]'

# Counters
$totalLinksFound    = 0  # all wikilinks encountered
$brokenLinksFound   = 0  # wikilinks with no matching vault note
$skippedExclusions  = 0  # links skipped by date/folder exclusion rules
$filesWithBroken    = 0  # files containing at least one broken link
$filesProcessed     = 0  # total files examined
$filesModified      = 0  # files actually rewritten (delete mode only)

# Map: full file path -> array of PSCustomObject{RawTarget, LookupName, FullMatch}
$brokenLinksByFile = @{}

Write-Host "Scanning for broken wikilinks..." -ForegroundColor Green

# Apply limit if set
$filesToProcess = if ($Limit -gt 0) {
    $allMarkdownFiles | Select-Object -First $Limit
} else {
    $allMarkdownFiles
}
$totalFiles = @($filesToProcess).Count
Write-Host "  $totalFiles files to process..." -ForegroundColor White

foreach ($file in $filesToProcess) {
    $filesProcessed++

    # Read with explicit UTF-8 to preserve diacriticals (Bahá'í, Riḍván, etc.)
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    # Find all wikilinks in this file
    $linkMatches = [regex]::Matches($content, $wikiLinkPattern)

    # Broken links found in this specific file
    $brokenInThisFile = @()

    foreach ($m in $linkMatches) {
        $totalLinksFound++

        # Raw target text (may include path prefix like "folder/Note")
        $rawTarget = $m.Groups[1].Value.Trim()

        # For path-qualified links like [[00 - Home Dashboard/MOC - Technology]],
        # extract just the basename ("MOC - Technology") for vault index lookup
        $lookupName = if ($rawTarget -match '/') {
            $rawTarget -replace '^.*/', ''
        } else {
            $rawTarget
        }

        # Exclusion 1: date refs (future daily notes, not broken)
        if ($excludeDateRegex.IsMatch($lookupName)) {
            $skippedExclusions++
            continue
        }

        # Exclusion 2: numeric folder/section refs (valid navigation targets)
        if ($excludeFolderRegex.IsMatch($lookupName)) {
            $skippedExclusions++
            continue
        }

        # Check if the target note exists (case-insensitive)
        if (-not $existingNotes.ContainsKey($lookupName.ToLower())) {
            $brokenLinksFound++
            $brokenInThisFile += [PSCustomObject]@{
                RawTarget  = $rawTarget    # full target as written (may have folder prefix)
                LookupName = $lookupName   # basename used for lookup (used as replacement text)
                FullMatch  = $m.Value      # the entire [[...]] token to replace
            }
        }
    }

    if ($brokenInThisFile.Count -gt 0) {
        $filesWithBroken++
        $brokenLinksByFile[$file.FullName] = $brokenInThisFile
    }

    # Progress report every 200 files
    if ($filesProcessed % 200 -eq 0) {
        Write-Host "    $filesProcessed / $totalFiles..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  SCAN RESULTS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Files processed:          $filesProcessed" -ForegroundColor White
Write-Host "Total wikilinks found:    $totalLinksFound" -ForegroundColor White
Write-Host "Links excluded (date/dir):$skippedExclusions" -ForegroundColor Gray
Write-Host "Broken links found:       $brokenLinksFound" -ForegroundColor $(if ($brokenLinksFound -gt 0) { 'Red' } else { 'Green' })
Write-Host "Files with broken links:  $filesWithBroken" -ForegroundColor $(if ($filesWithBroken -gt 0) { 'Red' } else { 'Green' })
Write-Host ""

if ($brokenLinksFound -eq 0) {
    Write-Host "Vault is clean -- no broken links found." -ForegroundColor Green
    $elapsed = (Get-Date) - $startTime
    Write-Host "Elapsed: $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Gray
    exit 0
}

# Show per-file detail unless -SummaryOnly
if (-not $SummaryOnly) {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  BROKEN LINKS BY FILE" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    foreach ($filePath in ($brokenLinksByFile.Keys | Sort-Object)) {
        $rel = $filePath.Replace($VaultPath, "").TrimStart("\")
        Write-Host "FILE: $rel" -ForegroundColor Yellow
        foreach ($link in $brokenLinksByFile[$filePath]) {
            Write-Host "  -> $($link.FullMatch)  (lookup: $($link.LookupName))" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# -------------------------------------------------------
# Stop here if not in delete mode
# -------------------------------------------------------
if (-not $Delete) {
    Write-Host "Dry run -- no changes made." -ForegroundColor Yellow
    Write-Host "Run with -Delete to fix all broken links." -ForegroundColor White
    $elapsed = (Get-Date) - $startTime
    Write-Host "Elapsed: $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Gray
    exit 0
}

# -------------------------------------------------------
# Step 3: Fix broken links in each affected file
# -------------------------------------------------------
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  REMOVING BROKEN LINKS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($filePath in $brokenLinksByFile.Keys) {
    # Read with UTF-8 (same as scan pass — must match to avoid re-encoding)
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    $originalContent = $content

    foreach ($link in $brokenLinksByFile[$filePath]) {
        # Escape the full [[...]] token for use as a regex pattern
        $escapedToken = [regex]::Escape($link.FullMatch)

        # Determine replacement display text:
        # - [[Note|Alias]] -> "Alias"  (explicit alias wins)
        # - [[Note]] -> "Note" basename (no folder prefix)
        if ($link.FullMatch -match '\[\[([^\]|]+)\|([^\]]+)\]\]') {
            # Has explicit alias: use the alias part
            $displayText = $Matches[2]
        } else {
            # No alias: use the lookup name (basename, no folder prefix)
            $displayText = $link.LookupName
        }

        # --- Fix 1: Remove standalone bullet lines ---
        # If a line is ONLY "- [[BrokenNote]]" (nothing else), remove the entire line.
        # This avoids leaving dangling "- BrokenNote" bullets in Related Notes sections.
        # Pattern matches: optional leading spaces, dash, spaces, [[link]], trailing spaces, newline
        $bulletPattern = "(?m)^[ \t]*-[ \t]*" + $escapedToken + "[ \t]*\r?\n?"
        $content = [regex]::Replace($content, $bulletPattern, "")

        # --- Fix 2: Delink remaining inline occurrences ---
        # Any [[BrokenNote]] not in a standalone bullet becomes plain text.
        # (After Fix 1 removed the bullet lines, only inline occurrences remain.)
        $content = [regex]::Replace($content, $escapedToken, $displayText)
    }

    # Only rewrite if content actually changed
    if ($content -ne $originalContent) {
        # Write with UTF-8 (no BOM) to match Obsidian's expected encoding
        [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
        $filesModified++

        if (-not $SummaryOnly) {
            $rel = $filePath.Replace($VaultPath, "").TrimStart("\")
            Write-Host "Fixed: $rel  ($($brokenLinksByFile[$filePath].Count) link(s))" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Files modified:        $filesModified" -ForegroundColor Green
Write-Host "Broken links removed:  $brokenLinksFound" -ForegroundColor Green

$elapsed = (Get-Date) - $startTime
Write-Host "Elapsed: $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Gray
