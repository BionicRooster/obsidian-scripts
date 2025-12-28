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
#   - Em dash (—) when "â"€" mojibake pattern appears
#   - Em dash (—) when triple-encoded mojibake pattern appears
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
$script:filesFixed = 0                                       # Number of files modified for replacement char fix
$script:totalReplacements = 0                                # Total replacement characters fixed
$script:emDashFilesFixed = 0                                 # Number of files modified for em dash fix
$script:emDashReplacements = 0                               # Total em dash mojibakes fixed
$script:tripleEncFilesFixed = 0                              # Number of files modified for triple-encoded fix
$script:tripleEncReplacements = 0                            # Total triple-encoded mojibakes fixed
$script:hyphenFilesFixed = 0                                 # Number of files modified for hyphen fix
$script:hyphenReplacements = 0                               # Total hyphen mojibakes fixed
$script:checkmarkFilesFixed = 0                              # Number of files modified for checkmark fix
$script:checkmarkReplacements = 0                            # Total checkmark mojibakes fixed

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
# Fix Em Dash Mojibake (â"€)
# =============================================================================
# Scans all markdown files for the "â"€" mojibake pattern and replaces with
# proper em dash (—). This pattern occurs when UTF-8 encoded em dashes are
# incorrectly decoded as Windows-1252 or similar encoding.
# =============================================================================
function Fix-EmDashMojibake {
    Write-Log "=== Fixing Em Dash Mojibake ===" "Cyan"

    # The mojibake pattern to find: â + " + € (three characters that represent corrupted em dash)
    # Using character codes to avoid encoding issues in the script itself
    # â = U+00E2, " = U+201C (left double quote), € = U+20AC
    $mojibakePattern = [char]0x00E2 + [char]0x201C + [char]0x20AC  # The corrupted em dash pattern
    $emDash = [char]0x2014                                         # Correct em dash character (U+2014)

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count                                  # Total markdown files to scan
    $processedFiles = 0                                           # Counter for progress tracking

    Write-Log "  Scanning $totalFiles markdown files for em dash mojibake..." "Gray"

    foreach ($file in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            # Read file content as raw bytes to preserve encoding
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if (-not $content) { continue }                       # Skip empty files

            # Check if file contains the mojibake pattern
            if (-not $content.Contains($mojibakePattern)) { continue }

            $originalContent = $content                           # Store original for comparison
            $replacementCount = 0                                 # Counter for replacements in this file

            # Count occurrences before fixing
            $replacementCount = ([regex]::Matches($content, [regex]::Escape($mojibakePattern))).Count

            # Replace all occurrences of the mojibake pattern with em dash
            $content = $content -replace [regex]::Escape($mojibakePattern), $emDash

            # Check if content changed
            if ($content -ne $originalContent) {
                if ($dryRun) {
                    Write-Log "  [DRY RUN] Would fix $replacementCount em dash mojibake(s) in: $($file.Name)" "Magenta"
                } else {
                    try {
                        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
                        Write-Log "  Fixed $replacementCount em dash mojibake(s) in: $($file.Name)" "Green"
                        $script:emDashFilesFixed++
                    } catch {
                        Write-Log "  ERROR: Could not write $($file.Name) - $_" "Red"
                    }
                }
                $script:emDashReplacements += $replacementCount
            }
        } catch {
            # Skip files that can't be read
            continue
        }
    }

    Write-Log "  Scan complete. Found $script:emDashReplacements em dash mojibake(s) in $script:emDashFilesFixed file(s)." "Green"
}

