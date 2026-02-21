# fix_smart_apostrophe_links.ps1
# Purpose: Fix broken Obsidian links that contain smart/curly apostrophes (')
#          by replacing them with standard apostrophes (')
#
# The issue: Links in markdown files may contain smart apostrophes (Unicode: U+2019)
# but the actual files/folders on disk use standard apostrophes (Unicode: U+0027).
# This causes Obsidian to report "file not found" errors.
#
# Usage: Run this script to scan and fix all markdown files in the Obsidian vault.

# ============================================================================
# CONFIGURATION
# ============================================================================

# Path to the Obsidian vault - modify this if your vault is in a different location
$VaultPath = "D:\Obsidian\Main"

# Smart apostrophe character to find (Unicode: U+2019 - Right Single Quotation Mark)
$SmartApostrophe = [char]0x2019  # This is the curly/smart apostrophe: '

# Standard apostrophe to replace with (Unicode: U+0027 - Apostrophe)
$StandardApostrophe = [char]0x0027  # This is the straight apostrophe: '

# Additional smart quote variants that might appear in links (for completeness)
$SmartQuotes = @(
    [char]0x2019,  # ' Right Single Quotation Mark (most common)
    [char]0x2018,  # ' Left Single Quotation Mark
    [char]0x201B   # ‛ Single High-Reversed-9 Quotation Mark
)

# ============================================================================
# LOGGING SETUP
# ============================================================================

# Log file path - stored in the user's home directory
$LogFile = "C:\Users\awt\PowerShell\logs\fix_smart_apostrophe_links_log.txt"

# Function to write log messages with timestamps
function Write-Log {
    param([string]$Message)
    # Format: [YYYY-MM-DD HH:MM:SS] Message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    # Output to console and append to log file
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# Clear the log file and start fresh
"" | Set-Content -Path $LogFile

Write-Log "=========================================="
Write-Log "Smart Apostrophe Link Fixer Starting"
Write-Log "=========================================="
Write-Log "Vault Path: $VaultPath"
Write-Log "Searching for smart apostrophes in wiki-style links [[...]]"

# Counter variables to track progress
$filesScanned = 0      # Total number of .md files examined
$filesModified = 0     # Number of files that had changes made
$linksFixed = 0        # Total number of link replacements made

# Get all markdown files in the vault (recursive search)
# -Filter *.md: Only look at markdown files
# -Recurse: Search all subdirectories
# -File: Only return files, not directories
$mdFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File

Write-Log "Found $($mdFiles.Count) markdown files to scan"
Write-Log ""

# Process each markdown file
foreach ($file in $mdFiles) {
    $filesScanned++

    # Read the entire file content as a single string
    # This preserves line endings and allows us to do accurate replacements
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    # Skip if file is empty or couldn't be read
    if ([string]::IsNullOrEmpty($content)) {
        continue
    }

    # Store original content to compare later
    $originalContent = $content

    # Flag to track if this file was modified
    $fileWasModified = $false

    # Process each type of smart quote
    foreach ($smartQuote in $SmartQuotes) {
        # Check if the file contains this smart quote character at all
        if ($content.Contains($smartQuote)) {
            # Use regex to find all wiki-style links: [[...]] and ![[...]]
            # The regex pattern:
            #   (!?\[\[)  - Optional ! followed by [[  (captured as group 1)
            #   ([^\]]+)  - One or more chars that aren't ]  (captured as group 2 - link content)
            #   (\]\])    - ]]  (captured as group 3)

            $pattern = "(!?\[\[)([^\]]+)(\]\])"

            # Find all matches in the content
            $matches = [regex]::Matches($content, $pattern)

            foreach ($match in $matches) {
                # Extract the link content (the part between [[ and ]])
                $linkContent = $match.Groups[2].Value

                # Check if this specific link contains the smart quote
                if ($linkContent.Contains($smartQuote)) {
                    # Replace smart quote with standard apostrophe in the link
                    $fixedLinkContent = $linkContent.Replace($smartQuote, $StandardApostrophe)

                    # Reconstruct the full link with the fix
                    $originalLink = $match.Value
                    $fixedLink = $match.Groups[1].Value + $fixedLinkContent + $match.Groups[3].Value

                    # Apply the fix to the content
                    $content = $content.Replace($originalLink, $fixedLink)

                    $linksFixed++
                    $fileWasModified = $true

                    Write-Log "Fixed link in: $($file.Name)"
                    Write-Log "  Original: $originalLink"
                    Write-Log "  Fixed:    $fixedLink"
                }
            }
        }
    }

    # If modifications were made, save the file
    if ($fileWasModified) {
        # Write the corrected content back to the file
        # Using -NoNewline to prevent adding extra line at end
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $filesModified++
        Write-Log "Saved: $($file.FullName)"
        Write-Log ""
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Log "=========================================="
Write-Log "Smart Apostrophe Link Fixer Complete"
Write-Log "=========================================="
Write-Log "Files Scanned:  $filesScanned"
Write-Log "Files Modified: $filesModified"
Write-Log "Links Fixed:    $linksFixed"
Write-Log "Log saved to:   $LogFile"
Write-Log "=========================================="

# Return summary as object for programmatic use
[PSCustomObject]@{
    FilesScanned  = $filesScanned
    FilesModified = $filesModified
    LinksFixed    = $linksFixed
    LogFile       = $LogFile
}
