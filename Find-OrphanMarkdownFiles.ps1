# Find-OrphanMarkdownFiles.ps1
# This script scans an Obsidian vault for markdown files that contain no wikilinks
# Wikilinks are defined as text enclosed in double square brackets: [[link]]

# Define the path to the Obsidian vault to scan
$vaultPath = "D:\Obsidian\Main"

# Define folders to exclude from the scan
# These are typically imported notes that don't have wikilinks
#$excludedFolders = @(
#    "11 - Evernote",
#    "12 - OneNote"
#)

# Define the output directory where the results file will be saved
$outputDirectory = "C:\Users\awt\PowerShell\Out"

# Define the output file name with timestamp for uniqueness
# Using ISO 8601 date format for sortable file names
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

# Full path to the output file that will contain the list of orphan files
$outputFile = Join-Path -Path $outputDirectory -ChildPath "OrphanFiles_$timestamp.txt"

# Define the regex pattern for wikilinks
# This pattern matches [[ followed by any characters followed by ]]
# The .NET regex engine requires escaping the brackets
$wikiLinkPattern = "\[\[.+?\]\]"

# Initialize a counter for tracking progress
$totalFilesScanned = 0

# Initialize a counter for files without wikilinks
$orphanFileCount = 0

# Initialize an array to store the paths of files without wikilinks
$orphanFiles = @()

# Display script start message
Write-Host "Starting scan of Obsidian vault: $vaultPath" -ForegroundColor Cyan
Write-Host "Looking for markdown files without wikilinks..." -ForegroundColor Cyan

# Get all markdown files recursively from the vault
# -Filter "*.md" ensures we only get markdown files
# -Recurse ensures we search all subdirectories
$allMarkdownFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -File

# Filter out files from excluded folders
# This checks if any part of the file path contains an excluded folder name
$markdownFiles = $allMarkdownFiles | Where-Object {
    # Get the relative path from the vault root
    $relativePath = $_.FullName.Substring($vaultPath.Length + 1)

    # Check if the file is in any excluded folder
    $isExcluded = $false
    foreach ($excludedFolder in $excludedFolders) {
        if ($relativePath.StartsWith($excludedFolder + "\") -or $relativePath -eq $excludedFolder) {
            $isExcluded = $true
            break
        }
    }

    # Return true to keep the file (i.e., it's NOT excluded)
    -not $isExcluded
}

# Display excluded folders info
Write-Host "Excluding folders: $($excludedFolders -join ', ')" -ForegroundColor Magenta

# Store the total count of markdown files found
$totalFiles = $markdownFiles.Count

# Display the total number of files to scan
Write-Host "Found $totalFiles markdown files to scan." -ForegroundColor Yellow

# Iterate through each markdown file
foreach ($file in $markdownFiles) {
    # Increment the scanned files counter
    $totalFilesScanned++

    # Read the entire content of the current file
    # -Raw reads the file as a single string (faster for regex matching)
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue

    # Check if the file has any content
    # Some files may be empty or unreadable
    if ($null -eq $content) {
        # Treat empty/unreadable files as having no wikilinks
        $hasWikiLinks = $false
    }
    else {
        # Test if the content contains any wikilinks using regex
        # Returns true if at least one match is found
        $hasWikiLinks = $content -match $wikiLinkPattern
    }

    # If no wikilinks were found in the file
    if (-not $hasWikiLinks) {
        # Increment the orphan file counter
        $orphanFileCount++

        # Add the full path to our collection of orphan files
        $orphanFiles += $file.FullName
    }

    # Display progress every 100 files to avoid flooding the console
    if ($totalFilesScanned % 100 -eq 0) {
        # Calculate percentage complete
        $percentComplete = [math]::Round(($totalFilesScanned / $totalFiles) * 100, 1)

        # Display progress update
        Write-Host "Progress: $totalFilesScanned / $totalFiles ($percentComplete%)" -ForegroundColor Gray
    }
}

# Write the results to the output file
# Using Out-File with UTF8 encoding for proper character support
$orphanFiles | Out-File -FilePath $outputFile -Encoding UTF8

# Display completion summary
Write-Host "`n========== SCAN COMPLETE ==========" -ForegroundColor Green
Write-Host "Total files scanned: $totalFilesScanned" -ForegroundColor White
Write-Host "Files without wikilinks: $orphanFileCount" -ForegroundColor Yellow
Write-Host "Results saved to: $outputFile" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Green
