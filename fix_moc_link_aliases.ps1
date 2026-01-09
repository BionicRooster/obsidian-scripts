<#
.SYNOPSIS
    Removes redundant display aliases from Obsidian wiki links in MOC files.

.DESCRIPTION
    This script finds links in the format [[path/filename|filename]] where the alias
    matches the filename, and converts them to [[path/filename]].
    It also fixes any ]]] endings to ]].

.PARAMETER Path
    The path to search for MOC files. Defaults to the Obsidian vault.

.PARAMETER WhatIf
    Shows what changes would be made without actually modifying files.

.PARAMETER Fix
    Actually applies the fixes to files.

.EXAMPLE
    .\fix_moc_link_aliases.ps1 -WhatIf
    Shows what changes would be made without modifying files.

.EXAMPLE
    .\fix_moc_link_aliases.ps1 -Fix
    Applies the fixes to all MOC files.
#>

param(
    # Path to the Obsidian vault
    [string]$Path = "D:\Obsidian\Main",

    # Preview mode - show what would be changed without modifying files
    [switch]$WhatIf,

    # Apply fixes to files
    [switch]$Fix
)

# Counter variables for tracking changes
$totalFilesScanned = 0
$totalFilesModified = 0
$totalLinksFixed = 0
$totalTripleBracketFixed = 0

# Get all markdown files in the vault (focusing on MOC-related directories)
# MOCs are typically in folders like "00 - Home Dashboard", or have "MOC" in the name
$mocFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse -File | Where-Object {
    # Include files in dashboard/index folders or files with MOC in the name
    $_.DirectoryName -match '(Dashboard|Index|MOC)' -or $_.Name -match 'MOC'
}

Write-Host "Found $($mocFiles.Count) MOC files to process" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $mocFiles) {
    $totalFilesScanned++

    # Read file content with UTF-8 encoding (preserving diacriticals)
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    # Skip if file is empty
    if ([string]::IsNullOrWhiteSpace($content)) {
        continue
    }

    # Store original content for comparison
    $originalContent = $content
    $fileLinksFixed = 0
    $fileTripleBracketFixed = 0

    # Pattern to match [[path/filename|alias]] where we need to check if alias matches filename
    # This regex captures: [[anything/filename|alias]]
    $linkPattern = '\[\[([^\]|]+)\|([^\]]+)\]\]'

    # Find all matches
    $matches = [regex]::Matches($content, $linkPattern)

    foreach ($match in $matches) {
        $fullMatch = $match.Value
        $pathPart = $match.Groups[1].Value      # e.g., "20 - Permanent Notes/Felipe Sanchez Lands"
        $aliasPart = $match.Groups[2].Value     # e.g., "Felipe Sanchez Lands"

        # Extract just the filename from the path (part after last / or \)
        $filename = $pathPart
        if ($pathPart -match '[/\\]') {
            $filename = $pathPart -replace '^.*[/\\]', ''
        }

        # Check if alias matches the filename
        if ($aliasPart -eq $filename) {
            # Replace [[path/filename|filename]] with [[path/filename]]
            $replacement = "[[$pathPart]]"
            $content = $content.Replace($fullMatch, $replacement)
            $fileLinksFixed++

            if ($WhatIf) {
                Write-Host "  Would fix: $fullMatch" -ForegroundColor Yellow
                Write-Host "        To: $replacement" -ForegroundColor Green
            }
        }
    }

    # Fix any ]]] to ]]
    $tripleBracketPattern = '\]\]\]'
    $tripleBracketMatches = [regex]::Matches($content, $tripleBracketPattern)

    if ($tripleBracketMatches.Count -gt 0) {
        $content = $content -replace $tripleBracketPattern, ']]'
        $fileTripleBracketFixed = $tripleBracketMatches.Count

        if ($WhatIf) {
            Write-Host "  Would fix $fileTripleBracketFixed triple bracket(s) ]]] -> ]]" -ForegroundColor Yellow
        }
    }

    # If content changed, report and optionally save
    if ($content -ne $originalContent) {
        $totalLinksFixed += $fileLinksFixed
        $totalTripleBracketFixed += $fileTripleBracketFixed

        Write-Host "File: $($file.FullName)" -ForegroundColor White
        Write-Host "  Links to fix: $fileLinksFixed, Triple brackets: $fileTripleBracketFixed" -ForegroundColor Cyan

        if ($Fix) {
            # Write back with UTF-8 encoding (no BOM)
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
            Write-Host "  FIXED" -ForegroundColor Green
            $totalFilesModified++
        }

        Write-Host ""
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Files scanned: $totalFilesScanned" -ForegroundColor White
# Calculate files with changes message
$filesWithChangesMsg = if ($totalLinksFixed + $totalTripleBracketFixed -gt 0) {
    if ($Fix) { $totalFilesModified } else { "N/A (WhatIf mode)" }
} else { 0 }
Write-Host "  Files with changes: $filesWithChangesMsg" -ForegroundColor White
Write-Host "  Redundant aliases found: $totalLinksFixed" -ForegroundColor White
Write-Host "  Triple brackets found: $totalTripleBracketFixed" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

if (-not $Fix -and -not $WhatIf) {
    Write-Host ""
    Write-Host "Run with -WhatIf to preview changes, or -Fix to apply them." -ForegroundColor Yellow
}
