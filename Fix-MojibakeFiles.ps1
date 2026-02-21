<#
.SYNOPSIS
    Identifies and fixes files with mojibake (multi-level encoding corruption).

.DESCRIPTION
    This script detects files containing mojibake - garbled text resulting from
    UTF-8 content being repeatedly misinterpreted through wrong encodings.

    Common symptoms:
    - Sequences like "A?' 'A?" or "A'A A  ?sA "
    - High concentration of characters: Ã (195), Â (194), ¢ (162), â (226), etc.
    - Text mixed with garbage that makes files unreadable

.PARAMETER Path
    The directory to scan for affected files. Defaults to current directory.

.PARAMETER Fix
    Path to a specific file to fix. When provided, skips scanning and fixes this file.

.PARAMETER Recurse
    When scanning, search subdirectories recursively.

.PARAMETER Extension
    File extension to scan. Defaults to "*.md" for Markdown files.

.PARAMETER Threshold
    Minimum percentage of garbage characters to consider a file "affected".
    Defaults to 0.01 (meaning 0.01% or more garbage = affected).
    Set to 0 to flag any file with at least one garbage character.

.PARAMETER DryRun
    When fixing, show what would be changed without actually modifying the file.

.PARAMETER BackupFirst
    Create a .bak backup before modifying the file.

.PARAMETER LogFile
    Path to a log file that tracks which files have already been fixed.
    Files in this log will be skipped during scans. Defaults to mojibake_fixed.log
    in the script directory.

.PARAMETER ClearLog
    Clear the log file of previously fixed files, allowing them to be scanned again.

.EXAMPLE
    .\Fix-MojibakeFiles.ps1 -Path "D:\Obsidian\Main" -Recurse
    Scans the Obsidian vault for affected files.

.EXAMPLE
    .\Fix-MojibakeFiles.ps1 -Fix "D:\Obsidian\Main\SomeFile.md"
    Fixes a specific file.

.EXAMPLE
    .\Fix-MojibakeFiles.ps1 -Fix "D:\Obsidian\Main\SomeFile.md" -DryRun
    Shows what would be fixed without changing the file.

.EXAMPLE
    .\Fix-MojibakeFiles.ps1 -ClearLog
    Clears the log of previously fixed files so they can be scanned again.
#>

param(
    # Directory to scan for affected files
    [string]$Path = ".",

    # Specific file to fix (skips scan mode)
    [string]$Fix = "",

    # Recurse into subdirectories when scanning
    [switch]$Recurse,

    # File extension filter for scanning
    [string]$Extension = "*.md",

    # Percentage threshold of garbage chars to flag a file (default 0.01%)
    # Set to 0 to flag any file with at least one garbage character
    [double]$Threshold = 0.01,

    # Show changes without modifying file
    [switch]$DryRun,

    # Create backup before fixing
    [switch]$BackupFirst,

    # Path to log file tracking fixed files (default: mojibake_fixed.log in script dir)
    [string]$LogFile = "",

    # Clear the log file and start fresh
    [switch]$ClearLog,

    # Automatically fix all affected files found during scan
    [switch]$FixAll
)

# ============================================================================
# LOG FILE SETUP - Track files that have already been fixed
# ============================================================================

# Set default log file path if not provided (same directory as script)
if ($LogFile -eq "") {
    $LogFile = Join-Path $PSScriptRoot "mojibake_fixed.log"
}

# Clear the log file if requested
if ($ClearLog) {
    if (Test-Path $LogFile) {
        Remove-Item $LogFile -Force
        Write-Host "Log file cleared: $LogFile" -ForegroundColor Yellow
    }
    else {
        Write-Host "No log file to clear." -ForegroundColor Gray
    }
    # If only clearing log (no other action), exit
    if ($Fix -eq "" -and $Path -eq ".") {
        exit 0
    }
}

# Load the set of already-fixed files from the log
$FixedFilesSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
if (Test-Path $LogFile) {
    $logEntries = Get-Content $LogFile -ErrorAction SilentlyContinue
    foreach ($entry in $logEntries) {
        if ($entry -and $entry.Trim() -ne "") {
            [void]$FixedFilesSet.Add($entry.Trim())
        }
    }
}

