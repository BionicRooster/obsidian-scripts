# =============================================================================
# Obsidian Vault Maintenance Script
# =============================================================================
# Purpose: Comprehensive maintenance for an Obsidian vault:
#   1. Normalizes smart/curly apostrophes to standard apostrophes in file names
#   2. Renames unknown_filename images to meaningful names based on parent folder
#   3. Updates all markdown links to match renamed files
#   4. Fixes broken links pointing to moved resources
#   5. Fixes legacy Evernote paths pointing to new image locations
#
# Safe to run repeatedly - only makes changes when needed
#
# Usage: powershell -ExecutionPolicy Bypass -File "C:\Users\awt\obsidian_maintenance.ps1"
# =============================================================================

# Configuration
$vaultPath = "D:\Obsidian\Main"                              # Path to Obsidian vault
$logPath = "C:\Users\awt\obsidian_maintenance_log.txt"       # Log file location
$dryRun = $false                                             # Set to $true to preview changes without applying
$maxPathLength = 240                                         # Windows max path safety limit

# Characters to normalize
$curlyApostrophe = [char]0x2019    # ' (right single quote)
$leftApostrophe = [char]0x2018     # ' (left single quote)
$backtick = [char]0x0060           # ` (backtick/grave accent)
$standardApostrophe = "'"          # ' (standard apostrophe)

# Initialize counters
$script:filesRenamed = 0
$script:imagesRenamed = 0
$script:linksFixed = 0
$script:filesModified = 0

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
# PHASE 1: Rename files/folders with non-standard apostrophes
# =============================================================================
function Rename-NonStandardApostrophes {
    Write-Log "=== Phase 1: Checking for files with non-standard apostrophes ===" "Cyan"

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
Rename-UnknownFilenameImages
Build-FileIndex
Fix-BrokenLinks
Fix-LegacyEvernotePaths

# Summary
Write-Log "" "White"
Write-Log "============================================" "Green"
Write-Log "MAINTENANCE COMPLETE" "Green"
Write-Log "  Files/folders renamed (apostrophes): $script:filesRenamed" "White"
Write-Log "  Images renamed (unknown_filename): $script:imagesRenamed" "White"
Write-Log "  Markdown files updated: $script:filesModified" "White"
Write-Log "  Links fixed: $script:linksFixed" "White"
Write-Log "  Log saved to: $logPath" "White"
Write-Log "============================================" "Green"
