# MOC Orphan Relevance Linker - Helper Script
# This script gathers data for the interactive Claude Code workflow
# It extracts MOC subsections and orphan files for AI-based relevance ranking

param(
    # Action to perform: 'list-mocs', 'get-subsections', 'get-orphans', 'link-orphan'
    [string]$Action = 'list-mocs',

    # MOC file name (without path) for get-subsections action
    [string]$MOCName = '',

    # For link-orphan action: orphan file path and MOC subsection
    [string]$OrphanPath = '',
    [string]$MOCPath = '',
    [string]$SubsectionName = ''
)

# Vault configuration
$vaultPath = 'D:\Obsidian\Main'
$mocFolder = '00 - Home Dashboard'

# Function to get all MOC files from the vault
function Get-MOCFiles {
    # Get all files starting with "MOC -" in the Home Dashboard folder
    $mocFiles = Get-ChildItem -Path (Join-Path $vaultPath $mocFolder) -Filter "MOC - *.md" -ErrorAction SilentlyContinue

    $mocs = @()
    foreach ($file in $mocFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        # Extract the MOC topic (remove "MOC - " prefix)
        $topic = $baseName -replace '^MOC - ', ''
        $mocs += @{
            FileName = $file.Name
            BaseName = $baseName
            Topic = $topic
            FullPath = $file.FullName
        }
    }
    return $mocs | Sort-Object { $_.Topic }
}

# Function to extract subsections from a MOC file
function Get-MOCSubsections {
    param([string]$MOCFilePath)

    if (-not (Test-Path $MOCFilePath)) {
        Write-Error "MOC file not found: $MOCFilePath"
        return @()
    }

    $content = Get-Content -Path $MOCFilePath -Raw -Encoding UTF8
    $lines = $content -split "`n"

    $subsections = @()
    $currentSection = $null
    $currentLinks = @()

    foreach ($line in $lines) {
        # Check for level 2 headers (## Section Name)
        if ($line -match '^##\s+(.+)$') {
            # Save previous section if it has content
            if ($currentSection -and $currentLinks.Count -gt 0) {
                $subsections += @{
                    Name = $currentSection
                    Links = $currentLinks
                    LinkCount = $currentLinks.Count
                }
            }
            # Start new section
            $currentSection = $matches[1].Trim()
            $currentLinks = @()
        }
        # Check for wiki links in current section
        elseif ($currentSection -and $line -match '\[\[([^\]|]+)(?:\|([^\]]+))?\]\]') {
            $linkTarget = $matches[1]
            $linkAlias = if ($matches[2]) { $matches[2] } else { Split-Path $linkTarget -Leaf }
            $currentLinks += @{
                Target = $linkTarget
                Alias = $linkAlias
            }
        }
    }

    # Don't forget last section
    if ($currentSection -and $currentLinks.Count -gt 0) {
        $subsections += @{
            Name = $currentSection
            Links = $currentLinks
            LinkCount = $currentLinks.Count
        }
    }

    return $subsections
}