# ============================================================================
# FUNCTION: Add-ToFixedLog
# Records a file as fixed so it won't be processed again
# ============================================================================
function Add-ToFixedLog {
    param(
        [string]$FilePath  # Full path to the file that was fixed
    )
    # Append the file path to the log
    Add-Content -Path $LogFile -Value $FilePath -Encoding UTF8
    # Also add to in-memory set
    [void]$FixedFilesSet.Add($FilePath)
}

# ============================================================================
# GARBAGE CHARACTER DEFINITIONS
# These are the Unicode code points commonly found in mojibake text
# ============================================================================

# Primary garbage characters (high frequency in corrupted files)
$GarbageCharCodes = @(
    # UTF-8 lead bytes misread as Latin-1
    195,   # Ã - Latin capital A with tilde (UTF-8 lead byte misread)
    194,   # Â - Latin capital A with circumflex (UTF-8 lead byte misread)
    197,   # Å - Latin capital A with ring above (common in mojibake)
    196,   # Ä - Latin capital A with diaeresis

    # Common mojibake artifacts
    402,   # ƒ - Latin small f with hook (very common in mojibake)
    8224,  # † - Dagger (common in mojibake patterns)
    8225,  # ‡ - Double dagger
    # Note: Smart quotes (8216, 8217, 8220, 8221) are converted, not removed

    # Other frequent garbage chars
    162,   # ¢ - Cent sign
    226,   # â - Latin small a with circumflex
    8218,  # ‚ - Single low-9 quotation mark
    8364,  # € - Euro sign
    172,   # ¬ - Not sign
    198,   # Æ - Latin capital AE
    353,   # š - Latin small s with caron
    161,   # ¡ - Inverted exclamation mark
    8230,  # … - Horizontal ellipsis
    382,   # ž - Latin small z with caron
    166,   # ¦ - Broken bar
    190,   # ¾ - Vulgar fraction three quarters
    189,   # ½ - Vulgar fraction one half
    188,   # ¼ - Vulgar fraction one quarter
    191,   # ¿ - Inverted question mark
    183,   # · - Middle dot
    157,   # Control character
    129,   # Control character
    128,   # Control character
    141,   # Control character
    143,   # Control character
    144,   # Control character
    152,   # Control character
    163,   # £ - Pound sign (when appearing in garbage context)
    65533  #   - Replacement character (indicates encoding failure)
)

# Build a HashSet for fast lookup
$GarbageCharSet = [System.Collections.Generic.HashSet[int]]::new()
foreach ($code in $GarbageCharCodes) {
    [void]$GarbageCharSet.Add($code)
}

# ============================================================================
# FUNCTION: Test-FileForMojibake
# Analyzes a file and returns info about garbage character presence
# ============================================================================
function Test-FileForMojibake {
    param(
        [string]$FilePath  # Path to the file to analyze
    )

    # Read file content as UTF-8
    try {
        $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    }
    catch {
        # Return error info if file can't be read
        return @{
            Path = $FilePath
            Error = $_.Exception.Message
            IsAffected = $false
        }
    }

    # Skip empty files
    if ($content.Length -eq 0) {
        return @{
            Path = $FilePath
            TotalChars = 0
            GarbageChars = 0
            GarbagePercent = 0
            IsAffected = $false
        }
    }

    # Count garbage characters
    $garbageCount = 0
    $totalChars = $content.Length

    foreach ($char in $content.ToCharArray()) {
        $code = [int]$char
        if ($GarbageCharSet.Contains($code)) {
            $garbageCount++
        }
    }

    # Calculate percentage
    $garbagePercent = [math]::Round(($garbageCount / $totalChars) * 100, 2)

    # Check for the distinctive "A?" pattern that indicates mojibake
    $hasAQPattern = $content -match "A\?'|A'[^a-zA-Z]"

    # Determine if file is affected:
    # - If threshold is 0, flag any file with at least one garbage character
    # - Otherwise use percentage threshold or pattern detection
    $isAffected = if ($Threshold -eq 0) {
        $garbageCount -gt 0
    } else {
        ($garbagePercent -ge $Threshold) -or ($hasAQPattern -and $garbageCount -gt 0)
    }

    # Return analysis results
    return @{
        Path = $FilePath
        TotalChars = $totalChars
        GarbageChars = $garbageCount
        GarbagePercent = $garbagePercent
        HasAQPattern = $hasAQPattern
        IsAffected = $isAffected
    }
}

