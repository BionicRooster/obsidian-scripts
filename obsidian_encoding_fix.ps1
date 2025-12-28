# =============================================================================
# Obsidian Vault Encoding Fix Script (ISOLATED - USE WITH CAUTION)
# =============================================================================
# Purpose: Attempts to repair UTF-8 encoding corruption (mojibake) in markdown files
#
# WARNING: This script has caused corruption in some notes. It has been isolated
# from the main maintenance script until the best approach can be determined.
#
# What it attempts to fix:
#   - Smart quotes/apostrophes: curly quotes -> straight quotes
#   - Dashes: em/en dashes -> standard dashes
#   - Non-breaking spaces: NBSP -> regular space
#   - BOM: Removes UTF-8 BOM marker from start of files
#   - Double-encoded mojibake patterns
#   - Corrupted horizontal line characters (box-drawing mojibake)
#
# Usage: powershell -ExecutionPolicy Bypass -File "C:\Users\awt\obsidian_encoding_fix.ps1"
#
# RECOMMENDATION: Run with $dryRun = $true first to preview changes
# =============================================================================

# Configuration
$vaultPath = "D:\Obsidian\Main"                              # Path to Obsidian vault
$logPath = "C:\Users\awt\PowerShell\logs\obsidian_encoding_fix_log.txt"  # Log file location
$dryRun = $true                                              # SET TO $true FOR SAFETY - preview changes first

# Initialize counters
$script:encodingIssuesFixed = 0
$script:corruptedLinesFixed = 0

# Logging function
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logPath -Value $logMessage
}

# =============================================================================
# PHASE 1: Fix UTF-8 encoding corruption (mojibake)
# =============================================================================
# Repairs common UTF-8 encoding issues using byte-level operations:
#   - Smart quotes/apostrophes: curly quotes -> straight quotes
#   - Dashes: em/en dashes -> standard dashes
#   - Non-breaking spaces: NBSP -> regular space
#   - BOM: Removes UTF-8 BOM marker from start of files
#   - Double-encoded mojibake patterns
# Uses byte-level operations to avoid encoding issues during read/write.
# =============================================================================

# Define encoding patterns as hex strings and their UTF-8 replacements
# Pattern = mojibake bytes in hex, Replacement = correct UTF-8 bytes in hex
$script:encodingPatterns = @(
    # Right single quote (most common: displays as special chars)
    @{ Find = "C3A2E282ACE284A2"; Replace = "27" },      # Double-encoded -> '
    @{ Find = "E28099"; Replace = "27" },                 # Curly apostrophe -> '

    # Left single quote
    @{ Find = "C3A2E282ACCB9C"; Replace = "27" },        # Double-encoded -> '
    @{ Find = "E28098"; Replace = "27" },                 # Curly left quote -> '

    # Left double quote
    @{ Find = "C3A2E282ACC593"; Replace = "22" },        # Double-encoded -> "
    @{ Find = "E2809C"; Replace = "22" },                 # Curly left double -> "

    # Right double quote
    @{ Find = "C3A2E282ACC29D"; Replace = "22" },        # Double-encoded -> "
    @{ Find = "E2809D"; Replace = "22" },                 # Curly right double -> "

    # Em dash
    @{ Find = "C3A2E282ACE2809C"; Replace = "2D2D" },    # Double-encoded -> --
    @{ Find = "E28094"; Replace = "2D2D" },              # Em dash -> --

    # En dash
    @{ Find = "C3A2E282ACE28093"; Replace = "2D" },      # Double-encoded -> -
    @{ Find = "E28093"; Replace = "2D" },                 # En dash -> -

    # Non-breaking space corruption
    @{ Find = "C382C2A0"; Replace = "20" },              # Double-encoded NBSP -> space
    @{ Find = "C2A0"; Replace = "20" },                   # NBSP -> space

    # Corrupted checkbox/bullet
    @{ Find = "C3A2E296A2"; Replace = "2D" },            # Corrupted ballot box -> -

    # BOM
    @{ Find = "EFBBBF"; Replace = "" },                   # Remove BOM

    # Ellipsis
    @{ Find = "C3A2E282ACE2809A"; Replace = "2E2E2E" },  # Double-encoded -> ...
    @{ Find = "E280A6"; Replace = "2E2E2E" },             # Ellipsis -> ...

    # Bullet
    @{ Find = "C3A2E282ACE280A2"; Replace = "E280A2" }   # Double-encoded -> proper bullet
)

