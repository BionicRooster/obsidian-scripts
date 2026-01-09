<#
.SYNOPSIS
    Simplifies Obsidian wiki links by removing path prefixes, keeping just the filename.

.DESCRIPTION
    This script finds links in the format [[path/filename]] and converts them to [[filename]].
    Obsidian can resolve links by filename alone, so full paths are not needed.
    Preserves heading/block references (e.g., [[path/file#heading]] -> [[file#heading]]).

.PARAMETER Path
    The path to search for MOC files. Defaults to the Obsidian vault.

.PARAMETER WhatIf
    Shows what changes would be made without actually modifying files.

.PARAMETER Fix
    Actually applies the fixes to files.

.EXAMPLE
    .\simplify_moc_link_paths.ps1 -WhatIf
    Shows what changes would be made without modifying files.

.EXAMPLE
    .\simplify_moc_link_paths.ps1 -Fix
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
$totalLinksSimplified = 0

# Get all markdown files in MOC-related directories
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
    $fileLinksSimplified = 0

    # Pattern to match [[path/filename]] or [[path/filename#heading]] or [[path/filename|alias]]
    # We want to find links that contain a forward slash (indicating a path)
    # Capture groups:
    #   1: The full path including filename (before any # or |)
    #   2: Optional heading/block reference (#something)
    #   3: Optional alias (|something)
    $linkPattern = '\[\[([^\]#|]+/[^\]#|]+)(#[^\]|]+)?(\|[^\]]+)?\]\]'

    # Find all matches and process them
    $matches = [regex]::Matches($content, $linkPattern)

    # Process matches in reverse order to preserve string positions
    $matchList = @($matches)
    [array]::Reverse($matchList)

    foreach ($match in $matchList) {
        $fullMatch = $match.Value
        $pathPart = $match.Groups[1].Value           # e.g., "04 - Indexes/Religion/Bahá'í/Ridván 2022 Message"
        $headingPart = $match.Groups[2].Value        # e.g., "#heading" or empty
        $aliasPart = $match.Groups[3].Value          # e.g., "|alias" or empty

        # Extract just the filename from the path (part after last /)
        $filename = $pathPart -replace '^.*/', ''

        # Build the simplified link
        $simplifiedLink = "[[$filename$headingPart$aliasPart]]"

        # Only replace if it's actually different (has a path to remove)
        if ($fullMatch -ne $simplifiedLink) {
            $content = $content.Substring(0, $match.Index) + $simplifiedLink + $content.Substring($match.Index + $match.Length)
            $fileLinksSimplified++

            if ($WhatIf) {
                Write-Host "  $fullMatch" -ForegroundColor Yellow
                Write-Host "    -> $simplifiedLink" -ForegroundColor Green
            }
        }
    }

    # If content changed, report and optionally save
    if ($content -ne $originalContent) {
        $totalLinksSimplified += $fileLinksSimplified

        Write-Host "File: $($file.FullName)" -ForegroundColor White
        Write-Host "  Links simplified: $fileLinksSimplified" -ForegroundColor Cyan

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
$filesWithChangesMsg = if ($totalLinksSimplified -gt 0) {
    if ($Fix) { $totalFilesModified } else { "N/A (WhatIf mode)" }
} else { 0 }
Write-Host "  Files with changes: $filesWithChangesMsg" -ForegroundColor White
Write-Host "  Links simplified: $totalLinksSimplified" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

if (-not $Fix -and -not $WhatIf) {
    Write-Host ""
    Write-Host "Run with -WhatIf to preview changes, or -Fix to apply them." -ForegroundColor Yellow
}
