# fix_smart_apostrophe_filenames.ps1
# Purpose: Rename folders and files that contain smart/curly apostrophes (')
#          to use standard apostrophes (') instead.
#
# The issue: Some folder and file names contain smart apostrophes (Unicode: U+2019)
# but the links in markdown files use standard apostrophes (Unicode: U+0027).
# This causes Obsidian to report "file not found" errors.
#
# This script renames the files/folders to match what the links expect.
#
# Usage: Run this script to scan and rename all files/folders in the Obsidian vault.

# ============================================================================
# CONFIGURATION
# ============================================================================

# Path to the Obsidian vault - modify this if your vault is in a different location
$VaultPath = "D:\Obsidian\Main"

# Smart apostrophe characters to find (various Unicode variants)
$SmartApostrophes = @(
    [char]0x2019,  # ' Right Single Quotation Mark (most common)
    [char]0x2018,  # ' Left Single Quotation Mark
    [char]0x201B,  # ‛ Single High-Reversed-9 Quotation Mark
    [char]0x0060,  # ` Grave Accent (backtick - sometimes confused)
    [char]0x00B4   # ´ Acute Accent
)

# Standard apostrophe to replace with (Unicode: U+0027 - Apostrophe)
$StandardApostrophe = [char]0x0027  # This is the straight apostrophe: '

# ============================================================================
# LOGGING SETUP
# ============================================================================

# Log file path - stored in the user's home directory
$LogFile = "C:\Users\awt\PowerShell\logs\fix_smart_apostrophe_filenames_log.txt"

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
# HELPER FUNCTION
# ============================================================================

# Function to check if a path contains any smart apostrophes
function Test-HasSmartApostrophe {
    param([string]$Name)
    foreach ($smartApos in $SmartApostrophes) {
        if ($Name.Contains($smartApos)) {
            return $true
        }
    }
    return $false
}

# Function to replace all smart apostrophes with standard ones
function Convert-SmartApostrophes {
    param([string]$Name)
    $result = $Name
    foreach ($smartApos in $SmartApostrophes) {
        $result = $result.Replace($smartApos, $StandardApostrophe)
    }
    return $result
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# Clear the log file and start fresh
"" | Set-Content -Path $LogFile

Write-Log "=========================================="
Write-Log "Smart Apostrophe Filename Fixer Starting"
Write-Log "=========================================="
Write-Log "Vault Path: $VaultPath"
Write-Log "Renaming folders and files with smart apostrophes to use standard apostrophes"
Write-Log ""

# Counter variables to track progress
$foldersRenamed = 0    # Number of folders renamed
$filesRenamed = 0      # Number of files renamed
$errors = 0            # Number of errors encountered

# ============================================================================
# PHASE 1: Rename Folders (deepest first to avoid path issues)
# ============================================================================

Write-Log "--- PHASE 1: Renaming Folders ---"

# Get all directories recursively, sort by depth (deepest first)
# This ensures we rename child folders before parent folders
$folders = Get-ChildItem -Path $VaultPath -Directory -Recurse -ErrorAction SilentlyContinue |
           Sort-Object { $_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count } -Descending

Write-Log "Found $($folders.Count) folders to check"

foreach ($folder in $folders) {
    # Check if folder name contains smart apostrophe
    if (Test-HasSmartApostrophe -Name $folder.Name) {
        # Create new name with standard apostrophe
        $newName = Convert-SmartApostrophes -Name $folder.Name
        $newPath = Join-Path -Path $folder.Parent.FullName -ChildPath $newName

        Write-Log "Renaming folder:"
        Write-Log "  From: $($folder.FullName)"
        Write-Log "  To:   $newPath"

        try {
            # Perform the rename
            Rename-Item -Path $folder.FullName -NewName $newName -ErrorAction Stop
            $foldersRenamed++
            Write-Log "  Status: SUCCESS"
        }
        catch {
            $errors++
            Write-Log "  Status: ERROR - $($_.Exception.Message)"
        }
        Write-Log ""
    }
}

# ============================================================================
# PHASE 2: Rename Files
# ============================================================================

Write-Log "--- PHASE 2: Renaming Files ---"

# Get all files recursively
$files = Get-ChildItem -Path $VaultPath -File -Recurse -ErrorAction SilentlyContinue

Write-Log "Found $($files.Count) files to check"

foreach ($file in $files) {
    # Check if file name contains smart apostrophe
    if (Test-HasSmartApostrophe -Name $file.Name) {
        # Create new name with standard apostrophe
        $newName = Convert-SmartApostrophes -Name $file.Name
        $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newName

        Write-Log "Renaming file:"
        Write-Log "  From: $($file.FullName)"
        Write-Log "  To:   $newPath"

        try {
            # Perform the rename
            Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
            $filesRenamed++
            Write-Log "  Status: SUCCESS"
        }
        catch {
            $errors++
            Write-Log "  Status: ERROR - $($_.Exception.Message)"
        }
        Write-Log ""
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Log "=========================================="
Write-Log "Smart Apostrophe Filename Fixer Complete"
Write-Log "=========================================="
Write-Log "Folders Renamed: $foldersRenamed"
Write-Log "Files Renamed:   $filesRenamed"
Write-Log "Errors:          $errors"
Write-Log "Log saved to:    $LogFile"
Write-Log "=========================================="

# Return summary as object for programmatic use
[PSCustomObject]@{
    FoldersRenamed = $foldersRenamed
    FilesRenamed   = $filesRenamed
    Errors         = $errors
    LogFile        = $LogFile
}