# Converts a hex string to a byte array with explicit typing
function Convert-EncodingHexToBytes {
    param([string]$hex)

    # Return empty byte array for null/empty input
    if ([string]::IsNullOrEmpty($hex)) {
        return [byte[]]@()
    }

    # Create byte array of correct size
    [byte[]]$bytes = New-Object byte[] ($hex.Length / 2)

    # Convert each hex pair to a byte
    for ($i = 0; $i -lt $hex.Length; $i += 2) {
        $bytes[$i / 2] = [Convert]::ToByte($hex.Substring($i, 2), 16)
    }

    # Return with explicit type to prevent PowerShell array unrolling
    return ,[byte[]]$bytes
}

# Find byte pattern in source array starting at given index
function Find-EncodingBytePattern {
    param(
        [byte[]]$source,
        [byte[]]$pattern,
        [int]$startIndex
    )

    if ($pattern.Length -eq 0 -or $source.Length -eq 0) { return -1 }

    for ($i = $startIndex; $i -le $source.Length - $pattern.Length; $i++) {
        $found = $true
        for ($j = 0; $j -lt $pattern.Length; $j++) {
            if ($source[$i + $j] -ne $pattern[$j]) {
                $found = $false
                break
            }
        }
        if ($found) { return $i }
    }
    return -1
}

# Replace all occurrences of find pattern with replace pattern in byte array
function Replace-EncodingBytePattern {
    param(
        [byte[]]$source,
        [byte[]]$find,
        [byte[]]$replace
    )

    # Create a List to build the result
    $result = New-Object System.Collections.Generic.List[byte]
    $i = 0
    $matchCount = 0  # Track actual matches for verification

    while ($i -lt $source.Length) {
        $pos = Find-EncodingBytePattern -source $source -pattern $find -startIndex $i
        if ($pos -eq -1) {
            # No more matches, copy remaining bytes
            for ($j = $i; $j -lt $source.Length; $j++) {
                $result.Add($source[$j])
            }
            break
        }
        else {
            $matchCount++
            # Copy bytes before the match
            for ($j = $i; $j -lt $pos; $j++) {
                $result.Add($source[$j])
            }
            # Add replacement bytes (if any - empty replacement removes the pattern)
            if ($replace -ne $null -and $replace.Length -gt 0) {
                foreach ($b in $replace) {
                    $result.Add($b)
                }
            }
            # Advance past the matched pattern
            $i = $pos + $find.Length
        }
    }

    # Return results - use explicit byte array cast
    [byte[]]$outputBytes = $result.ToArray()
    $wasModified = ($matchCount -gt 0)

    return [PSCustomObject]@{
        Bytes = $outputBytes
        Modified = $wasModified
        MatchCount = $matchCount
    }
}

function Fix-EncodingCorruption {
    Write-Log "=== Phase 1: Fixing UTF-8 encoding corruption ===" "Cyan"

    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $filesFixed = 0
    $filesSkipped = 0

    foreach ($file in $mdFiles) {
        try {
            # Read original bytes with explicit type
            [byte[]]$originalBytes = [System.IO.File]::ReadAllBytes($file.FullName)
            [byte[]]$currentBytes = $originalBytes.Clone()  # Clone to avoid reference issues
            $fileModified = $false

            foreach ($p in $script:encodingPatterns) {
                # Convert hex patterns to byte arrays with explicit typing
                [byte[]]$findBytes = Convert-EncodingHexToBytes $p.Find
                [byte[]]$replaceBytes = Convert-EncodingHexToBytes $p.Replace

                if ($findBytes.Length -gt 0) {
                    $result = Replace-EncodingBytePattern -source $currentBytes -find $findBytes -replace $replaceBytes
                    if ($result.Modified) {
                        # Explicitly cast to byte array to prevent type coercion
                        [byte[]]$currentBytes = $result.Bytes
                        $fileModified = $true
                    }
                }
            }

            if ($fileModified) {
                # Verify the bytes actually changed before writing
                $bytesAreDifferent = ($currentBytes.Length -ne $originalBytes.Length)
                if (-not $bytesAreDifferent) {
                    for ($i = 0; $i -lt $currentBytes.Length; $i++) {
                        if ($currentBytes[$i] -ne $originalBytes[$i]) {
                            $bytesAreDifferent = $true
                            break
                        }
                    }
                }

                if ($bytesAreDifferent) {
                    if ($dryRun) {
                        Write-Log "  [DRY RUN] Would fix encoding: $($file.Name)" "Magenta"
                        $filesFixed++
                    } else {
                        try {
                            # Write the modified bytes
                            [System.IO.File]::WriteAllBytes($file.FullName, [byte[]]$currentBytes)
                            $filesFixed++
                        } catch {
                            # File may be locked, log and continue
                            $filesSkipped++
                            Write-Log "  LOCKED: $($file.Name)" "DarkYellow"
                        }
                    }
                }
            }
        } catch {
            # Skip files that can't be read
            $filesSkipped++
        }
    }

    $script:encodingIssuesFixed = $filesFixed
    if ($filesSkipped -gt 0) {
        Write-Log "  Fixed encoding in $filesFixed files ($filesSkipped skipped - locked)" "Green"
    } else {
        Write-Log "  Fixed encoding in $filesFixed files" "Green"
    }
}

