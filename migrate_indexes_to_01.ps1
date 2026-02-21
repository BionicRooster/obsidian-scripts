# migrate_indexes_to_01.ps1
# Migrates files from "04 - Indexes" folder to appropriate "01" subdirectories
# while updating all wikilinks throughout the vault

# Define vault path
$vaultPath = "D:\Obsidian\Main"
# Source folder containing files to migrate
$sourceFolder = Join-Path $vaultPath "04 - Indexes"
# Target base folder for migrations
$targetBase = Join-Path $vaultPath "01"

# Define mapping from source patterns to target subdirectories
# Format: @{ "source pattern or folder" = "target subfolder in 01" }
$migrationMap = @{
    # Computer-related content goes to Technology
    "Computer Sciences" = "Technology"
    "MicrosoftAccess" = "Technology"
    "Linux.md" = "Technology"
    "Windows.md" = "Technology"

    # Finance stays in Finance
    "Finance" = "Finance"

    # Family/home-related
    "Genealogy" = "Home"
    "Home and Hearth.md" = "Home"
    "Movies.md" = "Home"
    "Star Trek.md" = "Home"

    # Travel destinations
    "Japan.md" = "Travel"
    "Travel.md" = "Travel"

    # Library/knowledge management
    "Library" = "PKM"
    "04 - Indexes.md" = "PKM"

    # Health-related
    "medical.md" = "Health"
    "Vegan.md" = "Health"
    "WFPB Diet" = "Health"

    # Science-related
    "Micrometeorite.md" = "Science"
    "Nature.md" = "Science"
    "Sciences" = "Science"

    # Music stays in Music
    "Music" = "Music"

    # Personal development
    "Personal Development.md" = "NLP_Psy"

    # Religion mapping - Bahá'í specific content goes to Bahá'í folder
    # General religion stays in Religion
}

# Track all file moves for link updates: @{ "old filename" = "new full path" }
$fileMoves = @{}
# Track files moved for summary
$movedFiles = @()

Write-Host "=== Migration Script: 04 - Indexes -> 01 ===" -ForegroundColor Cyan
Write-Host ""

# Get all markdown files from source folder recursively
$allSourceFiles = Get-ChildItem -Path $sourceFolder -Recurse -Filter "*.md" -File

Write-Host "Found $($allSourceFiles.Count) markdown files to process" -ForegroundColor Yellow
Write-Host ""

