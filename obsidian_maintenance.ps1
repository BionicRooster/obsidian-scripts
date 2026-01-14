# =============================================================================
# Obsidian Vault Maintenance Script
# =============================================================================
# Purpose: Comprehensive maintenance for an Obsidian vault:
#   1a. Normalizes smart/curly apostrophes to standard apostrophes in file names
#   1b. Resolves duplicate files (smart vs standard apostrophe versions)
#   1c. Trims leading/trailing whitespace from filenames and fixes associated links
#   2. Renames unknown_filename images to meaningful names based on parent folder
#   3. Updates all markdown links to match renamed files
#   4. Fixes broken links pointing to moved resources
#   5. Fixes legacy Evernote paths pointing to new image locations
#   6. Generates "Empty Notes.md" listing notes with only a title (no content)
#   7. Generates "Truncated Filenames.md" listing notes with cut-off names
#   8. Deletes small image files (<3KB) in .resources folders (icons, trackers)
#   9. Deletes empty folders left behind after cleanup
#  10. Adds #task tag to uncompleted checkboxes missing the tag
#  11. Fixes broken image links by finding images elsewhere in vault
#      (including OneNote exported images with wrong directory paths)
#  12. Generates "Orphan Files.md" listing notes with no incoming links
#  13. Fixes mojibake encoding (em dash, ellipsis) from UTF-8/Windows-1252 mismatch
#  14. Comprehensive mojibake repair for severely corrupted files
#  15. Removes link aliases from MOC files ([[target|alias]] -> [[target]])
#  16. Simplifies MOC link paths ([[path/filename]] -> [[filename]])
#  17. Moves #clippings tag to last position in files with multiple tags
#
# NOTE: Encoding fix phases have been moved to obsidian_encoding_fix.ps1
#
# Safe to run repeatedly - only makes changes when needed
#
# Usage: powershell -ExecutionPolicy Bypass -File "C:\Users\awt\obsidian_maintenance.ps1"
# =============================================================================

# Configuration
$vaultPath = "D:\Obsidian\Main"                              # Path to Obsidian vault
$logPath = "C:\Users\awt\PowerShell\logs\obsidian_maintenance_log.txt"  # Log file location
$dryRun = $false                                             # Set to $true to preview changes without applying
$maxPathLength = 240                                         # Windows max path safety limit

# Characters to normalize
$curlyApostrophe = [char]0x2019    # ' (right single quote)
$leftApostrophe = [char]0x2018     # ' (left single quote)
$backtick = [char]0x0060           # ` (backtick/grave accent)
$standardApostrophe = "'"          # ' (standard apostrophe)

# Initialize counters
$script:filesRenamed = 0
$script:duplicatesResolved = 0
$script:filenamesTrimmed = 0
$script:trimmedLinksFixed = 0
$script:imagesRenamed = 0
$script:linksFixed = 0
$script:filesModified = 0
$script:emptyNotesFound = 0
$script:truncatedFilesFound = 0
$script:smallImagesDeleted = 0
$script:emptyFoldersDeleted = 0
$script:taskTagsAdded = 0
$script:brokenImageLinksFixed = 0
$script:oneNoteImageLinksFixed = 0
$script:orphanFilesFound = 0
$script:mojibakeFixed = 0
$script:comprehensiveMojibakeFixed = 0
$script:linkAliasesRemoved = 0
$script:linkPathsSimplified = 0
$script:clippingsTagsMoved = 0

# Dictionary configuration for truncated filename detection
$script:wordListPath = "C:\Users\awt\english_words.txt"
$script:wordListUrl = "https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt"
$script:dictionary = $null

# Track renamed images for link updates
$script:renamedImages = [System.Collections.ArrayList]@()

# Comprehensive folder-to-images mapping for legacy link fixes
$script:folderToImages = @{}

# Logging function
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logPath -Value $logMessage
}

# Function to normalize text (convert smart apostrophes to standard)
function Normalize-Text {
    param([string]$text)
    $result = $text -replace "[$curlyApostrophe$leftApostrophe$backtick]", $standardApostrophe
    return $result
}

# =============================================================================
# PHASE 1a: Rename files/folders with non-standard apostrophes
# =============================================================================
function Rename-NonStandardApostrophes {
    Write-Log "=== Phase 1a: Checking for files with non-standard apostrophes ===" "Cyan"

    $itemsToRename = Get-ChildItem -Path $vaultPath -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "[$curlyApostrophe$leftApostrophe$backtick]" } |
        Sort-Object { $_.FullName.Length } -Descending

    if ($itemsToRename.Count -eq 0) {
        Write-Log "  No files need apostrophe normalization" "Green"
        return
    }

    Write-Log "  Found $($itemsToRename.Count) items to check" "Yellow"

    foreach ($item in $itemsToRename) {
        if (-not (Test-Path $item.FullName)) { continue }
        if (-not $item.Directory) { continue }

        $oldName = $item.Name
        $newName = Normalize-Text $oldName

        if ($oldName -ne $newName) {
            $newPath = Join-Path $item.Directory.FullName $newName

            if (Test-Path $newPath) {
                Write-Log "  SKIP: Destination exists: $newName" "DarkYellow"
                continue
            }

            if ($dryRun) {
                Write-Log "  [DRY RUN] Would rename: $oldName -> $newName" "Magenta"
            } else {
                try {
                    Rename-Item -Path $item.FullName -NewName $newName -ErrorAction Stop
                    Write-Log "  Renamed: $oldName" "Green"
                    $script:filesRenamed++
                } catch {
                    Write-Log "  ERROR: Failed to rename $oldName - $_" "Red"
                }
            }
        }
    }
}

# =============================================================================
# PHASE 1b: Resolve duplicate files (smart vs standard apostrophe versions)
# =============================================================================
# When Phase 1a skips a file because the destination exists, we may have duplicates
# where one file has a smart apostrophe and one has a standard apostrophe.
# This phase detects such duplicates, compares file sizes, keeps the larger one
# (which contains the real content), and deletes the smaller stub file.
# =============================================================================
function Resolve-ApostropheDuplicates {
    Write-Log "=== Phase 1b: Resolving apostrophe duplicate files ===" "Cyan"

    # Track duplicates found for reporting
    $duplicatesFound = 0

    # Get all items with non-standard apostrophes in their names
    $itemsWithSmartApos = Get-ChildItem -Path $vaultPath -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "[$curlyApostrophe$leftApostrophe$backtick]" }

    if ($itemsWithSmartApos.Count -eq 0) {
        Write-Log "  No potential duplicates found" "Green"
        return
    }

    Write-Log "  Checking $($itemsWithSmartApos.Count) items for duplicates..." "Yellow"

    foreach ($item in $itemsWithSmartApos) {
        # Skip if item no longer exists (may have been processed already)
        if (-not (Test-Path $item.FullName)) { continue }

        # Get the normalized name (with standard apostrophe)
        $normalizedName = Normalize-Text $item.Name

        # Skip if names are the same (no smart apostrophe in name)
        if ($normalizedName -eq $item.Name) { continue }

        # Build path to potential duplicate with standard apostrophe
        $parentPath = if ($item.PSIsContainer) { $item.Parent.FullName } else { $item.DirectoryName }
        $normalizedPath = Join-Path $parentPath $normalizedName

        # Check if both versions exist (duplicate situation)
        if (Test-Path $normalizedPath) {
            $duplicatesFound++

            # Get file info for both versions
            $smartAposItem = $item
            $standardAposItem = Get-Item -Path $normalizedPath -ErrorAction SilentlyContinue

            if (-not $standardAposItem) { continue }

            # Determine which is the "real" file based on size
            # The larger file typically contains the actual content
            $smartSize = if ($smartAposItem.PSIsContainer) {
                (Get-ChildItem -Path $smartAposItem.FullName -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum).Sum
            } else {
                $smartAposItem.Length
            }

            $standardSize = if ($standardAposItem.PSIsContainer) {
                (Get-ChildItem -Path $standardAposItem.FullName -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum).Sum
            } else {
                $standardAposItem.Length
            }

            # Handle null sizes (empty files/folders)
            if ($null -eq $smartSize) { $smartSize = 0 }
            if ($null -eq $standardSize) { $standardSize = 0 }

            Write-Log "  Found duplicate pair:" "Yellow"
            Write-Log "    Smart apostrophe:    $($smartAposItem.Name) ($smartSize bytes)" "Gray"
            Write-Log "    Standard apostrophe: $($standardAposItem.Name) ($standardSize bytes)" "Gray"

            if ($dryRun) {
                if ($smartSize -gt $standardSize) {
                    Write-Log "    [DRY RUN] Would delete standard version (stub), rename smart version" "Magenta"
                } elseif ($standardSize -gt $smartSize) {
                    Write-Log "    [DRY RUN] Would delete smart version (stub), keep standard version" "Magenta"
                } else {
                    Write-Log "    [DRY RUN] Same size - would delete smart version, keep standard" "Magenta"
                }
            } else {
                try {
                    if ($smartSize -gt $standardSize) {
                        # Smart apostrophe version is larger (real file)
                        # Delete the standard apostrophe stub, then rename the smart one
                        Remove-Item -Path $standardAposItem.FullName -Force -Recurse -ErrorAction Stop
                        Rename-Item -Path $smartAposItem.FullName -NewName $normalizedName -ErrorAction Stop
                        Write-Log "    Resolved: Deleted stub, renamed real file to standard apostrophe" "Green"
                        $script:duplicatesResolved++
                    } elseif ($standardSize -gt $smartSize) {
                        # Standard apostrophe version is larger (real file)
                        # Delete the smart apostrophe stub
                        Remove-Item -Path $smartAposItem.FullName -Force -Recurse -ErrorAction Stop
                        Write-Log "    Resolved: Deleted smart apostrophe stub, kept standard version" "Green"
                        $script:duplicatesResolved++
                    } else {
                        # Same size - prefer standard apostrophe version, delete smart one
                        Remove-Item -Path $smartAposItem.FullName -Force -Recurse -ErrorAction Stop
                        Write-Log "    Resolved: Same size, deleted smart apostrophe version" "Green"
                        $script:duplicatesResolved++
                    }
                } catch {
                    Write-Log "    ERROR: Failed to resolve duplicate - $_" "Red"
                }
            }
        }
    }

    if ($duplicatesFound -eq 0) {
        Write-Log "  No duplicates found" "Green"
    } else {
        Write-Log "  Found $duplicatesFound duplicate pairs, resolved $($script:duplicatesResolved)" "Green"
    }
}

# =============================================================================
# PHASE 1c: Trim leading/trailing whitespace from filenames
# =============================================================================
# Finds markdown files with leading or trailing whitespace in their names,
# renames them to trimmed versions, and fixes any links that referenced
# the old names (since Obsidian doesn't auto-update these links).
# =============================================================================

# Track trimmed files for link fixing
$script:trimmedFileRenames = [System.Collections.ArrayList]@()

