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
Write-Log "  Log saved to: $logPath" "White"
Write-Log "============================================" "Green"
