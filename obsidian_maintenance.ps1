# =============================================================================
# Obsidian Vault Maintenance Script
# =============================================================================
# Purpose: Comprehensive maintenance for an Obsidian vault:
#   1a. Normalizes smart/curly apostrophes to standard apostrophes in file names
#   1b. Resolves duplicate files (smart vs standard apostrophe versions)
#   2. Renames unknown_filename images to meaningful names based on parent folder
#   3. Updates all markdown links to match renamed files
#   4. Fixes broken links pointing to moved resources
#   5. Fixes legacy Evernote paths pointing to new image locations
#   6. Generates "Empty Notes.md" listing notes with only a title (no content)
#   7. Generates "Truncated Filenames.md" listing notes with cut-off names
#   8. Fixes UTF-8 encoding corruption (mojibake): smart quotes, accents, NBSP, BOM
#   9. Deletes small image files (<3KB) in .resources folders (icons, trackers)
#  10. Deletes empty folders left behind after cleanup
#  11. Adds #task tag to uncompleted checkboxes missing the tag
#  12. Fixes corrupted horizontal line characters (mojibake box-drawing chars)
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
$script:imagesRenamed = 0
$script:linksFixed = 0
$script:filesModified = 0
$script:emptyNotesFound = 0
$script:truncatedFilesFound = 0
$script:smallImagesDeleted = 0
$script:emptyFoldersDeleted = 0
$script:taskTagsAdded = 0
$script:corruptedLinesFixed = 0

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
# PHASE 8: Fix UTF-8 encoding corruption (mojibake)
# =============================================================================
# Repairs common UTF-8 encoding issues using byte-level operations:
#   - Smart quotes/apostrophes: curly quotes -> straight quotes
#   - Dashes: em/en dashes -> standard dashes
#   - Non-breaking spaces: NBSP -> regular space
#   - BOM: Removes UTF-8 BOM marker from start of files
#   - Double-encoded mojibake patterns
# Uses byte-level operations to avoid encoding issues during read/write.
# =============================================================================
$script:encodingIssuesFixed = 0

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
    Write-Log "=== Phase 8: Fixing UTF-8 encoding corruption ===" "Cyan"

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
# PHASE 9: Delete small image files in .resources folders (was PHASE 8)
# =============================================================================
# Removes tiny images (<3KB) that are typically tracker pixels, spacer GIFs,
# small icons, and other web clipping artifacts that serve no purpose.
# =============================================================================
function Delete-SmallResourceImages {
    Write-Log "=== Phase 9: Deleting small images in .resources folders ===" "Cyan"

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
    Write-Log "=== Phase 10: Deleting empty folders ===" "Cyan"

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
# PHASE 11: Add #task tag to uncompleted checkboxes
# =============================================================================
# Finds all uncompleted checkbox patterns (- [ ]) that are not followed by
# the #task tag and adds the tag. This ensures all tasks are properly tagged
# for Obsidian task queries and plugins.
# =============================================================================
function Add-TaskTagsToCheckboxes {
    Write-Log "=== Phase 11: Adding #task tags to checkboxes ===" "Cyan"

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
# PHASE 12: Fix corrupted horizontal line characters
# =============================================================================
# Repairs corrupted box-drawing horizontal line characters (mojibake).
# The pattern C3 A2 22 E2 82 AC (6 bytes) repeated is the corrupted form
# of the Unicode box-drawing character. Replaces with markdown horizontal rule.
# =============================================================================
function Fix-CorruptedHorizontalLines {
    Write-Log "=== Phase 12: Fixing corrupted horizontal lines ===" "Cyan"

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
Write-Log "Obsidian Vault Maintenance Script" "Cyan"
Write-Log "Vault: $vaultPath" "Cyan"
Write-Log "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Cyan"
if ($dryRun) { Write-Log "MODE: DRY RUN (no changes will be made)" "Magenta" }
Write-Log "============================================" "Cyan"
Write-Log ""

# Run maintenance phases
Rename-NonStandardApostrophes
Resolve-ApostropheDuplicates
Rename-UnknownFilenameImages
Build-FileIndex
Fix-BrokenLinks
Fix-LegacyEvernotePaths
Generate-EmptyNotesList
Generate-TruncatedFilenamesList
Fix-EncodingCorruption
Delete-SmallResourceImages
Delete-EmptyFolders
Add-TaskTagsToCheckboxes
Fix-CorruptedHorizontalLines

# Summary
Write-Log "" "White"
Write-Log "============================================" "Green"
Write-Log "MAINTENANCE COMPLETE" "Green"
Write-Log "  Files/folders renamed (apostrophes): $script:filesRenamed" "White"
Write-Log "  Apostrophe duplicates resolved: $script:duplicatesResolved" "White"
Write-Log "  Images renamed (unknown_filename): $script:imagesRenamed" "White"
Write-Log "  Markdown files updated: $script:filesModified" "White"
Write-Log "  Links fixed: $script:linksFixed" "White"
Write-Log "  Empty notes found: $script:emptyNotesFound" "White"
Write-Log "  Truncated filenames found: $script:truncatedFilesFound" "White"
Write-Log "  Encoding issues fixed: $script:encodingIssuesFixed" "White"
Write-Log "  Small images deleted: $script:smallImagesDeleted" "White"
Write-Log "  Empty folders deleted: $script:emptyFoldersDeleted" "White"
Write-Log "  Task tags added: $script:taskTagsAdded" "White"
Write-Log "  Corrupted lines fixed: $script:corruptedLinesFixed" "White"
Write-Log "  Log saved to: $logPath" "White"
Write-Log "============================================" "Green"