# =============================================================================
# Fix Triple-Encoded Em Dash Mojibake
# =============================================================================
# Scans all markdown files for triple UTF-8 encoded em dash patterns and
# replaces with proper em dash (—). This pattern occurs when UTF-8 encoded
# em dashes are decoded/encoded incorrectly multiple times.
# Pattern: ÃƒÂ¢Ã¢â€šÂ¬" -> —
# =============================================================================
function Fix-TripleEncodedEmDash {
    Write-Log "=== Fixing Triple-Encoded Em Dash Mojibake ===" "Cyan"

    # The triple-encoded mojibake patterns for em dash
    # This is what an em dash looks like after being incorrectly decoded/encoded multiple times
    # Building patterns from UTF-8 byte sequences to avoid script encoding issues
    # There are two variations: one ending with regular quote (0x22) and one with left double quote (E2 80 9C)
    $emDash = [char]0x2014                                       # Correct em dash character (U+2014)

    # Pattern 1: Ends with regular double quote (")
    $pattern1Bytes = [byte[]]@(0xC3, 0x83, 0xC6, 0x92, 0xC3, 0x82, 0xC2, 0xA2, 0xC3, 0x83, 0xC2, 0xA2, 0xC3, 0xA2, 0xE2, 0x82, 0xAC, 0xC5, 0xA1, 0xC3, 0x82, 0xC2, 0xAC, 0x22)
    $pattern1 = [System.Text.Encoding]::UTF8.GetString($pattern1Bytes)

    # Pattern 2: Ends with left double quotation mark (")
    $pattern2Bytes = [byte[]]@(0xC3, 0x83, 0xC6, 0x92, 0xC3, 0x82, 0xC2, 0xA2, 0xC3, 0x83, 0xC2, 0xA2, 0xC3, 0xA2, 0xE2, 0x82, 0xAC, 0xC5, 0xA1, 0xC3, 0x82, 0xC2, 0xAC, 0xE2, 0x80, 0x9C)
    $pattern2 = [System.Text.Encoding]::UTF8.GetString($pattern2Bytes)

    # Collect all patterns to check
    $patterns = @($pattern1, $pattern2)

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count                                 # Total markdown files to scan
    $processedFiles = 0                                          # Counter for progress tracking

    Write-Log "  Scanning $totalFiles markdown files for triple-encoded em dash..." "Gray"

    foreach ($file in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            # Read file content
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if (-not $content) { continue }                      # Skip empty files

            $originalContent = $content                          # Store original for comparison
            $replacementCount = 0                                # Counter for replacements in this file

            # Check and replace each pattern variant
            foreach ($pattern in $patterns) {
                if ($content.Contains($pattern)) {
                    # Count occurrences of this pattern
                    $patternCount = ([regex]::Matches($content, [regex]::Escape($pattern))).Count
                    $replacementCount += $patternCount

                    # Replace all occurrences of this pattern with em dash
                    $content = $content -replace [regex]::Escape($pattern), $emDash
                }
            }

            # Check if content changed
            if ($content -ne $originalContent) {
                if ($dryRun) {
                    Write-Log "  [DRY RUN] Would fix $replacementCount triple-encoded em dash(es) in: $($file.Name)" "Magenta"
                } else {
                    try {
                        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
                        Write-Log "  Fixed $replacementCount triple-encoded em dash(es) in: $($file.Name)" "Green"
                        $script:tripleEncFilesFixed++
                    } catch {
                        Write-Log "  ERROR: Could not write $($file.Name) - $_" "Red"
                    }
                }
                $script:tripleEncReplacements += $replacementCount
            }
        } catch {
            # Skip files that can't be read
            continue
        }
    }

    Write-Log "  Scan complete. Found $script:tripleEncReplacements triple-encoded em dash(es) in $script:tripleEncFilesFixed file(s)." "Green"
}

# =============================================================================
# Fix Non-Breaking Hyphen Mojibake (â€')
# =============================================================================
# Scans all markdown files for the "â€'" mojibake pattern and replaces with
# a regular hyphen (-). This pattern occurs when the non-breaking hyphen
# (U+2011) is incorrectly decoded as Windows-1252.
# =============================================================================
function Fix-HyphenMojibake {
    Write-Log "=== Fixing Non-Breaking Hyphen Mojibake ===" "Cyan"

    # The mojibake pattern for non-breaking hyphen (U+2011)
    # When UTF-8 bytes E2 80 91 are misinterpreted as Windows-1252: â€'
    # Byte sequence: 0xC3, 0xA2, 0xE2, 0x82, 0xAC, 0x27
    $patternBytes = [byte[]]@(0xC3, 0xA2, 0xE2, 0x82, 0xAC, 0x27)
    $hyphenPattern = [System.Text.Encoding]::UTF8.GetString($patternBytes)  # The corrupted hyphen pattern
    $hyphen = "-"                                                # Regular hyphen replacement

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count                                 # Total markdown files to scan
    $processedFiles = 0                                          # Counter for progress tracking

    Write-Log "  Scanning $totalFiles markdown files for hyphen mojibake..." "Gray"

    foreach ($file in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            # Read file content
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if (-not $content) { continue }                      # Skip empty files

            # Check if file contains the mojibake pattern
            if (-not $content.Contains($hyphenPattern)) { continue }

            $originalContent = $content                          # Store original for comparison
            $replacementCount = 0                                # Counter for replacements in this file

            # Count occurrences before fixing
            $replacementCount = ([regex]::Matches($content, [regex]::Escape($hyphenPattern))).Count

            # Replace all occurrences of the mojibake pattern with hyphen
            $content = $content -replace [regex]::Escape($hyphenPattern), $hyphen

            # Check if content changed
            if ($content -ne $originalContent) {
                if ($dryRun) {
                    Write-Log "  [DRY RUN] Would fix $replacementCount hyphen mojibake(s) in: $($file.Name)" "Magenta"
                } else {
                    try {
                        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
                        Write-Log "  Fixed $replacementCount hyphen mojibake(s) in: $($file.Name)" "Green"
                        $script:hyphenFilesFixed++
                    } catch {
                        Write-Log "  ERROR: Could not write $($file.Name) - $_" "Red"
                    }
                }
                $script:hyphenReplacements += $replacementCount
            }
        } catch {
            # Skip files that can't be read
            continue
        }
    }

    Write-Log "  Scan complete. Found $script:hyphenReplacements hyphen mojibake(s) in $script:hyphenFilesFixed file(s)." "Green"
}