# ============================================================================
# FUNCTION: Repair-MojibakeFile
# Removes garbage characters and cleans up the file
# ============================================================================
function Repair-MojibakeFile {
    param(
        [string]$FilePath,   # Path to the file to repair
        [switch]$DryRun,     # If true, don't actually modify the file
        [switch]$Backup      # If true, create a .bak backup first
    )

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Processing: $FilePath" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Read the file
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    catch {
        Write-Host "ERROR: Could not read file: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    $originalSize = $content.Length
    Write-Host "Original size: $originalSize characters" -ForegroundColor Yellow

    # ---- PHASE 1: Remove BOM characters from start ----
    # BOM (Byte Order Mark) = U+FEFF (code 65279)
    $bomCount = 0
    while ($content.Length -gt 0 -and [int]$content[0] -eq 65279) {
        $content = $content.Substring(1)
        $bomCount++
    }
    if ($bomCount -gt 0) {
        Write-Host "  Removed $bomCount BOM character(s) from start" -ForegroundColor Gray
    }

    # ---- PHASE 2: Remove garbage character sequences ----
    # Process character by character, detecting and removing garbage runs
    $result = [System.Text.StringBuilder]::new()
    $i = 0
    $removedSequences = 0

    while ($i -lt $content.Length) {
        $char = $content[$i]
        $code = [int]$char

        # Check if this is a standalone garbage character
        if ($GarbageCharSet.Contains($code)) {
            $i++
            continue
        }

        # Check for "A'" or "A" followed by garbage (common mojibake pattern)
        if ($char -eq 'A' -and ($i + 1) -lt $content.Length) {
            $nextChar = $content[$i + 1]
            $nextCode = [int]$nextChar

            # If A is followed by ' or a garbage char, check if it's a garbage sequence
            if ($nextChar -eq "'" -or $GarbageCharSet.Contains($nextCode)) {
                # Scan ahead to measure the garbage run
                $j = $i + 1
                $garbageRun = 0

                while ($j -lt $content.Length -and $j -lt $i + 100) {
                    $testChar = $content[$j]
                    $testCode = [int]$testChar

                    # Characters that are part of garbage sequences
                    if ($GarbageCharSet.Contains($testCode) -or
                        $testChar -eq "'" -or
                        $testChar -eq 'A' -or
                        $testChar -eq '?' -or
                        $testChar -eq '.' -or
                        $testChar -eq ',' -or
                        $testChar -eq '_' -or
                        $testChar -eq ' ') {
                        $garbageRun++
                    }
                    else {
                        break
                    }
                    $j++
                }

                # If we found a significant garbage run (>10 chars), skip it
                if ($garbageRun -gt 10) {
                    $removedSequences++
                    $i = $j
                    continue
                }
            }
        }

        # Keep this character
        [void]$result.Append($char)
        $i++
    }

    $content = $result.ToString()
    Write-Host "  Removed $removedSequences garbage sequences" -ForegroundColor Gray

    # ---- PHASE 3: Clean up leftover punctuation patterns ----
    # After removing garbage, we often have leftover patterns like '' '' '''
    $beforeCleanup = $content.Length
    $content = [regex]::Replace($content, "['\.\,_\s]{4,}", " ")
    $punctuationCleaned = $beforeCleanup - $content.Length
    if ($punctuationCleaned -gt 0) {
        Write-Host "  Cleaned $punctuationCleaned chars of leftover punctuation patterns" -ForegroundColor Gray
    }

    # ---- PHASE 4: Normalize characters ----
    # Convert smart quotes to regular apostrophes
    $content = $content -replace [char]0x2019, "'"  # Right single quote
    $content = $content -replace [char]0x2018, "'"  # Left single quote

    # Remove replacement characters
    $content = $content -replace [char]0xFFFD, ""

    # ---- PHASE 5: Clean whitespace ----
    $content = [regex]::Replace($content, "[ ]{2,}", " ")      # Multiple spaces -> single
    $content = [regex]::Replace($content, "[ ]+`n", "`n")      # Trailing spaces
    $content = [regex]::Replace($content, "`n[ ]+", "`n")      # Leading spaces on lines
    $content = [regex]::Replace($content, "`n{3,}", "`n`n")    # Multiple newlines -> double

    # Trim the whole content
    $content = $content.Trim()

    # ---- RESULTS ----
    $newSize = $content.Length
    $removed = $originalSize - $newSize
    $percentRemoved = if ($originalSize -gt 0) { [math]::Round(($removed / $originalSize) * 100, 1) } else { 0 }

    # Check if any changes were actually made
    $originalContent = [System.Text.Encoding]::UTF8.GetString($bytes)
    $hasChanges = ($content -ne $originalContent)

    Write-Host "`nResults:" -ForegroundColor Green
    Write-Host "  Original: $originalSize chars" -ForegroundColor White
    Write-Host "  Cleaned:  $newSize chars" -ForegroundColor White
    Write-Host "  Removed:  $removed chars ($percentRemoved%)" -ForegroundColor White

    if (-not $hasChanges) {
        Write-Host "`n  WARNING: No actual changes detected!" -ForegroundColor Red
        Write-Host "  The repair patterns did not match the garbage in this file." -ForegroundColor Red

        # Show sample of what garbage chars exist in file
        Write-Host "`n  Garbage characters found in file:" -ForegroundColor Yellow
        $garbageFound = @{}
        foreach ($char in $originalContent.ToCharArray()) {
            $code = [int]$char
            if ($GarbageCharSet.Contains($code)) {
                $charDisplay = if ($code -lt 32) { "CTRL-$code" } else { $char }
                if (-not $garbageFound.ContainsKey($code)) {
                    $garbageFound[$code] = @{ Char = $charDisplay; Count = 0 }
                }
                $garbageFound[$code].Count++
            }
        }
        foreach ($code in $garbageFound.Keys | Sort-Object) {
            $info = $garbageFound[$code]
            Write-Host "    Code $code ($($info.Char)): $($info.Count) occurrences" -ForegroundColor Gray
        }

        # Show a sample of the file content where garbage appears
        Write-Host "`n  Sample context (first garbage occurrence):" -ForegroundColor Yellow
        $firstGarbageIdx = -1
        for ($idx = 0; $idx -lt $originalContent.Length; $idx++) {
            if ($GarbageCharSet.Contains([int]$originalContent[$idx])) {
                $firstGarbageIdx = $idx
                break
            }
        }
        if ($firstGarbageIdx -ge 0) {
            $sampleStart = [Math]::Max(0, $firstGarbageIdx - 30)
            $sampleEnd = [Math]::Min($originalContent.Length, $firstGarbageIdx + 50)
            $sample = $originalContent.Substring($sampleStart, $sampleEnd - $sampleStart)
            Write-Host "    ...${sample}..." -ForegroundColor Gray
        }

        return $false
    }

    # Show preview
    Write-Host "`n--- Preview (first 500 chars) ---" -ForegroundColor Cyan
    $preview = $content.Substring(0, [Math]::Min(500, $content.Length))
    Write-Host $preview -ForegroundColor Gray
    Write-Host "`n---------------------------------" -ForegroundColor Cyan

    # Save or report
    if ($DryRun) {
        Write-Host "`n[DRY RUN] No changes made to file." -ForegroundColor Yellow
    }
    else {
        # Create backup if requested
        if ($Backup) {
            $backupPath = "$FilePath.bak"
            Copy-Item $FilePath $backupPath -Force
            Write-Host "`nBackup created: $backupPath" -ForegroundColor Gray
        }

        # Write the cleaned content
        [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::UTF8)
        Write-Host "`nFile saved successfully!" -ForegroundColor Green

        # Add to the fixed log so it won't be processed again
        Add-ToFixedLog -FilePath $FilePath
        Write-Host "Added to fixed log (won't appear in future scans)" -ForegroundColor Gray
    }

    return $true
}

# ============================================================================
# MAIN SCRIPT LOGIC
# ============================================================================

# Mode 1: Fix a specific file
if ($Fix -ne "") {
    if (-not (Test-Path $Fix)) {
        Write-Host "ERROR: File not found: $Fix" -ForegroundColor Red
        exit 1
    }

    Repair-MojibakeFile -FilePath $Fix -DryRun:$DryRun -Backup:$BackupFirst
    exit 0
}

# Mode 2: Scan for affected files
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  MOJIBAKE FILE SCANNER" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Scanning: $Path"
Write-Host "Pattern:  $Extension"
Write-Host "Recurse:  $Recurse"
Write-Host "Threshold: $Threshold% garbage characters"
Write-Host ""

# Get files to scan
$searchOption = if ($Recurse) { "AllDirectories" } else { "TopDirectoryOnly" }
try {
    $files = Get-ChildItem -Path $Path -Filter $Extension -Recurse:$Recurse -File -ErrorAction Stop
}
catch {
    Write-Host "ERROR: Could not access path: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$totalFiles = $files.Count
Write-Host "Found $totalFiles files to scan...`n" -ForegroundColor Yellow

# Analyze each file
$affectedFiles = @()
$scanned = 0
$skippedFromLog = 0

foreach ($file in $files) {
    $scanned++

    # Progress indicator (every 100 files or for small sets)
    if ($scanned % 100 -eq 0 -or $totalFiles -lt 100) {
        Write-Progress -Activity "Scanning files" -Status "$scanned / $totalFiles" -PercentComplete (($scanned / $totalFiles) * 100)
    }

    # Skip files that have already been fixed (tracked in log)
    if ($FixedFilesSet.Contains($file.FullName)) {
        $skippedFromLog++
        continue
    }

    $result = Test-FileForMojibake -FilePath $file.FullName

    if ($result.IsAffected) {
        $affectedFiles += $result
    }
}

Write-Progress -Activity "Scanning files" -Completed

# Display results
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  SCAN RESULTS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Total files found: $totalFiles"
if ($skippedFromLog -gt 0) {
    Write-Host "Skipped (already fixed): $skippedFromLog" -ForegroundColor Gray
}
Write-Host "Files scanned: $($totalFiles - $skippedFromLog)"
Write-Host "Affected files found: $($affectedFiles.Count)`n"

if ($affectedFiles.Count -eq 0) {
    Write-Host "No files with mojibake detected!" -ForegroundColor Green
}
else {
    Write-Host "Affected files:" -ForegroundColor Yellow
    Write-Host ""

    # Sort by garbage percentage (worst first)
    $affectedFiles = $affectedFiles | Sort-Object -Property GarbagePercent -Descending

    $index = 1
    foreach ($file in $affectedFiles) {
        $relativePath = $file.Path
        if ($file.Path.StartsWith($Path)) {
            $relativePath = $file.Path.Substring($Path.Length).TrimStart('\', '/')
        }

        Write-Host "  [$index] $relativePath" -ForegroundColor White
        Write-Host "      Garbage: $($file.GarbagePercent)% ($($file.GarbageChars) of $($file.TotalChars) chars)" -ForegroundColor Gray
        $index++
    }

    # If FixAll is specified, automatically repair all affected files
    if ($FixAll) {
        Write-Host "`n============================================" -ForegroundColor Green
        Write-Host "  FIXING ALL AFFECTED FILES" -ForegroundColor Green
        Write-Host "============================================`n" -ForegroundColor Green

        $fixed = 0
        $failed = 0

        foreach ($file in $affectedFiles) {
            $result = Repair-MojibakeFile -FilePath $file.Path -DryRun:$DryRun -Backup:$BackupFirst
            if ($result) {
                $fixed++
            }
            else {
                $failed++
            }
        }

        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "  BATCH FIX COMPLETE" -ForegroundColor Cyan
        Write-Host "============================================" -ForegroundColor Cyan
        Write-Host "Successfully fixed: $fixed files" -ForegroundColor Green
        if ($failed -gt 0) {
            Write-Host "Failed/No changes: $failed files" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`n--------------------------------------------" -ForegroundColor Cyan
        Write-Host "To fix a file, run:" -ForegroundColor Yellow
        Write-Host "  .\Fix-MojibakeFiles.ps1 -Fix ""<filepath>"" -DryRun" -ForegroundColor White
        Write-Host "  .\Fix-MojibakeFiles.ps1 -Fix ""<filepath>"" -BackupFirst" -ForegroundColor White
        Write-Host "  .\Fix-MojibakeFiles.ps1 -Path ""<dir>"" -Recurse -FixAll" -ForegroundColor White
        Write-Host ""
    }
}