function Trim-FilenameWhitespace {
    Write-Log "=== Phase 1c: Trimming whitespace from filenames ===" "Cyan"

    # Find all markdown files with leading or trailing whitespace in names
    # NOTE: We check $_.Name directly because $_.BaseName is unreliable when there's
    # a space before .md - Windows treats " .md" as the extension, so BaseName includes .md
    $filesToTrim = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\s' -or $_.Name -match '\s\.md$' }

    if ($filesToTrim.Count -eq 0) {
        Write-Log "  No files need whitespace trimming" "Green"
        return
    }

    Write-Log "  Found $($filesToTrim.Count) files with whitespace in names" "Yellow"

    foreach ($file in $filesToTrim) {
        # Skip if file no longer exists
        if (-not (Test-Path $file.FullName)) { continue }

        # Extract base name manually - don't use $file.BaseName as it's unreliable
        # when there's a space before .md (Windows treats " .md" as extension)
        $oldName = $file.Name -replace '\.md$', ''
        $newName = $oldName.Trim()
        $newPath = Join-Path $file.DirectoryName "$newName.md"

        # Check if target already exists
        if (Test-Path $newPath) {
            Write-Log "  SKIP: Target exists: $newName" "DarkYellow"
            continue
        }

        if ($dryRun) {
            Write-Log "  [DRY RUN] Would trim: '$oldName' -> '$newName'" "Magenta"
            $script:filenamesTrimmed++
        } else {
            try {
                Rename-Item -Path $file.FullName -NewName "$newName.md" -ErrorAction Stop

                # Track the rename for link fixing
                [void]$script:trimmedFileRenames.Add([PSCustomObject]@{
                    OldName = $oldName
                    NewName = $newName
                })

                $script:filenamesTrimmed++
            } catch {
                Write-Log "  ERROR: Failed to trim '$oldName' - $_" "Red"
            }
        }
    }

    Write-Log "  Trimmed $($script:filenamesTrimmed) filenames" "Green"

    # Now fix links to the renamed files
    if ($script:trimmedFileRenames.Count -gt 0 -and -not $dryRun) {
        Write-Log "  Fixing links to trimmed files..." "Gray"
        Fix-TrimmedFileLinks
    }
}

# Helper function to fix links after filename trimming
function Fix-TrimmedFileLinks {
    if ($script:trimmedFileRenames.Count -eq 0) { return }

    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count
    $processedFiles = 0

    foreach ($mdFile in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "    Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            $content = Get-Content -Path $mdFile.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if (-not $content) { continue }
        } catch {
            continue
        }

        $originalContent = $content
        $fileModified = $false

        foreach ($rename in $script:trimmedFileRenames) {
            $oldName = $rename.OldName
            $newName = $rename.NewName

            # Escape special regex characters in the old name
            $escapedOldName = [regex]::Escape($oldName)

            # Pattern matches [[oldname]], [[oldname|alias]], [[oldname#heading]]
            # Replace with the trimmed name while preserving alias/heading
            if ($content -match "\[\[$escapedOldName(\]\]|\||#)") {
                $content = $content -replace "\[\[$escapedOldName\]\]", "[[$newName]]"
                $content = $content -replace "\[\[$escapedOldName\|", "[[$newName|"
                $content = $content -replace "\[\[$escapedOldName#", "[[$newName#"
                $fileModified = $true
                $script:trimmedLinksFixed++
            }
        }

        if ($fileModified -and $content -ne $originalContent) {
            try {
                Set-Content -Path $mdFile.FullName -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
            } catch {
                Write-Log "    ERROR: Failed to update $($mdFile.Name) - $_" "Red"
            }
        }
    }

    Write-Log "  Fixed $($script:trimmedLinksFixed) links to trimmed files" "Green"
}

# =============================================================================
# PHASE 2: Rename unknown_filename images to meaningful names
# =============================================================================
function Rename-UnknownFilenameImages {
    Write-Log "=== Phase 2: Renaming unknown_filename images ===" "Cyan"

    $unknownFiles = Get-ChildItem -Path "$vaultPath\00 - Images" -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "^unknown_filename" }

    if ($unknownFiles.Count -eq 0) {
        Write-Log "  No unknown_filename images found" "Green"
        return
    }

    Write-Log "  Found $($unknownFiles.Count) images to rename" "Yellow"

    $groupedFiles = $unknownFiles | Group-Object { $_.Directory.FullName }

    foreach ($group in $groupedFiles) {
        $directory = $group.Name
        $files = $group.Group | Sort-Object Name
        $parentFolder = Split-Path $directory -Leaf
        $baseName = $parentFolder -replace '\.resources$', ''

        if ($baseName.Length -gt 80) {
            $baseName = $baseName.Substring(0, 80)
        }

        $counter = 1
        foreach ($file in $files) {
            $extension = $file.Extension
            $oldName = $file.Name
            $newName = "${baseName}_img${counter}${extension}"

            $newPath = Join-Path $directory $newName
            if ($newPath.Length -gt $maxPathLength) {
                $excess = $newPath.Length - $maxPathLength + 10
                $baseName = $baseName.Substring(0, [Math]::Max(20, $baseName.Length - $excess))
                $newName = "${baseName}_img${counter}${extension}"
                $newPath = Join-Path $directory $newName
            }

            if (Test-Path $newPath) {
                $counter++
                continue
            }

            if ($dryRun) {
                Write-Log "  [DRY RUN] Would rename: $oldName -> $newName" "Magenta"
            } else {
                try {
                    Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop

                    $oldRelPath = $file.FullName.Substring($vaultPath.Length + 1).Replace("\", "/")
                    $newRelPath = $newPath.Substring($vaultPath.Length + 1).Replace("\", "/")

                    [void]$script:renamedImages.Add([PSCustomObject]@{
                        OldPath = $oldRelPath
                        NewPath = $newRelPath
                        OldName = $oldName
                        NewName = $newName
                    })

                    $script:imagesRenamed++
                } catch {
                    Write-Log "  ERROR: Failed to rename $oldName - $_" "Red"
                }
            }

            $counter++
        }
    }

    Write-Log "  Renamed $($script:imagesRenamed) images" "Green"
}

# =============================================================================
# PHASE 3: Build comprehensive file index for link resolution
# =============================================================================
function Build-FileIndex {
    Write-Log "=== Phase 3: Building file index ===" "Cyan"

    $script:fileLookup = @{}

    # Add renamed images to lookup
    foreach ($renamed in $script:renamedImages) {
        $script:fileLookup[$renamed.OldPath] = $renamed.NewPath
    }

    # Index remaining files with "unknown_filename" in 00 - Images
    $imageFiles = Get-ChildItem -Path "$vaultPath\00 - Images" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "^unknown_filename" }

    foreach ($file in $imageFiles) {
        $resourceFolder = $file.Directory.Name
        $fileName = $file.Name
        $relativePath = $file.FullName.Substring($vaultPath.Length + 1).Replace("\", "/")

        $key = "$resourceFolder/$fileName"
        $script:fileLookup[$key] = $relativePath

        $normalizedKey = Normalize-Text $key
        if ($normalizedKey -ne $key) {
            $script:fileLookup[$normalizedKey] = $relativePath
        }
    }

    # Build comprehensive folder-to-images mapping for Evernote-Resources
    $imagesPath = "$vaultPath\00 - Images\Evernote-Resources"
    if (Test-Path $imagesPath) {
        $allFolders = Get-ChildItem -Path $imagesPath -Directory -ErrorAction SilentlyContinue

        foreach ($folder in $allFolders) {
            $folderName = $folder.Name

            $folderImageFiles = Get-ChildItem -Path $folder.FullName -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -match '\.(png|jpeg|jpg|gif|webp|svg)$' }

            if ($folderImageFiles.Count -gt 0) {
                $imagePaths = @()
                foreach ($img in $folderImageFiles) {
                    $relativePath = $img.FullName.Substring($vaultPath.Length + 1).Replace("\", "/")
                    $imagePaths += $relativePath
                }

                $normalizedName = $folderName -replace "[$curlyApostrophe$leftApostrophe$backtick]", $standardApostrophe
                $script:folderToImages[$normalizedName] = $imagePaths

                # Also add with .resources suffix for matching old links
                $withResources = "$normalizedName.resources"
                $script:folderToImages[$withResources] = $imagePaths
            }
        }

        # Also map .resources subfolders directly
        $resourcesSubFolders = Get-ChildItem -Path $imagesPath -Directory -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '\.resources$' }

        foreach ($folder in $resourcesSubFolders) {
            $folderName = $folder.Name
            $normalizedName = $folderName -replace "[$curlyApostrophe$leftApostrophe$backtick]", $standardApostrophe

            if ($script:folderToImages.ContainsKey($normalizedName)) { continue }

            $folderImageFiles = Get-ChildItem -Path $folder.FullName -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -match '\.(png|jpeg|jpg|gif|webp|svg)$' }

            if ($folderImageFiles.Count -gt 0) {
                $imagePaths = @()
                foreach ($img in $folderImageFiles) {
                    $relativePath = $img.FullName.Substring($vaultPath.Length + 1).Replace("\", "/")
                    $imagePaths += $relativePath
                }
                $script:folderToImages[$normalizedName] = $imagePaths
            }
        }
    }

    Write-Log "  Indexed $($script:fileLookup.Count) file mappings" "Green"
    Write-Log "  Indexed $($script:folderToImages.Count) folder mappings" "Green"
}

# =============================================================================
# PHASE 4: Fix broken links in markdown files
# =============================================================================
function Fix-BrokenLinks {
    Write-Log "=== Phase 4: Fixing links in markdown files ===" "Cyan"

    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count
    $processedFiles = 0

    foreach ($mdFile in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            $content = Get-Content -Path $mdFile.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if (-not $content) { continue }
        } catch {
            continue
        }

        $originalContent = $content
        $fileModified = $false

        # Update links for renamed images
        foreach ($oldPath in $script:fileLookup.Keys) {
            $newPath = $script:fileLookup[$oldPath]
            $escapedOld = [regex]::Escape($oldPath)

            if ($content -match "\[\[$escapedOld\]\]") {
                $content = $content -replace "\[\[$escapedOld\]\]", "[[$newPath]]"
                $fileModified = $true
                $script:linksFixed++
            }
        }

        # Pattern to match links with unknown_filename (legacy broken links)
        $pattern = '\[\[([^\]]*unknown_filename[^\]]*)\]\]'
        $matches = [regex]::Matches($content, $pattern)

        foreach ($match in $matches) {
            $brokenLink = $match.Groups[1].Value
            $normalizedLink = Normalize-Text $brokenLink

            if ($normalizedLink -match '([^/]+\.resources)/(unknown_filename[^/\]]*)$') {
                $resourceFolder = $Matches[1]
                $fileName = $Matches[2]
                $lookupKey = "$resourceFolder/$fileName"

                if ($script:fileLookup.ContainsKey($lookupKey)) {
                    $correctPath = $script:fileLookup[$lookupKey]
                    $oldText = $match.Value
                    $newText = "[[$correctPath]]"

                    if ($oldText -ne $newText) {
                        $content = $content.Replace($oldText, $newText)
                        $fileModified = $true
                        $script:linksFixed++
                    }
                }
            }
        }

        # Normalize any remaining curly apostrophes in links
        $apostrophePattern = "\[\[([^\]]*[$curlyApostrophe$leftApostrophe$backtick][^\]]*)\]\]"
        $apostropheMatches = [regex]::Matches($content, $apostrophePattern)

        foreach ($match in $apostropheMatches) {
            $oldLink = $match.Groups[1].Value
            $newLink = Normalize-Text $oldLink

            if ($oldLink -ne $newLink) {
                $content = $content.Replace($match.Value, "[[$newLink]]")
                $fileModified = $true
            }
        }

        if ($fileModified -and $content -ne $originalContent) {
            if ($dryRun) {
                Write-Log "  [DRY RUN] Would update: $($mdFile.Name)" "Magenta"
            } else {
                try {
                    Set-Content -Path $mdFile.FullName -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
                    $script:filesModified++
                } catch {
                    Write-Log "  ERROR: Failed to update $($mdFile.Name) - $_" "Red"
                }
            }
        }
    }
}