# Function to get all orphan files (files with no incoming links)
function Get-OrphanFiles {
    Write-Host "Scanning vault for orphan files..." -ForegroundColor Gray

    # Get all markdown files
    $mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

    # Build a map of all file names for link resolution
    $fileMap = @{}
    foreach ($file in $mdFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $fileMap[$baseName.ToLower()] = $file.FullName
    }

    # Track which files are linked to (have incoming links)
    $linkedFiles = @{}

    # Scan all files for outgoing links
    foreach ($file in $mdFiles) {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        # Find all wiki-style links [[link]] or [[link|alias]]
        $linkMatches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

        foreach ($match in $linkMatches) {
            $linkTarget = $match.Groups[1].Value.Trim()
            # Remove any heading anchors
            if ($linkTarget -match '^([^#]+)#') {
                $linkTarget = $matches[1]
            }
            $linkTargetLower = $linkTarget.ToLower()

            # Mark this file as linked
            if ($fileMap.ContainsKey($linkTargetLower)) {
                $linkedFiles[$linkTargetLower] = $true
            }
        }
    }

    # Skip these folders - they have their own natural organization
    $skipFolders = @('00 - Journal', '05 - Templates', '00 - Images', 'attachments', '.trash', '.obsidian', '.smart-env')

    # Find orphans (files not linked by any other file)
    $orphans = @()
    foreach ($file in $mdFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $relativePath = $file.FullName.Replace($vaultPath + "\", "")

        # Skip if in excluded folders
        $skip = $false
        foreach ($folder in $skipFolders) {
            if ($relativePath -match "^$([regex]::Escape($folder))") {
                $skip = $true
                break
            }
        }
        if ($skip) { continue }

        # Check if it's an orphan
        if (-not $linkedFiles.ContainsKey($baseName.ToLower())) {
            $orphans += @{
                Name = $baseName
                RelativePath = $relativePath
                FullPath = $file.FullName
                Folder = Split-Path $relativePath -Parent
            }
        }
    }

    return $orphans
}

# Function to get orphan file content for relevance analysis
function Get-OrphanContent {
    param([string]$OrphanPath)

    $fullPath = Join-Path $vaultPath $OrphanPath
    if (-not (Test-Path $fullPath)) {
        return $null
    }

    $content = Get-Content -Path $fullPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    return $content
}

# Function to create bidirectional link between orphan and MOC subsection
function Add-BidirectionalLink {
    param(
        [string]$OrphanRelPath,
        [string]$MOCRelPath,
        [string]$SubsectionName
    )

    $orphanFullPath = Join-Path $vaultPath $OrphanRelPath
    $mocFullPath = Join-Path $vaultPath $MOCRelPath

    if (-not (Test-Path $orphanFullPath)) {
        Write-Error "Orphan file not found: $OrphanRelPath"
        return $false
    }
    if (-not (Test-Path $mocFullPath)) {
        Write-Error "MOC file not found: $MOCRelPath"
        return $false
    }

    $orphanName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $OrphanRelPath -Leaf))
    $mocName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $MOCRelPath -Leaf))

    # === Add link from orphan to MOC ===
    $orphanContent = Get-Content -Path $orphanFullPath -Raw -Encoding UTF8
    $mocLinkPath = $MOCRelPath.Replace('\', '/').Replace('.md', '')

    # Check if link already exists
    if ($orphanContent -notmatch [regex]::Escape("[[$mocLinkPath")) {
        # Find or create Related Notes section
        if ($orphanContent -match '## Related Notes') {
            $orphanContent = $orphanContent -replace '(## Related Notes[^\n]*\n)', "`$1- [[$mocLinkPath|$mocName]]`n"
        } else {
            $orphanContent = $orphanContent.TrimEnd() + "`n`n---`n## Related Notes`n- [[$mocLinkPath|$mocName]]`n"
        }
        Set-Content -Path $orphanFullPath -Value $orphanContent -Encoding UTF8 -NoNewline
        Write-Host "  Added link from orphan to MOC" -ForegroundColor Green
    } else {
        Write-Host "  Link from orphan to MOC already exists" -ForegroundColor Yellow
    }

    # === Add link from MOC to orphan under the subsection ===
    $mocContent = Get-Content -Path $mocFullPath -Raw -Encoding UTF8
    $orphanLinkPath = $OrphanRelPath.Replace('\', '/').Replace('.md', '')

    # Check if orphan already linked in MOC
    if ($mocContent -notmatch [regex]::Escape("[[$orphanLinkPath")) {
        # Find the subsection and add the link after it
        $subsectionPattern = "(?m)(^## $([regex]::Escape($SubsectionName))[^\n]*\n)"

        if ($mocContent -match $subsectionPattern) {
            $newLink = "- [[$orphanLinkPath|$orphanName]]`n"
            $mocContent = $mocContent -replace $subsectionPattern, "`$1$newLink"
            Set-Content -Path $mocFullPath -Value $mocContent -Encoding UTF8 -NoNewline
            Write-Host "  Added link from MOC subsection '$SubsectionName' to orphan" -ForegroundColor Green
        } else {
            Write-Host "  Warning: Could not find subsection '$SubsectionName' in MOC" -ForegroundColor Yellow
            # Fallback: add to end
            $mocContent = $mocContent.TrimEnd() + "`n- [[$orphanLinkPath|$orphanName]]`n"
            Set-Content -Path $mocFullPath -Value $mocContent -Encoding UTF8 -NoNewline
            Write-Host "  Added link at end of MOC instead" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Link from MOC to orphan already exists" -ForegroundColor Yellow
    }

    return $true
}

# === Main Action Handler ===
switch ($Action) {
    'list-mocs' {
        # List all available MOCs
        $mocs = Get-MOCFiles
        Write-Host "`n=== Available MOCs ===" -ForegroundColor Cyan
        $i = 1
        foreach ($moc in $mocs) {
            Write-Host "$i. $($moc.Topic)" -ForegroundColor White
            $i++
        }
        Write-Host "`nTotal: $($mocs.Count) MOCs" -ForegroundColor Gray

        # Output as JSON for programmatic use
        $mocsJson = $mocs | ConvertTo-Json -Depth 3
        $mocsJson | Set-Content "C:\Users\awt\moc_list.json" -Encoding UTF8
        Write-Host "MOC list saved to: C:\Users\awt\moc_list.json" -ForegroundColor Gray
    }

    'get-subsections' {
        if (-not $MOCName) {
            Write-Error "MOCName parameter required for get-subsections action"
            exit 1
        }

        # Find the MOC file
        $mocPath = Join-Path $vaultPath (Join-Path $mocFolder "$MOCName.md")
        if (-not (Test-Path $mocPath)) {
            # Try with "MOC - " prefix
            $mocPath = Join-Path $vaultPath (Join-Path $mocFolder "MOC - $MOCName.md")
        }

        if (-not (Test-Path $mocPath)) {
            Write-Error "MOC file not found: $MOCName"
            exit 1
        }

        $subsections = Get-MOCSubsections -MOCFilePath $mocPath

        Write-Host "`n=== Subsections in $MOCName ===" -ForegroundColor Cyan
        $i = 1
        foreach ($section in $subsections) {
            Write-Host "$i. $($section.Name) ($($section.LinkCount) links)" -ForegroundColor White
            $i++
        }

        # Output as JSON
        $subsectionsJson = @{
            MOCName = $MOCName
            MOCPath = $mocPath.Replace($vaultPath + "\", "")
            Subsections = $subsections
        } | ConvertTo-Json -Depth 4
        $subsectionsJson | Set-Content "C:\Users\awt\moc_subsections.json" -Encoding UTF8
        Write-Host "`nSubsections saved to: C:\Users\awt\moc_subsections.json" -ForegroundColor Gray
    }

    'get-orphans' {
        $orphans = Get-OrphanFiles

        Write-Host "`n=== Orphan Files ===" -ForegroundColor Cyan
        Write-Host "Total orphans: $($orphans.Count)" -ForegroundColor White

        # Group by folder for summary
        $byFolder = $orphans | Group-Object { $_.Folder } | Sort-Object Count -Descending
        Write-Host "`nBy folder:" -ForegroundColor Gray
        foreach ($group in $byFolder | Select-Object -First 10) {
            Write-Host "  $($group.Name): $($group.Count)" -ForegroundColor Gray
        }

        # Save full orphan list with metadata
        $orphansJson = $orphans | ConvertTo-Json -Depth 3
        $orphansJson | Set-Content "C:\Users\awt\orphan_list.json" -Encoding UTF8
        Write-Host "`nOrphan list saved to: C:\Users\awt\orphan_list.json" -ForegroundColor Gray
    }

    'link-orphan' {
        if (-not $OrphanPath -or -not $MOCPath -or -not $SubsectionName) {
            Write-Error "OrphanPath, MOCPath, and SubsectionName parameters required for link-orphan action"
            exit 1
        }

        Write-Host "Creating bidirectional link..." -ForegroundColor Cyan
        Write-Host "  Orphan: $OrphanPath" -ForegroundColor Gray
        Write-Host "  MOC: $MOCPath" -ForegroundColor Gray
        Write-Host "  Subsection: $SubsectionName" -ForegroundColor Gray

        $result = Add-BidirectionalLink -OrphanRelPath $OrphanPath -MOCRelPath $MOCPath -SubsectionName $SubsectionName

        if ($result) {
            Write-Host "`nBidirectional link created successfully!" -ForegroundColor Green
        } else {
            Write-Host "`nFailed to create link" -ForegroundColor Red
            exit 1
        }
    }

    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host "Available actions: list-mocs, get-subsections, get-orphans, link-orphan" -ForegroundColor Yellow
    }
}