# =============================================================================
# Fix Checkmark Emoji Mojibake (âœ...)
# =============================================================================
# Scans all markdown files for the "âœ..." mojibake pattern and replaces with
# the checkmark emoji (✅). This pattern occurs when the checkmark emoji
# (U+2705) is incorrectly decoded.
# =============================================================================
function Fix-CheckmarkMojibake {
    Write-Log "=== Fixing Checkmark Emoji Mojibake ===" "Cyan"

    # The mojibake pattern for checkmark emoji (U+2705)
    # Byte sequence: 0xC3, 0xA2, 0xC5, 0x93 followed by ... (three dots)
    $patternBytes = [byte[]]@(0xC3, 0xA2, 0xC5, 0x93, 0x2E, 0x2E, 0x2E)
    $checkmarkPattern = [System.Text.Encoding]::UTF8.GetString($patternBytes)  # The corrupted checkmark pattern
    $checkmark = [char]0x2705                                    # Checkmark emoji (✅)

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count                                 # Total markdown files to scan
    $processedFiles = 0                                          # Counter for progress tracking

    Write-Log "  Scanning $totalFiles markdown files for checkmark mojibake..." "Gray"

    foreach ($file in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            # Read file content
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if (-not $content) { continue }                      # Skip empty files

            # Check if file contains the mojibake pattern
            if (-not $content.Contains($checkmarkPattern)) { continue }

            $originalContent = $content                          # Store original for comparison
            $replacementCount = 0                                # Counter for replacements in this file

            # Count occurrences before fixing
            $replacementCount = ([regex]::Matches($content, [regex]::Escape($checkmarkPattern))).Count

            # Replace all occurrences of the mojibake pattern with checkmark
            $content = $content -replace [regex]::Escape($checkmarkPattern), $checkmark

            # Check if content changed
            if ($content -ne $originalContent) {
                if ($dryRun) {
                    Write-Log "  [DRY RUN] Would fix $replacementCount checkmark mojibake(s) in: $($file.Name)" "Magenta"
                } else {
                    try {
                        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
                        Write-Log "  Fixed $replacementCount checkmark mojibake(s) in: $($file.Name)" "Green"
                        $script:checkmarkFilesFixed++
                    } catch {
                        Write-Log "  ERROR: Could not write $($file.Name) - $_" "Red"
                    }
                }
                $script:checkmarkReplacements += $replacementCount
            }
        } catch {
            # Skip files that can't be read
            continue
        }
    }

    Write-Log "  Scan complete. Found $script:checkmarkReplacements checkmark mojibake(s) in $script:checkmarkFilesFixed file(s)." "Green"
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

# Run the fixes
Fix-ReplacementCharacters
Fix-EmDashMojibake
Fix-TripleEncodedEmDash
Fix-HyphenMojibake
Fix-CheckmarkMojibake

# Summary
Write-Log "" "White"
Write-Log "============================================" "Green"
Write-Log "CHARACTER CORRECTIONS COMPLETE" "Green"
Write-Log "  Replacement char (�) fixes:" "White"
Write-Log "    Files fixed: $script:filesFixed" "White"
Write-Log "    Total replacements: $script:totalReplacements" "White"
Write-Log "  Em dash mojibake fixes:" "White"
Write-Log "    Files fixed: $script:emDashFilesFixed" "White"
Write-Log "    Total replacements: $script:emDashReplacements" "White"
Write-Log "  Triple-encoded em dash fixes:" "White"
Write-Log "    Files fixed: $script:tripleEncFilesFixed" "White"
Write-Log "    Total replacements: $script:tripleEncReplacements" "White"
Write-Log "  Hyphen mojibake fixes:" "White"
Write-Log "    Files fixed: $script:hyphenFilesFixed" "White"
Write-Log "    Total replacements: $script:hyphenReplacements" "White"
Write-Log "  Checkmark mojibake fixes:" "White"
Write-Log "    Files fixed: $script:checkmarkFilesFixed" "White"
Write-Log "    Total replacements: $script:checkmarkReplacements" "White"
Write-Log "  Log saved to: $logPath" "White"
Write-Log "============================================" "Green"