# =============================================================================
# PHASE 5: Fix legacy Evernote paths to new image locations
# =============================================================================
function Fix-LegacyEvernotePaths {
    Write-Log "=== Phase 5: Fixing legacy Evernote paths ===" "Cyan"

    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count
    $processedFiles = 0
    $legacyLinksFixed = 0

    foreach ($mdFile in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            $content = Get-Content -Path $mdFile.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if (-not $content) { continue }
        } catch {
            continue
        }

        $originalContent = $content
        $fileModified = $false

        # Pattern: Match any path containing .resources/unknown_filename
        $pattern = "(!\[\[|(?<!\!)\[\[)([^\]]*?)([^/]+\.resources)/unknown_filename(\.[0-9]*)?(\.[^\]]+)\]\]"

        $allMatches = [regex]::Matches($content, $pattern)

        foreach ($match in $allMatches) {
            $prefix = $match.Groups[1].Value      # ![[ or [[
            $pathBefore = $match.Groups[2].Value  # path before folder name
            $resourceFolder = $match.Groups[3].Value  # folder.resources
            $numSuffix = $match.Groups[4].Value   # .1, .2 etc
            $extension = $match.Groups[5].Value   # .jpeg, .png
            $oldLink = $match.Value

            $normalizedFolder = $resourceFolder -replace "[$curlyApostrophe$leftApostrophe$backtick]", $standardApostrophe

            # Try to find in mapping
            if ($script:folderToImages.ContainsKey($normalizedFolder)) {
                $newImages = $script:folderToImages[$normalizedFolder]
                $matchingImage = $newImages | Where-Object { $_ -like "*$extension" } | Select-Object -First 1

                if ($matchingImage) {
                    if ($prefix -eq "![[") {
                        $newLink = "![[$matchingImage]]"
                    } else {
                        $newLink = "[[$matchingImage]]"
                    }
                    $content = $content.Replace($oldLink, $newLink)
                    $fileModified = $true
                    $legacyLinksFixed++
                }
            } else {
                # Try partial matching - extract base name without long suffix
                $baseName = $normalizedFolder -replace '\.resources$', ''

                if ($baseName.Length -gt 30) {
                    $searchPrefix = $baseName.Substring(0, 30)
                    $matchingKey = $script:folderToImages.Keys | Where-Object { $_ -like "$searchPrefix*" } | Select-Object -First 1

                    if ($matchingKey) {
                        $newImages = $script:folderToImages[$matchingKey]
                        $matchingImage = $newImages | Where-Object { $_ -like "*$extension" } | Select-Object -First 1

                        if ($matchingImage) {
                            if ($prefix -eq "![[") {
                                $newLink = "![[$matchingImage]]"
                            } else {
                                $newLink = "[[$matchingImage]]"
                            }
                            $content = $content.Replace($oldLink, $newLink)
                            $fileModified = $true
                            $legacyLinksFixed++
                        }
                    }
                }
            }
        }

        if ($fileModified -and $content -ne $originalContent) {
            if ($dryRun) {
                Write-Log "  [DRY RUN] Would update: $($mdFile.Name)" "Magenta"
            } else {
                try {
                    Set-Content -Path $mdFile.FullName -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
                    $script:filesModified++
                } catch {
                    Write-Log "  ERROR: Failed to update $($mdFile.Name) - $_" "Red"
                }
            }
        }
    }

    $script:linksFixed += $legacyLinksFixed
    Write-Log "  Fixed $legacyLinksFixed legacy Evernote links" "Green"
}

# =============================================================================
# PHASE 6: Generate Empty Notes list
# =============================================================================
# Finds all markdown files that contain only a title heading and optional
# metadata (frontmatter, nav line, tags) but no actual body content.
# Creates/updates "Empty Notes.md" with links to these files.
# =============================================================================
function Generate-EmptyNotesList {
    Write-Log "=== Phase 6: Generating Empty Notes list ===" "Cyan"

    $emptyNotes = @()

    # Get all markdown files in the vault
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

    foreach ($file in $mdFiles) {
        # Skip the Empty Notes file itself
        if ($file.Name -eq "Empty Notes.md") { continue }

        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }

            # Remove frontmatter (YAML between --- markers)
            $contentNoFrontmatter = $content -replace '(?s)^---.*?---\s*', ''

            # Get non-empty lines
            $lines = ($contentNoFrontmatter -split "`n") |
                Where-Object { $_.Trim() -ne '' } |
                ForEach-Object { $_.Trim() }

            # Count lines that are actual content (not title, nav, or tags)
            $contentLines = $lines | Where-Object {
                # Skip headings
                $_ -notmatch '^#+\s+' -and
                # Skip nav lines
                $_ -notmatch '^nav:' -and
                # Skip standalone tags
                $_ -notmatch '^\s*#\w+\s*$' -and
                # Skip tag lists
                $_ -notmatch '^tags:' -and
                # Skip empty list items or simple breadcrumbs
                $_ -notmatch '^\s*-\s*\[\[.+\]\]\s*$'
            }

            # If no content lines, consider it empty
            if ($contentLines.Count -eq 0) {
                $emptyNotes += @{
                    Name = $file.BaseName
                    RelPath = $file.FullName.Replace($vaultPath + '\', '').Replace('\', '/')
                }
            }
        } catch {}
    }

    # Sort by relative path
    $emptyNotes = $emptyNotes | Sort-Object { $_.RelPath }

    $script:emptyNotesFound = $emptyNotes.Count

    # Create markdown content
    $mdContent = "# Empty Notes (Title Only)`n`n"
    $mdContent += "These notes contain no content other than a title heading and optional metadata.`n`n"
    $mdContent += "**Total: $($emptyNotes.Count) files**`n`n"
    $mdContent += "*Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*`n`n"

    foreach ($note in $emptyNotes) {
        # Create Obsidian wiki link using the base name
        $mdContent += "- [[$($note.Name)]]`n"
    }

    # Write to file
    $outputPath = Join-Path $vaultPath "Empty Notes.md"

    if ($dryRun) {
        Write-Log "  [DRY RUN] Would create Empty Notes.md with $($emptyNotes.Count) entries" "Magenta"
    } else {
        try {
            Set-Content -Path $outputPath -Value $mdContent -Encoding UTF8 -NoNewline
            Write-Log "  Created Empty Notes.md with $($emptyNotes.Count) entries" "Green"
        } catch {
            Write-Log "  ERROR: Failed to create Empty Notes.md - $_" "Red"
        }
    }
}

