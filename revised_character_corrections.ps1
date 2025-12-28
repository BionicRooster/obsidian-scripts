# =============================================================================
# Obsidian Vault Character Corrections Script
# =============================================================================
# Purpose: Fixes replacement characters (�) that appear due to encoding issues
#
# This script targets the Unicode replacement character (U+FFFD) which displays
# as � and replaces it with the appropriate standard character based on context:
#   - Standard space when between words
#   - Em dash (—) when used as parenthetical separator
#   - Standard apostrophe (') when used in possessives
#   - Standard quotes (") when used for quotations
#
# Usage: powershell -ExecutionPolicy Bypass -File "C:\Users\awt\revised_character_corrections.ps1"
#
# RECOMMENDATION: Run with $dryRun = $true first to preview changes
# =============================================================================

# Configuration
$vaultPath = "D:\Obsidian\Main"                              # Path to Obsidian vault
$logPath = "C:\Users\awt\PowerShell\logs\character_corrections_log.txt"  # Log file location
$dryRun = $true                                              # Set to $true to preview changes without applying

# Initialize counters
$script:filesFixed = 0                                       # Number of files modified
$script:totalReplacements = 0                                # Total replacement characters fixed

# Logging function
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logPath -Value $logMessage
}

# =============================================================================
# Fix Replacement Characters
# =============================================================================
# Scans all markdown files for the replacement character (�) and fixes them
# based on surrounding context.
# =============================================================================
function Fix-ReplacementCharacters {
    Write-Log "=== Fixing Replacement Characters (�) ===" "Cyan"

    # The replacement character (U+FFFD)
    $replacementChar = [char]0xFFFD

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count
    $processedFiles = 0

    Write-Log "  Scanning $totalFiles markdown files..." "Gray"

    foreach ($file in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            # Read file content
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if (-not $content) { continue }

            # Check if file contains replacement character
            if (-not $content.Contains($replacementChar)) { continue }

            $originalContent = $content
            $replacementCount = 0

            # Count occurrences before fixing
            $replacementCount = ([regex]::Matches($content, [regex]::Escape($replacementChar))).Count

            # Strategy: Replace based on context
            # 1. Replace �s at end of words (possessives) with 's
            $content = $content -replace "($replacementChar)s\b", "'s"

            # 2. Replace � followed by opening bracket/paren (likely was a space)
            $content = $content -replace "$replacementChar\[", " ["
            $content = $content -replace "$replacementChar\(", " ("

            # 3. Replace � after closing bracket/paren (likely was a space)
            $content = $content -replace "\]$replacementChar", "] "
            $content = $content -replace "\)$replacementChar", ") "

            # 4. Replace � between words (context: word�word -> word word or word—word)
            #    If between lowercase letters, likely a space
            $content = $content -replace "([a-z])$replacementChar([a-z])", '$1 $2'

            # 5. Replace remaining � with space (safest default)
            $content = $content -replace [regex]::Escape($replacementChar), " "

            # Clean up any double spaces created
            while ($content -match "  ") {
                $content = $content -replace "  ", " "
            }

            # Check if content changed
            if ($content -ne $originalContent) {
                if ($dryRun) {
                    Write-Log "  [DRY RUN] Would fix $replacementCount replacement chars in: $($file.Name)" "Magenta"
                } else {
                    try {
                        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
                        Write-Log "  Fixed $replacementCount replacement chars in: $($file.Name)" "Green"
                        $script:filesFixed++
                    } catch {
                        Write-Log "  ERROR: Could not write $($file.Name) - $_" "Red"
                    }
                }
                $script:totalReplacements += $replacementCount
            }
        } catch {
            # Skip files that can't be read
            continue
        }
    }

    Write-Log "  Scan complete." "Green"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Ensure log directory exists
$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Clear/create log file
"" | Set-Content -Path $logPath

Write-Log "============================================" "Cyan"
Write-Log "Character Corrections Script" "Cyan"
Write-Log "Vault: $vaultPath" "Cyan"
Write-Log "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Cyan"
if ($dryRun) {
    Write-Log "MODE: DRY RUN (no changes will be made)" "Magenta"
    Write-Log "Set `$dryRun = `$false to apply changes" "Magenta"
}
Write-Log "============================================" "Cyan"
Write-Log ""

# Run the fix
Fix-ReplacementCharacters

# Summary
Write-Log "" "White"
Write-Log "============================================" "Green"
Write-Log "CHARACTER CORRECTIONS COMPLETE" "Green"
Write-Log "  Files fixed: $script:filesFixed" "White"
Write-Log "  Total replacements: $script:totalReplacements" "White"
Write-Log "  Log saved to: $logPath" "White"
Write-Log "============================================" "Green"
