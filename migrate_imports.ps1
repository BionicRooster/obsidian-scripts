# Migration script to move Evernote and OneNote imports
# Moves .md files to 20 - Permanent Notes
# Moves image/resource files to 00 - Images
# Updates all links throughout the vault

$VaultPath = "D:\Obsidian\Main"
$EvernotePath = Join-Path $VaultPath "11 - Evernote"
$OneNotePath = Join-Path $VaultPath "12 - OneNote"
$PermanentNotesPath = Join-Path $VaultPath "20 - Permanent Notes"
$ImagesPath = Join-Path $VaultPath "00 - Images"

# Track all moves for link updating
$moves = @()
$mdCount = 0
$imageCount = 0
$linkUpdates = 0

# Image/resource extensions
$imageExtensions = @('.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.svg', '.pdf', '.mp3', '.mp4', '.wav')

Write-Host "=== Starting Migration ===" -ForegroundColor Cyan

# Function to get safe destination filename (handle duplicates)
function Get-SafeDestination {
    param($DestFolder, $FileName)

    $destPath = Join-Path $DestFolder $FileName
    if (-not (Test-Path $destPath)) {
        return $destPath
    }

    # File exists, add number suffix
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $ext = [System.IO.Path]::GetExtension($FileName)
    $counter = 1

    while (Test-Path $destPath) {
        $newName = "${baseName}_${counter}${ext}"
        $destPath = Join-Path $DestFolder $newName
        $counter++
    }

    return $destPath
}

# Process each source folder
foreach ($sourceFolder in @($EvernotePath, $OneNotePath)) {
    if (-not (Test-Path $sourceFolder)) {
        Write-Host "Folder not found: $sourceFolder" -ForegroundColor Yellow
        continue
    }

    $folderName = Split-Path $sourceFolder -Leaf
    Write-Host "`nProcessing: $folderName" -ForegroundColor Green

    # Get all files recursively
    $files = Get-ChildItem -Path $sourceFolder -Recurse -File

    foreach ($file in $files) {
        $ext = $file.Extension.ToLower()
        $oldPath = $file.FullName
        $oldRelPath = $oldPath.Substring($VaultPath.Length + 1)  # Relative path from vault root

        if ($ext -eq '.md') {
            # Move to Permanent Notes
            $destPath = Get-SafeDestination -DestFolder $PermanentNotesPath -FileName $file.Name
            $newRelPath = $destPath.Substring($VaultPath.Length + 1)

            Move-Item -Path $oldPath -Destination $destPath -Force
            $mdCount++

            $moves += [PSCustomObject]@{
                OldPath = $oldRelPath
                NewPath = $newRelPath
                Type = "markdown"
                FileName = $file.Name
            }
        }
        elseif ($imageExtensions -contains $ext) {
            # Move to Images folder - create subfolder for organization
            $subFolder = Join-Path $ImagesPath "Imported-Resources"
            if (-not (Test-Path $subFolder)) {
                New-Item -ItemType Directory -Path $subFolder -Force | Out-Null
            }

            $destPath = Get-SafeDestination -DestFolder $subFolder -FileName $file.Name
            $newRelPath = $destPath.Substring($VaultPath.Length + 1)

            Move-Item -Path $oldPath -Destination $destPath -Force
            $imageCount++

            $moves += [PSCustomObject]@{
                OldPath = $oldRelPath
                NewPath = $newRelPath
                Type = "image"
                FileName = $file.Name
            }
        }
        else {
            # Other file types - also move to Images/Imported-Resources
            $subFolder = Join-Path $ImagesPath "Imported-Resources"
            if (-not (Test-Path $subFolder)) {
                New-Item -ItemType Directory -Path $subFolder -Force | Out-Null
            }

            $destPath = Get-SafeDestination -DestFolder $subFolder -FileName $file.Name
            $newRelPath = $destPath.Substring($VaultPath.Length + 1)

            Move-Item -Path $oldPath -Destination $destPath -Force
            $imageCount++

            $moves += [PSCustomObject]@{
                OldPath = $oldRelPath
                NewPath = $newRelPath
                Type = $ext
                FileName = $file.Name
            }
        }
    }
}