# =============================================================================
# PHASE 7: Generate Truncated Filenames list
# =============================================================================
# Finds all markdown files with truncated names (last word not in dictionary
# and appears cut off mid-word). Uses pattern matching and dictionary lookup.
# Creates/updates "Truncated Filenames.md" with links to these files.
# =============================================================================
function Generate-TruncatedFilenamesList {
    Write-Log "=== Phase 7: Generating Truncated Filenames list ===" "Cyan"

    # Download word list if needed
    if (-not (Test-Path $script:wordListPath)) {
        Write-Log "  Downloading English word list..." "Yellow"
        try {
            Invoke-WebRequest -Uri $script:wordListUrl -OutFile $script:wordListPath -UseBasicParsing
            Write-Log "  Word list downloaded." "Green"
        } catch {
            Write-Log "  ERROR: Failed to download word list - $_" "Red"
            return
        }
    }

    # Load dictionary if not already loaded
    if ($null -eq $script:dictionary) {
        Write-Log "  Loading dictionary..." "Gray"
        $script:dictionary = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        Get-Content $script:wordListPath | ForEach-Object {
            [void]$script:dictionary.Add($_.Trim().ToLower())
        }

        # Add common terms not in standard dictionary
        $additionalWords = @(
            # Tech terms
            'kanban', 'onenote', 'evernote', 'obsidian', 'kindle', 'arduino', 'github', 'gitlab',
            'postgresql', 'mongodb', 'nodejs', 'javascript', 'typescript', 'kubernetes', 'dockerfile',
            'wifi', 'bluetooth', 'hdmi', 'usb', 'html', 'css', 'json', 'xml', 'sql', 'api', 'url',
            'iphone', 'ipad', 'macos', 'ios', 'linux', 'ubuntu', 'debian', 'nvidia', 'amd', 'intel',
            # Common proper nouns
            'bahai', 'quran', 'torah', 'buddhist', 'hindu', 'sikh', 'zoroastrian',
            # Food terms
            'kimchi', 'tofu', 'tempeh', 'hummus', 'falafel', 'tahini', 'miso', 'ramen', 'udon',
            'chutney', 'naan', 'chapati', 'samosa', 'biryani', 'teriyaki', 'wasabi', 'edamame',
            'quinoa', 'acai', 'kombucha', 'matcha', 'chai', 'boba', 'pho', 'banh',
            # Names/surnames
            'aiden', 'bryant', 'garcia', 'martinez', 'rodriguez', 'hernandez', 'lopez', 'gonzalez',
            'uberstzig', 'powell', 'klein', 'utne', 'hahn', 'ahmad', 'frys',
            # Tech/common terms from truncated filenames
            'perl', 'wiki',
            # Other common terms
            'podcast', 'ebook', 'audiobook', 'vegan', 'keto', 'paleo', 'gluten', 'probiotic',
            'cryptocurrency', 'blockchain', 'bitcoin', 'ethereum', 'nft', 'defi',
            'covid', 'coronavirus', 'pandemic', 'vaccine', 'mrna',
            'lgbt', 'lgbtq', 'bipoc', 'dei', 'juneteenth', 'kwanzaa', 'hanukkah', 'diwali', 'ramadan', 'eid',
            # Short words
            'md', 'vs', 'tv', 'uk', 'us', 'dc', 'ny', 'la', 'sf', 'ai', 'pc', 'dj', 'ok'
        )
        foreach ($word in $additionalWords) {
            [void]$script:dictionary.Add($word.ToLower())
        }
        Write-Log "  Loaded $($script:dictionary.Count) words" "Gray"
    }

    # Truncation pattern indicators - words ending in these are likely truncated
    $truncationPatterns = @(
        'nv', 'lv', 'rv', 'nf', 'lf', 'rf', 'nc', 'lc', 'rc', 'ng',
        'mb', 'mp', 'nt', 'nd', 'nk', 'ns', 'ct', 'pt', 'ft',
        'qu', 'sq', 'tw', 'sw', 'dw', 'gw',
        'bl', 'cl', 'fl', 'gl', 'pl', 'sl', 'br', 'cr', 'dr', 'fr', 'gr', 'pr', 'tr',
        'sc', 'sk', 'sm', 'sn', 'sp', 'st', 'sw',
        'th', 'ch', 'sh', 'wh', 'ph',
        'xp', 'xc', 'xh', 'xt',
        'ib', 'ob', 'ab', 'eb', 'ub',
        'ig', 'og', 'ag', 'eg', 'ug',
        'iv', 'ov', 'av', 'ev', 'uv',
        'iz', 'oz', 'az', 'ez', 'uz'
    )

    # Valid word endings
    $validEndings = @(
        'ing', 'tion', 'sion', 'ness', 'ment', 'able', 'ible', 'ful', 'less', 'ous', 'ive',
        'ary', 'ery', 'ory', 'ty', 'ly', 'al', 'er', 'or', 'ist', 'ism', 'ity', 'ure',
        'age', 'ance', 'ence', 'dom', 'hood', 'ship', 'ward', 'wise', 'like',
        'ed', 'es', 's', 'y', 'e', 'a', 'o', 'i'
    )

    # Function to check if a word looks truncated
    $testTruncated = {
        param([string]$word)

        $cleanWord = $word -replace '[^a-zA-Z]', ''
        if ($cleanWord.Length -lt 3) { return $false }
        if ($script:dictionary.Contains($cleanWord.ToLower())) { return $false }

        # Check valid endings
        foreach ($ending in $validEndings) {
            if ($cleanWord.Length -gt $ending.Length -and $cleanWord.ToLower().EndsWith($ending)) {
                if ($cleanWord.Length -ge 6) { return $false }
            }
        }

        # Check truncation patterns
        $lowerWord = $cleanWord.ToLower()
        $lastTwo = if ($lowerWord.Length -ge 2) { $lowerWord.Substring($lowerWord.Length - 2) } else { "" }

        foreach ($pattern in $truncationPatterns) {
            if ($lastTwo -eq $pattern) { return $true }
        }

        # Short unknown words are likely truncated
        if ($cleanWord.Length -le 5) { return $true }

        # Check if it's a prefix of a longer word
        if ($cleanWord.Length -ge 4) {
            $prefix = $cleanWord.ToLower()
            foreach ($dictWord in $script:dictionary) {
                if ($dictWord.StartsWith($prefix) -and $dictWord.Length -gt $prefix.Length + 2) {
                    return $true
                }
            }
        }

        return $false
    }

    # Find truncated filenames
    $truncatedFiles = @()
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

    foreach ($file in $mdFiles) {
        $baseName = $file.BaseName

        # Skip date-named files, .md in name, resource folders
        if ($baseName -match '^\d{4}-\d{2}-\d{2}') { continue }
        if ($baseName -match '\.md$') { continue }
        if ($baseName -match '\.resources$') { continue }

        # Split into words and get last alphabetic word
        $words = $baseName -split '[\s\-_]+'
        $lastWord = $null
        for ($i = $words.Count - 1; $i -ge 0; $i--) {
            if ($words[$i] -match '[a-zA-Z]') {
                $lastWord = $words[$i]
                break
            }
        }

        if (-not $lastWord) { continue }

        $cleanLastWord = $lastWord -replace '[^a-zA-Z]', ''
        if ($cleanLastWord.Length -lt 2) { continue }

        # Skip acronyms and camelCase
        if ($cleanLastWord -cmatch '^[A-Z]+$') { continue }
        if ($cleanLastWord -cmatch '[a-z][A-Z]') { continue }

        # Handle number suffixes
        if ($lastWord -match '^[a-zA-Z]+\d+$') {
            $cleanLastWord = $lastWord -replace '\d+$', ''
        }

        if (& $testTruncated $cleanLastWord) {
            $truncatedFiles += @{
                Name = $file.BaseName
                LastWord = $cleanLastWord
            }
        }
    }

    $truncatedFiles = $truncatedFiles | Sort-Object { $_.Name }
    $script:truncatedFilesFound = $truncatedFiles.Count

    # Create markdown content
    $mdContent = "# Truncated Filenames`n`n"
    $mdContent += "Notes with potentially truncated names (last word appears cut off).`n`n"
    $mdContent += "**Total: $($truncatedFiles.Count) files**`n`n"
    $mdContent += "*Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*`n`n"
    $mdContent += "| Note | Truncated Word |`n"
    $mdContent += "|------|----------------|`n"

    foreach ($file in $truncatedFiles) {
        $mdContent += "| [[$($file.Name)]] | ``$($file.LastWord)`` |`n"
    }

    $outputPath = Join-Path $vaultPath "Truncated Filenames.md"

    if ($dryRun) {
        Write-Log "  [DRY RUN] Would create Truncated Filenames.md with $($truncatedFiles.Count) entries" "Magenta"
    } else {
        try {
            Set-Content -Path $outputPath -Value $mdContent -Encoding UTF8 -NoNewline
            Write-Log "  Created Truncated Filenames.md with $($truncatedFiles.Count) entries" "Green"
        } catch {
            Write-Log "  ERROR: Failed to create Truncated Filenames.md - $_" "Red"
        }
    }
}

# =============================================================================
# PHASE 8: Delete small image files in .resources folders
# =============================================================================
# Removes tiny images (<3KB) that are typically tracker pixels, spacer GIFs,
# small icons, and other web clipping artifacts that serve no purpose.
# =============================================================================
function Delete-SmallResourceImages {
    Write-Log "=== Phase 8: Deleting small images in .resources folders ===" "Cyan"

    # Find all .resources folders
    $resourcesFolders = Get-ChildItem -Path $vaultPath -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*.resources" }

    if ($resourcesFolders.Count -eq 0) {
        Write-Log "  No .resources folders found" "Green"
        return
    }

    foreach ($folder in $resourcesFolders) {
        $images = Get-ChildItem -Path $folder.FullName -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '\.(png|jpg|jpeg|gif|ico|svg|webp)$' -and $_.Length -lt 3000 }

        foreach ($img in $images) {
            if ($dryRun) {
                Write-Log "  [DRY RUN] Would delete: $($folder.Name)/$($img.Name)" "Magenta"
                $script:smallImagesDeleted++
            } else {
                try {
                    Remove-Item -Path $img.FullName -Force -ErrorAction Stop
                    $script:smallImagesDeleted++
                } catch {
                    Write-Log "  ERROR: $($img.Name) - $_" "Red"
                }
            }
        }
    }

    Write-Log "  Deleted $($script:smallImagesDeleted) small images" "Green"
}

# =============================================================================
# PHASE 9: Delete empty folders
# =============================================================================
# Removes empty folders left behind after image cleanup and other operations.
# Runs multiple passes since deleting subfolders may leave parent folders empty.
# =============================================================================
function Delete-EmptyFolders {
    Write-Log "=== Phase 9: Deleting empty folders ===" "Cyan"

    # Keep running until no more empty folders found
    do {
        $deletedThisPass = 0

        # Get all directories, sorted by depth (deepest first)
        $folders = Get-ChildItem -Path $vaultPath -Directory -Recurse -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Split('\').Count } -Descending

        foreach ($folder in $folders) {
            # Skip if folder no longer exists
            if (-not (Test-Path $folder.FullName)) { continue }

            # Check if folder is empty (no files and no subfolders)
            $items = Get-ChildItem -Path $folder.FullName -Force -ErrorAction SilentlyContinue

            if ($items.Count -eq 0) {
                if ($dryRun) {
                    Write-Log "  [DRY RUN] Would delete: $($folder.FullName.Replace($vaultPath + '\', ''))" "Magenta"
                    $deletedThisPass++
                    $script:emptyFoldersDeleted++
                } else {
                    try {
                        Remove-Item -Path $folder.FullName -Force -ErrorAction Stop
                        $deletedThisPass++
                        $script:emptyFoldersDeleted++
                    } catch {
                        Write-Log "  ERROR: $($folder.Name) - $_" "Red"
                    }
                }
            }
        }
    } while ($deletedThisPass -gt 0 -and -not $dryRun)

    Write-Log "  Deleted $($script:emptyFoldersDeleted) empty folders" "Green"
}

# =============================================================================
# PHASE 10: Add #task tag to uncompleted checkboxes
# =============================================================================
# Finds all uncompleted checkbox patterns (- [ ]) that are not followed by
# the #task tag and adds the tag. This ensures all tasks are properly tagged
# for Obsidian task queries and plugins.
# =============================================================================
function Add-TaskTagsToCheckboxes {
    Write-Log "=== Phase 10: Adding #task tags to checkboxes ===" "Cyan"

    # Get all markdown files in the vault
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count
    $processedFiles = 0
    $filesModifiedThisPhase = 0

    foreach ($mdFile in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            # Read file content as UTF-8
            $content = Get-Content -Path $mdFile.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if ($null -eq $content) { continue }

            # Pattern: Match '- [ ] ' followed by optional extra spaces (0-3),
            # but NOT followed by #task. Capture the first non-whitespace character after.
            # This ensures we only add #task where it's missing.
            $pattern = '(- \[ \] {0,3})(?!#task)(\S)'
            $replacement = '- [ ] #task $2'

            # Count matches before replacement
            $matches = [regex]::Matches($content, $pattern)

            if ($matches.Count -gt 0) {
                # Perform replacement
                $newContent = [regex]::Replace($content, $pattern, $replacement)

                if ($dryRun) {
                    Write-Log "  [DRY RUN] Would add $($matches.Count) #task tags: $($mdFile.Name)" "Magenta"
                    $script:taskTagsAdded += $matches.Count
                } else {
                    # Write back to file
                    Set-Content -Path $mdFile.FullName -Value $newContent -NoNewline -Encoding UTF8 -ErrorAction Stop
                    $script:taskTagsAdded += $matches.Count
                    $filesModifiedThisPhase++
                }
            }
        } catch {
            # Skip files that can't be read or written
            continue
        }
    }

    Write-Log "  Added #task tag to $($script:taskTagsAdded) checkboxes in $filesModifiedThisPhase files" "Green"
}