# =============================================================================
# PHASE 2: Fix corrupted horizontal line characters
# =============================================================================
# Repairs corrupted box-drawing horizontal line characters (mojibake).
# The pattern C3 A2 22 E2 82 AC (6 bytes) repeated is the corrupted form
# of the Unicode box-drawing character. Replaces with markdown horizontal rule.
# =============================================================================
function Fix-CorruptedHorizontalLines {
    Write-Log "=== Phase 2: Fixing corrupted horizontal lines ===" "Cyan"

    # The corrupted 6-byte sequence (box-drawing horizontal line mojibake)
    [byte[]]$corruptedPattern = @(0xC3, 0xA2, 0x22, 0xE2, 0x82, 0xAC)

    $filesFixed = 0

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

    foreach ($file in $mdFiles) {
        try {
            # Read file as bytes
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            if ($bytes.Length -lt 6) { continue }

            # Quick check: does file contain the corrupted pattern?
            $containsPattern = $false
            for ($i = 0; $i -le $bytes.Length - 6; $i++) {
                $match = $true
                for ($j = 0; $j -lt 6; $j++) {
                    if ($bytes[$i + $j] -ne $corruptedPattern[$j]) {
                        $match = $false
                        break
                    }
                }
                if ($match) {
                    $containsPattern = $true
                    break
                }
            }

            if (-not $containsPattern) { continue }

            # Convert to string for line-by-line processing
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)
            $lines = $content -split "`n"
            $modified = $false

            # Build the corrupted string pattern for comparison
            $corruptedString = [System.Text.Encoding]::UTF8.GetString($corruptedPattern)

            for ($i = 0; $i -lt $lines.Length; $i++) {
                $line = $lines[$i].TrimEnd("`r")

                # Check if line consists entirely of the corrupted pattern repeated
                if ($line.Length -ge 6 -and $line.Contains($corruptedString)) {
                    $checkLine = $line

                    # Remove all occurrences of the corrupted pattern
                    while ($checkLine.Contains($corruptedString)) {
                        $checkLine = $checkLine.Replace($corruptedString, "")
                    }

                    # If nothing remains, it was a corrupted horizontal line
                    if ($checkLine.Trim().Length -eq 0) {
                        $lines[$i] = "---"
                        $modified = $true
                        $script:corruptedLinesFixed++
                    }
                }
            }

            if ($modified) {
                if ($dryRun) {
                    Write-Log "  [DRY RUN] Would fix corrupted lines in: $($file.Name)" "Magenta"
                } else {
                    $newContent = $lines -join "`n"
                    $newBytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
                    [System.IO.File]::WriteAllBytes($file.FullName, $newBytes)
                    $filesFixed++
                }
            }
        } catch {
            # Skip files that can't be read or written
            continue
        }
    }

    Write-Log "  Fixed $($script:corruptedLinesFixed) corrupted lines in $filesFixed files" "Green"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Clear/create log file
"" | Set-Content -Path $logPath

Write-Log "============================================" "Cyan"
Write-Log "Obsidian Encoding Fix Script (ISOLATED)" "Cyan"
Write-Log "Vault: $vaultPath" "Cyan"
Write-Log "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Cyan"
if ($dryRun) {
    Write-Log "MODE: DRY RUN (no changes will be made)" "Magenta"
    Write-Log "Set `$dryRun = `$false to apply changes" "Magenta"
}
Write-Log "============================================" "Cyan"
Write-Log ""

# Run encoding fix phases
Fix-EncodingCorruption
Fix-CorruptedHorizontalLines

# Summary
Write-Log "" "White"
Write-Log "============================================" "Green"
Write-Log "ENCODING FIX COMPLETE" "Green"
Write-Log "  Encoding issues fixed: $script:encodingIssuesFixed" "White"
Write-Log "  Corrupted lines fixed: $script:corruptedLinesFixed" "White"
Write-Log "  Log saved to: $logPath" "White"
Write-Log "============================================" "Green"