foreach ($file in $allSourceFiles) {
    # Get relative path from source folder
    $relativePath = $file.FullName.Substring($sourceFolder.Length + 1)
    # Get the top-level folder or file name for mapping
    $topLevel = $relativePath.Split('\')[0]

    # Determine target subfolder based on mapping
    $targetSubfolder = $null

    # Check if this is a Bahá'í-related file (special case within Religion)
    if ($relativePath -like "Religion\Bahá'í\*" -or $relativePath -like "Religion/Bahá'í/*") {
        $targetSubfolder = "Bahá'í"
    }
    # Check for direct mapping
    elseif ($migrationMap.ContainsKey($topLevel)) {
        $targetSubfolder = $migrationMap[$topLevel]
    }
    # Handle Religion folder (non-Bahá'í content)
    elseif ($topLevel -eq "Religion" -or $topLevel -eq "Religion.md") {
        $targetSubfolder = "Religion"
    }
    else {
        Write-Host "  WARNING: No mapping for '$topLevel' - skipping $($file.Name)" -ForegroundColor Red
        continue
    }

    # Build target path - flatten the structure (put files directly in target subfolder)
    $targetFolder = Join-Path $targetBase $targetSubfolder
    $targetPath = Join-Path $targetFolder $file.Name

    # Check if target file already exists
    if (Test-Path $targetPath) {
        Write-Host "  CONFLICT: $($file.Name) already exists in $targetSubfolder - skipping" -ForegroundColor Red
        continue
    }

    # Ensure target folder exists
    if (-not (Test-Path $targetFolder)) {
        New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
    }

    # Store the move for link updates (store just the filename without extension as the key)
    $fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $fileMoves[$fileBaseName] = @{
        OldPath = $file.FullName
        NewPath = $targetPath
        OldFolder = $file.DirectoryName
        NewFolder = $targetFolder
    }

    # Move the file
    Write-Host "Moving: $relativePath -> 01/$targetSubfolder/$($file.Name)" -ForegroundColor Green
    Move-Item -Path $file.FullName -Destination $targetPath -Force

    $movedFiles += [PSCustomObject]@{
        FileName = $file.Name
        From = $relativePath
        To = "01/$targetSubfolder/$($file.Name)"
    }
}

Write-Host ""
Write-Host "=== Updating Links ===" -ForegroundColor Cyan
Write-Host ""

# Now update all wikilinks in the vault that reference moved files
# Obsidian wikilinks typically use just the filename without path, so they should still work
# But we need to update any explicit path references

# Get all markdown files in the vault
$allVaultFiles = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" -File

$updatedFilesCount = 0

foreach ($vaultFile in $allVaultFiles) {
    # Read file content with UTF-8 encoding
    $content = [System.IO.File]::ReadAllText($vaultFile.FullName, [System.Text.Encoding]::UTF8)
    $originalContent = $content

    # Look for wikilinks with explicit paths referencing "04 - Indexes"
    # Pattern: [[04 - Indexes/...]] or [[04 - Indexes\...]]
    if ($content -match '\[\[04 - Indexes[/\\]') {
        # Replace path-based references
        foreach ($move in $fileMoves.GetEnumerator()) {
            $fileName = $move.Key
            $moveInfo = $move.Value

            # Get the relative path portion after "04 - Indexes/"
            $oldRelative = $moveInfo.OldPath.Substring($sourceFolder.Length + 1)
            $oldRelative = $oldRelative -replace '\.md$', ''

            # Get new relative path from vault root
            $newRelative = $moveInfo.NewPath.Substring($vaultPath.Length + 1)
            $newRelative = $newRelative -replace '\.md$', ''

            # Replace various path formats
            $patterns = @(
                "04 - Indexes/$oldRelative",
                "04 - Indexes\$oldRelative"
            )

            foreach ($pattern in $patterns) {
                if ($content.Contains($pattern)) {
                    $content = $content.Replace($pattern, $newRelative)
                }
            }
        }
    }

    # If content changed, write it back
    if ($content -ne $originalContent) {
        [System.IO.File]::WriteAllText($vaultFile.FullName, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Updated links in: $($vaultFile.Name)" -ForegroundColor Yellow
        $updatedFilesCount++
    }
}

Write-Host ""
Write-Host "=== Cleanup Empty Folders ===" -ForegroundColor Cyan
Write-Host ""

# Remove empty folders left behind in 04 - Indexes
# Do this in reverse order of depth so we remove deepest folders first
$emptyFolders = Get-ChildItem -Path $sourceFolder -Recurse -Directory |
    Sort-Object { $_.FullName.Length } -Descending

foreach ($folder in $emptyFolders) {
    $items = Get-ChildItem -Path $folder.FullName -Force
    if ($items.Count -eq 0) {
        Write-Host "Removing empty folder: $($folder.FullName.Substring($sourceFolder.Length + 1))" -ForegroundColor Gray
        Remove-Item -Path $folder.FullName -Force
    }
}

# Check if source folder itself is empty
$remainingItems = Get-ChildItem -Path $sourceFolder -Force
if ($remainingItems.Count -eq 0) {
    Write-Host "Removing empty source folder: 04 - Indexes" -ForegroundColor Gray
    Remove-Item -Path $sourceFolder -Force
}

Write-Host ""
Write-Host "=== Migration Summary ===" -ForegroundColor Cyan
Write-Host "Files moved: $($movedFiles.Count)" -ForegroundColor Green
Write-Host "Files with updated links: $updatedFilesCount" -ForegroundColor Yellow
Write-Host ""

# Display moved files table
if ($movedFiles.Count -gt 0) {
    Write-Host "Moved files:" -ForegroundColor White
    $movedFiles | Format-Table -AutoSize
}

Write-Host "Migration complete!" -ForegroundColor Green