# =============================================================================
# PHASE 11: Fix broken image links
# =============================================================================
# Finds image embeds (![[image.jpg]]) that point to non-existent paths,
# locates the actual image file elsewhere in the vault by filename,
# and updates the link to the correct path using forward slashes.
#
# Handles:
# - Character encoding mismatches common in Evernote exports where
#   special characters like » may appear differently in links vs actual files.
# - OneNote export paths where images are in .md folders but links point to
#   wrong directory (e.g., 12 - OneNote/... instead of 20 - Permanent Notes/...)
# =============================================================================

# Helper function to normalize a filename for fuzzy matching
# Removes/replaces special characters that may be encoded differently
function Normalize-ImageFileName {
    param([string]$Name)

    # Convert to lowercase first
    $normalized = $Name.ToLower()

    # Replace common problem characters with underscores
    # » (U+00BB), « (U+00AB), various dashes, special quotes, etc.
    $normalized = $normalized -replace '[\u00AB\u00BB\u2013\u2014\u2018\u2019\u201C\u201D\u2026]', '_'

    # Collapse multiple underscores/spaces into single underscore
    $normalized = $normalized -replace '[\s_]+', '_'

    # Remove any remaining non-ASCII characters
    $normalized = $normalized -replace '[^\x00-\x7F]', ''

    return $normalized
}

# Helper function to extract a base prefix for fuzzy matching
# Gets everything before _imgN or the last 20+ chars before extension
function Get-ImageBasePrefix {
    param([string]$Name)

    try {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Name)
    } catch {
        # If path has illegal characters, just use the name directly
        $baseName = $Name -replace '\.[^.]+$', ''
    }

    if (-not $baseName) { return "" }

    # If filename contains _img followed by digits, get everything before it
    if ($baseName -match '^(.+?)_img\d+$') {
        return $Matches[1].ToLower()
    }

    # Otherwise return first 25 chars (if long enough) for prefix matching
    if ($baseName.Length -gt 25) {
        return $baseName.Substring(0, 25).ToLower()
    }

    return $baseName.ToLower()
}