Write-Host "`n=== Files Moved ===" -ForegroundColor Cyan
Write-Host "Markdown files: $mdCount"
Write-Host "Image/resource files: $imageCount"

# Now update all links in the vault
Write-Host "`n=== Updating Links ===" -ForegroundColor Cyan

# Get all markdown files in the vault
$allMdFiles = Get-ChildItem -Path $VaultPath -Recurse -Filter "*.md" -File

foreach ($mdFile in $allMdFiles) {
    $content = Get-Content -Path $mdFile.FullName -Raw -Encoding UTF8
    if ($null -eq $content) { continue }

    $originalContent = $content
    $fileModified = $false

    foreach ($move in $moves) {
        # Handle various link formats in Obsidian
        $oldPathVariants = @(
            $move.OldPath,
            $move.OldPath -replace '\\', '/',
            [System.IO.Path]::GetFileNameWithoutExtension($move.FileName),
            $move.FileName
        )

        $newPathForLink = $move.NewPath -replace '\\', '/'
        $newFileName = [System.IO.Path]::GetFileNameWithoutExtension($move.FileName)

        foreach ($oldVariant in $oldPathVariants) {
            # Escape special regex characters
            $escapedOld = [regex]::Escape($oldVariant)

            # Match [[path]] or [[path|alias]] or ![[path]] patterns
            $patterns = @(
                "(\[\[)($escapedOld)(\]\])",
                "(\[\[)($escapedOld)(\|[^\]]+\]\])",
                "(!\[\[)($escapedOld)(\]\])"
            )

            foreach ($pattern in $patterns) {
                if ($content -match $pattern) {
                    # For markdown files, use just the filename (Obsidian resolves)
                    if ($move.Type -eq "markdown") {
                        $replacement = $newFileName
                    } else {
                        # For images, use full path
                        $replacement = $newPathForLink
                    }

                    $content = $content -replace $pattern, "`$1$replacement`$3"
                    $fileModified = $true
                }
            }
        }
    }

    if ($fileModified -and ($content -ne $originalContent)) {
        Set-Content -Path $mdFile.FullName -Value $content -Encoding UTF8 -NoNewline
        $linkUpdates++
    }
}

Write-Host "Files with updated links: $linkUpdates"

# Clean up empty directories
Write-Host "`n=== Cleaning Empty Directories ===" -ForegroundColor Cyan
foreach ($sourceFolder in @($EvernotePath, $OneNotePath)) {
    if (Test-Path $sourceFolder) {
        $emptyDirs = Get-ChildItem -Path $sourceFolder -Recurse -Directory |
                     Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -File).Count -eq 0 } |
                     Sort-Object { $_.FullName.Length } -Descending

        foreach ($dir in $emptyDirs) {
            Remove-Item -Path $dir.FullName -Force -Recurse 2>$null
        }

        # Try to remove the source folder itself if empty
        if ((Get-ChildItem -Path $sourceFolder -Recurse -File).Count -eq 0) {
            Remove-Item -Path $sourceFolder -Force -Recurse 2>$null
            Write-Host "Removed empty folder: $(Split-Path $sourceFolder -Leaf)"
        }
    }
}

# Output summary
Write-Host "`n=== MIGRATION SUMMARY ===" -ForegroundColor Green
Write-Host "Total markdown files moved: $mdCount"
Write-Host "Total image/resource files moved: $imageCount"
Write-Host "Total files with link updates: $linkUpdates"

# Save move log
$logPath = Join-Path $VaultPath "migration_log.json"
$moves | ConvertTo-Json -Depth 3 | Set-Content -Path $logPath -Encoding UTF8
Write-Host "`nMove log saved to: $logPath"

# Group by type for summary
Write-Host "`n=== Files by Type ===" -ForegroundColor Cyan
$moves | Group-Object Type | ForEach-Object {
    Write-Host "$($_.Name): $($_.Count)"
}

Write-Host "`n=== Migration Complete ===" -ForegroundColor Green