# Helper function to fix OneNote exported image paths
# OneNote exports create paths like: 12 - OneNote/.../Note.md/Exported image TIMESTAMP.ext
# But images actually exist in: 20 - Permanent Notes/Note.md/Exported image TIMESTAMP.ext
function Fix-OneNoteImagePaths {
    param(
        [string]$Content,           # File content to fix
        [hashtable]$ImageIndex,     # Index of image filenames to paths
        [ref]$FixCount              # Counter for fixes made
    )

    $result = $Content

    # Pattern to match URL-encoded OneNote image paths
    # Matches: 12%20-%20OneNote/.../Something.md/Exported%20image%20TIMESTAMP.ext
    $pattern = '12%20-%20OneNote/.*?\.md/Exported%20image%20\d{14}-\d+\.(png|jpg|jpeg|gif|webp)'

    $allMatches = [regex]::Matches($result, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    foreach ($match in $allMatches) {
        $brokenPath = $match.Value

        # URL-decode the entire path to extract the image filename
        $decodedPath = [System.Uri]::UnescapeDataString($brokenPath)

        # Extract just the image filename (e.g., "Exported image 20240909143732-0.png")
        if ($decodedPath -match '(Exported image \d{14}-\d+\.(png|jpg|jpeg|gif|webp))$') {
            $imageFileName = $Matches[1]

            # Look up this image in our index
            if ($ImageIndex.ContainsKey($imageFileName)) {
                $correctPath = $ImageIndex[$imageFileName]

                # URL-encode the new path (but keep forward slashes)
                $encodedCorrectPath = [System.Uri]::EscapeDataString($correctPath) -replace '%2F', '/'

                # Replace in content
                $result = $result.Replace($brokenPath, $encodedCorrectPath)
                $FixCount.Value++
            }
        }
    }

    return $result
}

function Fix-BrokenImageLinks {
    Write-Log "=== Phase 11: Fixing broken image links ===" "Cyan"

    # Build index of all image files in the vault
    # We create multiple lookup mechanisms:
    # 1. Exact filename match (case-insensitive)
    # 2. Normalized filename match (strips special chars)
    # 3. Prefix-based match (for fuzzy matching)
    # 4. OneNote "Exported image" files by timestamp filename
    Write-Log "  Building image file index..." "Gray"
    $imageIndex = @{}           # Exact filename -> full path
    $normalizedIndex = @{}      # Normalized filename -> full path
    $prefixIndex = @{}          # Base prefix -> list of full paths
    $exportedImageIndex = @{}   # "Exported image TIMESTAMP.ext" -> relative path (for OneNote)
    $imageExtensions = @('*.jpg', '*.jpeg', '*.png', '*.gif', '*.webp', '*.svg', '*.ico')

    foreach ($ext in $imageExtensions) {
        $images = Get-ChildItem -Path $vaultPath -Filter $ext -Recurse -ErrorAction SilentlyContinue
        foreach ($img in $images) {
            $fullPath = $img.FullName

            # 1. Exact filename match (case-insensitive)
            $exactKey = $img.Name.ToLower()
            if (-not $imageIndex.ContainsKey($exactKey)) {
                $imageIndex[$exactKey] = $fullPath
            }

            # 2. Normalized filename match
            $normalizedKey = Normalize-ImageFileName $img.Name
            if (-not $normalizedIndex.ContainsKey($normalizedKey)) {
                $normalizedIndex[$normalizedKey] = $fullPath
            }

            # 3. Prefix-based index for fuzzy matching
            $prefix = Get-ImageBasePrefix $img.Name
            if ($prefix.Length -ge 15) {
                if (-not $prefixIndex.ContainsKey($prefix)) {
                    $prefixIndex[$prefix] = [System.Collections.ArrayList]@()
                }
                [void]$prefixIndex[$prefix].Add($fullPath)
            }

            # 4. OneNote "Exported image" files - index by exact filename for timestamp lookup
            # These files are named like "Exported image 20240909143732-0.png"
            if ($img.Name -match '^Exported image \d{14}-\d+\.(png|jpg|jpeg|gif|webp)$') {
                $relativePath = $fullPath.Substring($vaultPath.Length + 1).Replace('\', '/')
                # Prefer paths in "20 - Permanent Notes" for OneNote exported images
                if (-not $exportedImageIndex.ContainsKey($img.Name) -or $relativePath -like "20 - Permanent Notes/*") {
                    $exportedImageIndex[$img.Name] = $relativePath
                }
            }
        }
    }
    Write-Log "  Indexed $($imageIndex.Count) image files (exact), $($normalizedIndex.Count) (normalized), $($prefixIndex.Count) (prefix), $($exportedImageIndex.Count) (OneNote exported)" "Gray"

    # Scan markdown files for broken image links
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count
    $processedFiles = 0
    $filesModifiedThisPhase = 0

    foreach ($mdFile in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            # Use -LiteralPath to handle files with special characters like [[ in the name
            $content = Get-Content -LiteralPath $mdFile.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            if (-not $content) { continue }
        } catch {
            continue
        }

        $originalContent = $content
        $fileModified = $false

        # Strategy 0: Fix OneNote exported image paths first
        # These have URL-encoded paths like 12%20-%20OneNote/.../Note.md/Exported%20image%20TIMESTAMP.ext
        if ($content -match '12%20-%20OneNote.*?\.md/Exported%20image') {
            $oneNoteFixCount = 0
            $content = Fix-OneNoteImagePaths -Content $content -ImageIndex $exportedImageIndex -FixCount ([ref]$oneNoteFixCount)
            if ($oneNoteFixCount -gt 0) {
                $fileModified = $true
                $script:brokenImageLinksFixed += $oneNoteFixCount
                $script:oneNoteImageLinksFixed += $oneNoteFixCount
            }
        }

        # Find all image embeds: ![[path/to/image.jpg]] or ![[image.jpg]]
        $imagePattern = '\!\[\[([^\]]+\.(jpg|jpeg|png|gif|webp|svg|ico))\]\]'
        $matches = [regex]::Matches($content, $imagePattern, 'IgnoreCase')

        foreach ($match in $matches) {
            $imagePath = $match.Groups[1].Value
            $imageFileName = Split-Path $imagePath -Leaf

            # Handle filenames with illegal characters (URLs mistakenly parsed as filenames)
            try {
                $imageExtension = [System.IO.Path]::GetExtension($imageFileName).ToLower()
            } catch {
                continue
            }

            # Build potential full paths to check existence
            # Path could be absolute from vault root or relative to note location
            $fullImagePath = Join-Path $vaultPath $imagePath
            $noteFolder = Split-Path $mdFile.FullName -Parent
            $relativeImagePath = Join-Path $noteFolder $imagePath

            # Check if image exists at either location
            $exists = $false
            try {
                $exists = (Test-Path -LiteralPath $fullImagePath) -or (Test-Path -LiteralPath $relativeImagePath)
            } catch {
                # Path has illegal characters, assume it doesn't exist
                $exists = $false
            }

            if (-not $exists) {
                $correctFullPath = $null

                # Strategy 1: Exact filename match (case-insensitive)
                $fileNameKey = $imageFileName.ToLower()
                if ($imageIndex.ContainsKey($fileNameKey)) {
                    $correctFullPath = $imageIndex[$fileNameKey]
                }

                # Strategy 2: Normalized filename match
                if (-not $correctFullPath) {
                    $normalizedKey = Normalize-ImageFileName $imageFileName
                    if ($normalizedIndex.ContainsKey($normalizedKey)) {
                        $correctFullPath = $normalizedIndex[$normalizedKey]
                    }
                }

                # Strategy 3: Prefix-based fuzzy match
                if (-not $correctFullPath) {
                    $searchPrefix = Get-ImageBasePrefix $imageFileName
                    $normalizedSearchPrefix = Normalize-ImageFileName $searchPrefix

                    # Look for matching prefix in the index
                    foreach ($indexPrefix in $prefixIndex.Keys) {
                        $normalizedIndexPrefix = Normalize-ImageFileName $indexPrefix

                        # Check if prefixes are similar (one contains the other or high overlap)
                        if ($normalizedIndexPrefix -like "*$normalizedSearchPrefix*" -or
                            $normalizedSearchPrefix -like "*$normalizedIndexPrefix*" -or
                            ($normalizedSearchPrefix.Length -ge 15 -and $normalizedIndexPrefix.StartsWith($normalizedSearchPrefix.Substring(0, 15)))) {

                            $candidates = $prefixIndex[$indexPrefix]
                            # Find candidate with matching extension
                            foreach ($candidate in $candidates) {
                                if ($candidate.ToLower().EndsWith($imageExtension)) {
                                    # Additional check: if filename contains _imgN pattern, try to match the number
                                    if ($imageFileName -match '_img(\d+)\.') {
                                        $wantedNum = $Matches[1]
                                        if ($candidate -match "_img${wantedNum}\.") {
                                            $correctFullPath = $candidate
                                            break
                                        }
                                        # Don't return a mismatched image number
                                    } else {
                                        $correctFullPath = $candidate
                                        break
                                    }
                                }
                            }
                            if ($correctFullPath) { break }
                        }
                    }
                }

                if ($correctFullPath) {
                    # Convert to relative path from vault root with FORWARD SLASHES
                    $correctRelPath = $correctFullPath.Substring($vaultPath.Length + 1).Replace('\', '/')

                    # Build replacement
                    $oldEmbed = $match.Value
                    $newEmbed = "![[$correctRelPath]]"

                    if ($oldEmbed -ne $newEmbed) {
                        $content = $content.Replace($oldEmbed, $newEmbed)
                        $fileModified = $true
                        $script:brokenImageLinksFixed++
                    }
                }
            }
        }

        # Write changes if any were made
        if ($fileModified -and $content -ne $originalContent) {
            if ($dryRun) {
                Write-Log "  [DRY RUN] Would fix image links in: $($mdFile.Name)" "Magenta"
            } else {
                try {
                    Set-Content -LiteralPath $mdFile.FullName -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
                    $filesModifiedThisPhase++
                } catch {
                    Write-Log "  ERROR: Failed to update $($mdFile.Name) - $_" "Red"
                }
            }
        }
    }

    Write-Log "  Fixed $($script:brokenImageLinksFixed) broken image links in $filesModifiedThisPhase files" "Green"
}

# =============================================================================
# PHASE 12: Generate Orphan Files list
# =============================================================================
# Finds all markdown files that have no incoming links from any other file
# in the vault. These "orphan" files are disconnected from the knowledge graph.
# Creates/updates "Orphan Files.md" with links to these files grouped by folder.
# =============================================================================
function Generate-OrphanFilesList {
    Write-Log "=== Phase 12: Generating Orphan Files list ===" "Cyan"

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

    # Build a map of all file base names for link resolution
    # Key = lowercase base name (trimmed), Value = file object
    $fileMap = @{}
    foreach ($file in $mdFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        # Trim the key to handle files with trailing spaces in names
        $fileMap[$baseName.ToLower().Trim()] = $file
    }

    Write-Log "  Scanning $($mdFiles.Count) files for links..." "Gray"

    # Track which files have incoming links
    # Key = lowercase base name of linked file
    $linkedFiles = @{}

    # Scan all files for outgoing wiki-style links
    foreach ($file in $mdFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not $content) { continue }
        } catch {
            continue
        }

        # Find all wiki-style links: [[link]] or [[link|alias]] or [[path/link]]
        $linkMatches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

        foreach ($match in $linkMatches) {
            $linkTarget = $match.Groups[1].Value.Trim()

            # Skip image embeds (handled separately)
            if ($linkTarget -match '\.(jpg|jpeg|png|gif|webp|svg|ico|pdf)$') { continue }

            # Remove heading anchors (e.g., [[Note#Section]] -> Note)
            if ($linkTarget -match '^([^#]+)#') {
                $linkTarget = $Matches[1]
            }

            # Handle path-style links (e.g., [[folder/note]] -> note)
            if ($linkTarget -match '[/\\]') {
                $linkTarget = Split-Path $linkTarget -Leaf
            }

            $linkTargetLower = $linkTarget.ToLower()

            # Mark this target as having an incoming link
            if ($fileMap.ContainsKey($linkTargetLower)) {
                $linkedFiles[$linkTargetLower] = $true
            }
        }
    }

    # Find orphans: files with no incoming links
    $orphans = @()
    foreach ($file in $mdFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

        # Skip system/generated files
        if ($file.Name -eq "Orphan Files.md") { continue }
        if ($file.Name -eq "Empty Notes.md") { continue }
        if ($file.Name -eq "Truncated Filenames.md") { continue }

        if (-not $linkedFiles.ContainsKey($baseName.ToLower().Trim())) {
            # Handle files in vault root (DirectoryName may be null or equal to vaultPath)
            $folderName = if ($file.DirectoryName -and $file.DirectoryName -ne $vaultPath) {
                Split-Path $file.DirectoryName -Leaf
            } else {
                "(Root)"
            }
            $orphans += @{
                Name = $baseName
                RelPath = $file.FullName.Replace($vaultPath + '\', '').Replace('\', '/')
                Folder = $folderName
            }
        }
    }

    # Sort by folder then name
    $orphans = $orphans | Sort-Object { $_.Folder }, { $_.Name }

    $script:orphanFilesFound = $orphans.Count

    # Group by folder for organized output
    $orphansByFolder = $orphans | Group-Object { $_.Folder } | Sort-Object { $_.Count } -Descending

    # Create markdown content
    $mdContent = "# Orphan Files`n`n"
    $mdContent += "Notes with no incoming links from other files in the vault.`n`n"
    $mdContent += "**Total: $($orphans.Count) orphan files**`n`n"
    $mdContent += "*Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*`n`n"

    foreach ($group in $orphansByFolder) {
        $mdContent += "## $($group.Name) ($($group.Count))`n`n"
        foreach ($orphan in $group.Group) {
            $mdContent += "- [[$($orphan.Name)]]`n"
        }
        $mdContent += "`n"
    }

    # Write to file
    $outputPath = Join-Path $vaultPath "Orphan Files.md"

    if ($dryRun) {
        Write-Log "  [DRY RUN] Would create Orphan Files.md with $($orphans.Count) entries" "Magenta"
    } else {
        try {
            Set-Content -Path $outputPath -Value $mdContent -Encoding UTF8 -NoNewline
            Write-Log "  Created Orphan Files.md with $($orphans.Count) entries in $($orphansByFolder.Count) folders" "Green"
        } catch {
            Write-Log "  ERROR: Failed to create Orphan Files.md - $_" "Red"
        }
    }

    Write-Log "  Files with incoming links: $($linkedFiles.Count)" "Gray"
}

# =============================================================================
# PHASE 13: Fix mojibake encoding issues
# =============================================================================
# Fixes common UTF-8 mojibake patterns that occur when UTF-8 text is incorrectly
# decoded as Windows-1252. These patterns appear in Evernote exports and other
# imported content.
#
# Common patterns fixed:
#   - Em dash mojibake: â€" -> — (U+2014)
#   - Ellipsis mojibake: â€¦ -> … (U+2026)
# =============================================================================
function Fix-MojibakeEncoding {
    Write-Log "=== Phase 13: Fixing mojibake encoding issues ===" "Cyan"

    # Define mojibake patterns and their correct replacements
    # These patterns occur when UTF-8 bytes are incorrectly decoded as Windows-1252

    # Em dash: UTF-8 bytes E2 80 94 decoded as Windows-1252 become â€"
    # We extract the pattern from a known file to ensure byte-accurate matching
    $emDashPattern = [char]0x00E2 + [char]0x20AC + [char]0x201C  # â€"
    $emDashReplacement = [char]0x2014  # — (em dash U+2014)

    # Ellipsis: UTF-8 bytes E2 80 A6 decoded as Windows-1252 become â€¦
    $ellipsisPattern = [char]0x00E2 + [char]0x20AC + [char]0x00A6  # â€¦
    $ellipsisReplacement = [char]0x2026  # … (ellipsis U+2026)

    $emDashFixed = 0
    $ellipsisFixed = 0
    $filesModifiedThisPhase = 0

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count
    $processedFiles = 0

    foreach ($mdFile in $mdFiles) {
        $processedFiles++
        if ($processedFiles % 500 -eq 0) {
            Write-Log "  Processing $processedFiles / $totalFiles files..." "Gray"
        }

        try {
            # Read file content using .NET to preserve exact byte sequences
            $content = [System.IO.File]::ReadAllText($mdFile.FullName, [System.Text.Encoding]::UTF8)
            if ($null -eq $content) { continue }
        } catch {
            continue
        }

        $original = $content
        $fileModified = $false

        # Count and fix em dash mojibake
        $emDashMatches = ([regex]::Matches($content, [regex]::Escape($emDashPattern))).Count
        if ($emDashMatches -gt 0) {
            $content = $content.Replace($emDashPattern, $emDashReplacement)
            $emDashFixed += $emDashMatches
            $fileModified = $true
        }

        # Count and fix ellipsis mojibake
        $ellipsisMatches = ([regex]::Matches($content, [regex]::Escape($ellipsisPattern))).Count
        if ($ellipsisMatches -gt 0) {
            $content = $content.Replace($ellipsisPattern, $ellipsisReplacement)
            $ellipsisFixed += $ellipsisMatches
            $fileModified = $true
        }

        if ($fileModified -and $content -ne $original) {
            if ($dryRun) {
                Write-Log "  [DRY RUN] Would fix mojibake in: $($mdFile.Name) (em dash: $emDashMatches, ellipsis: $ellipsisMatches)" "Magenta"
            } else {
                try {
                    [System.IO.File]::WriteAllText($mdFile.FullName, $content, [System.Text.Encoding]::UTF8)
                    $filesModifiedThisPhase++
                } catch {
                    Write-Log "  ERROR: Failed to update $($mdFile.Name) - $_" "Red"
                }
            }
        }
    }

    $script:mojibakeFixed = $emDashFixed + $ellipsisFixed
    Write-Log "  Fixed $emDashFixed em dash and $ellipsisFixed ellipsis mojibake patterns in $filesModifiedThisPhase files" "Green"
}

# =============================================================================
# PHASE 14: Comprehensive mojibake repair for corrupted files
# =============================================================================
# Detects and repairs files with encoding corruption (mojibake).
# This goes beyond Phase 13 to handle files with garbage characters like
# Ã, Â, ƒ, †, and the replacement character (�).
#
# The process:
#   1. Scans files for garbage character concentration (threshold: 0.01%)
#   2. Detects characteristic "A?" mojibake patterns
#   3. Removes garbage character sequences
#   4. Cleans up leftover punctuation patterns
#   5. Normalizes smart quotes and removes replacement characters (U+FFFD)
#   6. Tracks fixed files in a log to avoid re-processing
# =============================================================================

# Garbage character definitions - Unicode code points commonly found in mojibake
$script:GarbageCharCodes = @(
    # UTF-8 lead bytes misread as Latin-1
    195,   # Ã - Latin capital A with tilde (UTF-8 lead byte misread)
    194,   # Â - Latin capital A with circumflex (UTF-8 lead byte misread)
    197,   # Å - Latin capital A with ring above (common in mojibake)
    196,   # Ä - Latin capital A with diaeresis

    # Common mojibake artifacts
    402,   # ƒ - Latin small f with hook (very common in mojibake)
    8224,  # † - Dagger (common in mojibake patterns)
    8225,  # ‡ - Double dagger

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

# Build a HashSet for fast garbage character lookup
$script:GarbageCharSet = [System.Collections.Generic.HashSet[int]]::new()
foreach ($code in $script:GarbageCharCodes) {
    [void]$script:GarbageCharSet.Add($code)
}

# Path to log file tracking which files have been fixed (to avoid re-processing)
$script:MojibakeFixedLogPath = "C:\Users\awt\PowerShell\logs\mojibake_fixed.log"

# Load set of already-fixed files from log
$script:MojibakeFixedFilesSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

function Initialize-MojibakeFixedLog {
    # Load the set of already-fixed files from the log
    if (Test-Path $script:MojibakeFixedLogPath) {
        $logEntries = Get-Content $script:MojibakeFixedLogPath -ErrorAction SilentlyContinue
        foreach ($entry in $logEntries) {
            if ($entry -and $entry.Trim() -ne "") {
                [void]$script:MojibakeFixedFilesSet.Add($entry.Trim())
            }
        }
    }
}

function Add-ToMojibakeFixedLog {
    param([string]$FilePath)  # Full path to the file that was fixed
    # Append the file path to the log
    Add-Content -Path $script:MojibakeFixedLogPath -Value $FilePath -Encoding UTF8
    # Also add to in-memory set
    [void]$script:MojibakeFixedFilesSet.Add($FilePath)
}

# Test a file for mojibake by checking garbage character percentage
function Test-FileForMojibake {
    param(
        [string]$FilePath,         # Path to the file to analyze
        [double]$Threshold = 0.01  # Percentage threshold (0.01% catches nearly all garbage)
    )

    # Read file content as UTF-8
    try {
        $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    }
    catch {
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
        if ($script:GarbageCharSet.Contains($code)) {
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

# Repair a file with mojibake by removing garbage characters and cleaning up
function Repair-MojibakeFile {
    param(
        [string]$FilePath,   # Path to the file to repair
        [switch]$DryRunMode  # If true, don't actually modify the file
    )

    # Read the file
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    catch {
        Write-Log "    ERROR: Could not read file: $($_.Exception.Message)" "Red"
        return $false
    }

    $originalSize = $content.Length

    # ---- PHASE 1: Remove BOM characters from start ----
    # BOM (Byte Order Mark) = U+FEFF (code 65279)
    while ($content.Length -gt 0 -and [int]$content[0] -eq 65279) {
        $content = $content.Substring(1)
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
        if ($script:GarbageCharSet.Contains($code)) {
            $i++
            continue
        }

        # Check for "A'" or "A" followed by garbage (common mojibake pattern)
        if ($char -eq 'A' -and ($i + 1) -lt $content.Length) {
            $nextChar = $content[$i + 1]
            $nextCode = [int]$nextChar

            # If A is followed by ' or a garbage char, check if it's a garbage sequence
            if ($nextChar -eq "'" -or $script:GarbageCharSet.Contains($nextCode)) {
                # Scan ahead to measure the garbage run
                $j = $i + 1
                $garbageRun = 0

                while ($j -lt $content.Length -and $j -lt $i + 100) {
                    $testChar = $content[$j]
                    $testCode = [int]$testChar

                    # Characters that are part of garbage sequences
                    if ($script:GarbageCharSet.Contains($testCode) -or
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

    # ---- PHASE 3: Clean up leftover punctuation patterns ----
    # After removing garbage, we often have leftover patterns like '' '' '''
    $content = [regex]::Replace($content, "['\.\,_\s]{4,}", " ")

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

    # Check if any changes were actually made
    $originalContent = [System.Text.Encoding]::UTF8.GetString($bytes)
    $hasChanges = ($content -ne $originalContent)

    if (-not $hasChanges) {
        return $false
    }

    # Save the file
    if (-not $DryRunMode) {
        [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::UTF8)
        # Add to the fixed log so it won't be processed again
        Add-ToMojibakeFixedLog -FilePath $FilePath
    }

    return $true
}

function Fix-ComprehensiveMojibake {
    Write-Log "=== Phase 14: Comprehensive mojibake repair ===" "Cyan"

    # Initialize the log of previously fixed files
    Initialize-MojibakeFixedLog
    $skippedFromLog = 0

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    $totalFiles = $mdFiles.Count

    Write-Log "  Scanning $totalFiles files for severe mojibake..." "Gray"

    # Find affected files
    $affectedFiles = @()
    $scanned = 0

    foreach ($file in $mdFiles) {
        $scanned++

        # Progress indicator (every 500 files)
        if ($scanned % 500 -eq 0) {
            Write-Progress -Activity "Scanning for mojibake" -Status "$scanned / $totalFiles" -PercentComplete (($scanned / $totalFiles) * 100)
        }

        # Skip files that have already been fixed (tracked in log)
        if ($script:MojibakeFixedFilesSet.Contains($file.FullName)) {
            $skippedFromLog++
            continue
        }

        $result = Test-FileForMojibake -FilePath $file.FullName -Threshold 0.01

        if ($result.IsAffected) {
            $affectedFiles += $result
        }
    }

    Write-Progress -Activity "Scanning for mojibake" -Completed

    if ($skippedFromLog -gt 0) {
        Write-Log "  Skipped $skippedFromLog previously fixed files" "Gray"
    }

    if ($affectedFiles.Count -eq 0) {
        Write-Log "  No files with severe mojibake detected" "Green"
        return
    }

    Write-Log "  Found $($affectedFiles.Count) files with severe mojibake" "Yellow"

    # Fix all affected files
    $fixed = 0
    $failed = 0

    foreach ($file in $affectedFiles) {
        $relativePath = $file.Path.Replace($vaultPath + '\', '')

        if ($dryRun) {
            Write-Log "  [DRY RUN] Would fix: $relativePath (garbage: $($file.GarbagePercent)%)" "Magenta"
            $fixed++
        } else {
            $result = Repair-MojibakeFile -FilePath $file.Path -DryRunMode:$dryRun
            if ($result) {
                $fixed++
            }
            else {
                $failed++
            }
        }
    }

    $script:comprehensiveMojibakeFixed = $fixed
    Write-Log "  Fixed $fixed files" "Green"
    if ($failed -gt 0) {
        Write-Log "  Failed/no changes: $failed files" "Yellow"
    }
}

# =============================================================================
# PHASE 15: Remove link aliases from MOC files
# =============================================================================
# Converts [[target|alias]] to [[target]] so displayed text reflects actual filename
# This ensures that if a file is renamed, the displayed link text updates with it
# =============================================================================
function Remove-MocLinkAliases {
    Write-Log "=== Phase 15: Removing link aliases from MOC files ===" "Cyan"

    # Get all MOC files in the vault
    $mocFiles = Get-ChildItem -Path $vaultPath -Recurse -Filter "*MOC*.md" -ErrorAction SilentlyContinue

    if ($mocFiles.Count -eq 0) {
        Write-Log "  No MOC files found" "Gray"
        return
    }

    Write-Log "  Found $($mocFiles.Count) MOC files to process" "Yellow"

    # Counter for changes in this phase
    $totalChanges = 0
    $filesModified = 0

    foreach ($file in $mocFiles) {
        # Read file content with UTF-8 encoding
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        # Regex pattern to match [[target|alias]] links
        # Captures the target part (before the pipe) and replaces the whole thing with just [[target]]
        $pattern = '\[\[([^\]|]+)\|[^\]]+\]\]'

        # Find all matches
        $matches = [regex]::Matches($content, $pattern)

        if ($matches.Count -gt 0) {
            $relativePath = $file.FullName.Replace($vaultPath + '\', '')

            if ($dryRun) {
                Write-Log "  [DRY RUN] Would remove $($matches.Count) aliases from: $relativePath" "Magenta"
            } else {
                # Replace all alias links with just the target
                $newContent = [regex]::Replace($content, $pattern, '[[$1]]')

                # Write the modified content back to the file
                Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
                Write-Log "  Removed $($matches.Count) aliases from: $relativePath" "Green"
            }

            $totalChanges += $matches.Count
            $filesModified++
        }
    }

    $script:linkAliasesRemoved = $totalChanges

    if ($totalChanges -eq 0) {
        Write-Log "  No link aliases found in MOC files" "Green"
    } else {
        Write-Log "  Processed $filesModified files, removed $totalChanges aliases" "Green"
    }
}


# =============================================================================
# PHASE 16: Simplify MOC link paths
# =============================================================================
# Converts [[path/filename]] to [[filename]] so links don't include folder paths
# Obsidian can resolve links by filename alone, so full paths are unnecessary
# Preserves heading/block references and aliases
# =============================================================================
function Simplify-MocLinkPaths {
    Write-Log "=== Phase 16: Simplifying MOC link paths ===" "Cyan"

    # Get all MOC files in the vault (files in Dashboard/Index/MOC directories or with MOC in name)
    $mocFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $_.DirectoryName -match '(Dashboard|Index|MOC)' -or $_.Name -match 'MOC'
    }

    if ($mocFiles.Count -eq 0) {
        Write-Log "  No MOC files found" "Gray"
        return
    }

    Write-Log "  Found $($mocFiles.Count) MOC files to process" "Yellow"

    # Counters for this phase
    $totalLinksSimplified = 0
    $filesModified = 0

    foreach ($file in $mocFiles) {
        # Read file content with UTF-8 encoding (preserving diacriticals)
        $fileContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        # Skip if file is empty
        if ([string]::IsNullOrWhiteSpace($fileContent)) {
            continue
        }

        # Store original content for comparison
        $originalContent = $fileContent
        $fileLinksSimplified = 0

        # Pattern to match [[path/filename]] or [[path/filename#heading]] or [[path/filename|alias]]
        # Captures: 1=full path with filename, 2=optional #heading, 3=optional |alias
        $linkPattern = '\[\[([^\]#|]+/[^\]#|]+)(#[^\]|]+)?(\|[^\]]+)?\]\]'

        # Find all matches and process them
        $linkMatches = [regex]::Matches($fileContent, $linkPattern)

        # Process matches in reverse order to preserve string positions
        $matchList = @($linkMatches)
        [array]::Reverse($matchList)

        foreach ($match in $matchList) {
            $fullMatch = $match.Value
            $pathPart = $match.Groups[1].Value           # e.g., "04 - Indexes/Religion/BahÃ¡'Ã­/RidvÃ¡n 2022 Message"
            $headingPart = $match.Groups[2].Value        # e.g., "#heading" or empty
            $aliasPart = $match.Groups[3].Value          # e.g., "|alias" or empty

            # Extract just the filename from the path (part after last /)
            $filename = $pathPart -replace '^.*/', ''

            # Build the simplified link
            $simplifiedLink = "[[$filename$headingPart$aliasPart]]"

            # Only replace if it's actually different (has a path to remove)
            if ($fullMatch -ne $simplifiedLink) {
                $fileContent = $fileContent.Substring(0, $match.Index) + $simplifiedLink + $fileContent.Substring($match.Index + $match.Length)
                $fileLinksSimplified++
            }
        }

        # If content changed, save the file
        if ($fileContent -ne $originalContent) {
            $totalLinksSimplified += $fileLinksSimplified
            $relativePath = $file.FullName.Replace($vaultPath + '\', '')

            if ($dryRun) {
                Write-Log "  [DRY RUN] Would simplify $fileLinksSimplified links in: $relativePath" "Magenta"
            } else {
                # Write back with UTF-8 encoding (no BOM)
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($file.FullName, $fileContent, $utf8NoBom)
                Write-Log "  Simplified $fileLinksSimplified links in: $relativePath" "Green"
            }

            $filesModified++
        }
    }

    $script:linkPathsSimplified = $totalLinksSimplified

    if ($totalLinksSimplified -eq 0) {
        Write-Log "  No link paths needed simplification" "Green"
    } else {
        Write-Log "  Processed $filesModified files, simplified $totalLinksSimplified links" "Green"
    }
}

# =============================================================================
# PHASE 17: Move #clippings tag to last position
# =============================================================================
# In files with multiple tags, moves #clippings to the end of the tag list
# Handles both inline hashtag format (#tag1 #tag2 #clippings) and YAML format
# =============================================================================
function Move-ClippingsTagToLast {
    Write-Log "=== Phase 17: Moving #clippings tag to last position ===" "Cyan"

    # Path to the Clippings folder
    $clippingsPath = Join-Path $vaultPath "10 - Clippings"

    # Check if folder exists
    if (-not (Test-Path $clippingsPath)) {
        Write-Log "  Clippings folder not found: $clippingsPath" "Yellow"
        return
    }

    # Counter for tracking changes
    $filesModified = 0
    $tagsMovedCount = 0

    # Get all markdown files in the Clippings folder (recursively)
    $mdFiles = Get-ChildItem -Path $clippingsPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

    if ($mdFiles.Count -eq 0) {
        Write-Log "  No markdown files found in Clippings folder" "Gray"
        return
    }

    Write-Log "  Checking $($mdFiles.Count) files in Clippings folder" "Yellow"

    foreach ($file in $mdFiles) {
        # Read file content with UTF-8 encoding
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        # Skip empty files
        if ([string]::IsNullOrWhiteSpace($content)) {
            continue
        }

        # Flag to track if we modified this file
        $modified = $false
        $originalContent = $content
        $relativePath = $file.FullName.Replace($vaultPath + '\', '')

        # Check for YAML frontmatter
        if ($content -match '^---\r?\n([\s\S]*?)\r?\n---') {
            $yamlBlock = $Matches[0]
            $yamlContent = $Matches[1]

            # Check for YAML array format: tags: [tag1, tag2, clippings]
            if ($yamlContent -match 'tags:\s*\[([^\]]+)\]') {
                $tagsMatch = $Matches[0]
                $tagsList = $Matches[1]

                # Parse the tags (handle both quoted and unquoted)
                $tags = $tagsList -split '\s*,\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") }

                # Check if clippings tag exists and there are multiple tags
                if ($tags.Count -gt 1 -and ($tags -contains 'clippings' -or $tags -contains '#clippings')) {
                    # Check if clippings is already last
                    $lastTag = $tags[-1]
                    if ($lastTag -ne 'clippings' -and $lastTag -ne '#clippings') {
                        # Remove clippings from its current position
                        $otherTags = $tags | Where-Object { $_ -ne 'clippings' -and $_ -ne '#clippings' }

                        # Rebuild tags array with clippings at the end
                        $newTagsList = ($otherTags + 'clippings') -join ', '
                        $newTagsLine = "tags: [$newTagsList]"

                        # Replace in YAML content
                        $newYamlContent = $yamlContent -replace 'tags:\s*\[[^\]]+\]', $newTagsLine
                        $newYamlBlock = "---`n$newYamlContent`n---"
                        $content = $content -replace [regex]::Escape($yamlBlock), $newYamlBlock
                        $modified = $true
                        $tagsMovedCount++

                        if ($dryRun) {
                            Write-Log "  [DRY RUN] Would move clippings tag in YAML array: $relativePath" "Magenta"
                        } else {
                            Write-Log "  Moved clippings tag in YAML array: $relativePath" "Green"
                        }
                    }
                }
            }
            # Check for YAML list format: tags:\n  - tag1\n  - tag2
            elseif ($yamlContent -match 'tags:\s*\r?\n((?:\s*-\s*[^\r\n]+\r?\n?)+)') {
                $tagsSection = $Matches[0]
                $tagLines = $Matches[1]

                # Parse tags from list format
                $tags = @()
                $tagLines -split '\r?\n' | ForEach-Object {
                    if ($_ -match '^\s*-\s*(.+)$') {
                        $tags += $Matches[1].Trim().Trim('"').Trim("'")
                    }
                }

                # Check if clippings tag exists and there are multiple tags
                if ($tags.Count -gt 1 -and ($tags -contains 'clippings' -or $tags -contains '#clippings')) {
                    # Check if clippings is already last
                    $lastTag = $tags[-1]
                    if ($lastTag -ne 'clippings' -and $lastTag -ne '#clippings') {
                        # Remove clippings from its current position
                        $otherTags = $tags | Where-Object { $_ -ne 'clippings' -and $_ -ne '#clippings' }

                        # Rebuild tags section with clippings at the end
                        $newTagLines = ($otherTags | ForEach-Object { "  - $_" }) -join "`n"
                        $newTagLines += "`n  - clippings"
                        $newTagsSection = "tags:`n$newTagLines"

                        # Replace in content
                        $content = $content -replace [regex]::Escape($tagsSection), $newTagsSection
                        $modified = $true
                        $tagsMovedCount++

                        if ($dryRun) {
                            Write-Log "  [DRY RUN] Would move clippings tag in YAML list: $relativePath" "Magenta"
                        } else {
                            Write-Log "  Moved clippings tag in YAML list: $relativePath" "Green"
                        }
                    }
                }
            }
        }

        # Check for inline hashtag format (outside YAML): #clippings #othertag
        # Look for lines with multiple hashtags where one is #clippings
        $lines = $content -split '\r?\n'
        $newLines = @()
        $inlineModified = $false

        foreach ($line in $lines) {
            # Match lines with multiple hashtags
            if ($line -match '(?:^|\s)(#\w+(?:\s+#\w+)+)') {
                $hashtagsMatch = $Matches[1]
                $hashtags = [regex]::Matches($hashtagsMatch, '#\w+') | ForEach-Object { $_.Value }

                if ($hashtags.Count -gt 1 -and $hashtags -contains '#clippings') {
                    # Check if #clippings is already last
                    if ($hashtags[-1] -ne '#clippings') {
                        $otherHashtags = $hashtags | Where-Object { $_ -ne '#clippings' }
                        $newHashtags = ($otherHashtags + '#clippings') -join ' '
                        $newLine = $line -replace [regex]::Escape($hashtagsMatch), $newHashtags
                        $newLines += $newLine
                        $inlineModified = $true
                        $tagsMovedCount++
                        continue
                    }
                }
            }
            $newLines += $line
        }

        if ($inlineModified) {
            $content = $newLines -join "`n"
            $modified = $true

            if ($dryRun) {
                Write-Log "  [DRY RUN] Would move clippings tag inline: $relativePath" "Magenta"
            } else {
                Write-Log "  Moved clippings tag inline: $relativePath" "Green"
            }
        }

        if ($modified -and -not $dryRun) {
            # Write back with UTF-8 encoding (no BOM)
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
            $filesModified++
        }
    }

    $script:clippingsTagsMoved = $tagsMovedCount

    if ($tagsMovedCount -eq 0) {
        Write-Log "  No #clippings tags needed repositioning" "Green"
    } else {
        Write-Log "  Moved $tagsMovedCount clippings tags in $filesModified files" "Green"
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Clear/create log file
"" | Set-Content -Path $logPath

Write-Log "============================================" "Cyan"
Write-Log "Obsidian Vault Maintenance Script" "Cyan"
Write-Log "Vault: $vaultPath" "Cyan"
Write-Log "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Cyan"
if ($dryRun) { Write-Log "MODE: DRY RUN (no changes will be made)" "Magenta" }
Write-Log "============================================" "Cyan"
Write-Log ""

# Check if Obsidian is running, launch if not
$obsidianProcess = Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue
if ($obsidianProcess) {
    Write-Log "Obsidian is already running, continuing..." "Green"
} else {
    Write-Log "Launching Obsidian..." "Yellow"
    Start-Process "obsidian:"
    Write-Log "Waiting 15 seconds for Obsidian to initialize..." "Yellow"
    Start-Sleep -Seconds 15
    Write-Log "Proceeding with maintenance..." "Green"
}
Write-Log ""

# Run maintenance phases
Rename-NonStandardApostrophes
Resolve-ApostropheDuplicates
Trim-FilenameWhitespace
Rename-UnknownFilenameImages
Build-FileIndex
Fix-BrokenLinks
Fix-LegacyEvernotePaths
Generate-EmptyNotesList
Generate-TruncatedFilenamesList
Delete-SmallResourceImages
Delete-EmptyFolders
Add-TaskTagsToCheckboxes
Fix-BrokenImageLinks
Generate-OrphanFilesList
Fix-MojibakeEncoding
Fix-ComprehensiveMojibake
Remove-MocLinkAliases
Simplify-MocLinkPaths
Move-ClippingsTagToLast

# Summary
Write-Log "" "White"
Write-Log "============================================" "Green"
Write-Log "MAINTENANCE COMPLETE" "Green"
Write-Log "  Files/folders renamed (apostrophes): $script:filesRenamed" "White"
Write-Log "  Apostrophe duplicates resolved: $script:duplicatesResolved" "White"
Write-Log "  Filenames trimmed (whitespace): $script:filenamesTrimmed" "White"
Write-Log "  Links fixed (trimmed files): $script:trimmedLinksFixed" "White"
Write-Log "  Images renamed (unknown_filename): $script:imagesRenamed" "White"
Write-Log "  Markdown files updated: $script:filesModified" "White"
Write-Log "  Links fixed: $script:linksFixed" "White"
Write-Log "  Empty notes found: $script:emptyNotesFound" "White"
Write-Log "  Truncated filenames found: $script:truncatedFilesFound" "White"
Write-Log "  Small images deleted: $script:smallImagesDeleted" "White"
Write-Log "  Empty folders deleted: $script:emptyFoldersDeleted" "White"
Write-Log "  Task tags added: $script:taskTagsAdded" "White"
Write-Log "  Broken image links fixed: $script:brokenImageLinksFixed (OneNote: $script:oneNoteImageLinksFixed)" "White"
Write-Log "  Orphan files found: $script:orphanFilesFound" "White"
Write-Log "  Mojibake patterns fixed: $script:mojibakeFixed" "White"
Write-Log "  Severe mojibake files fixed: $script:comprehensiveMojibakeFixed" "White"
Write-Log "  MOC link aliases removed: $script:linkAliasesRemoved" "White"
Write-Log "  MOC link paths simplified: $script:linkPathsSimplified" "White"
Write-Log "  Clippings tags repositioned: $script:clippingsTagsMoved" "White"
Write-Log "  Log saved to: $logPath" "White"
Write-Log "============================================" "Green"
