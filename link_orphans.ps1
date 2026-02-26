# link_orphans.ps1 - Obsidian Orphan File Linker
# Reads orphan file list from C:\Users\awt\orphan_filtered.txt,
# classifies each file using shared keyword scoring, and adds
# bidirectional links between the file and its best-matching MOC.
#
# Usage:
#   powershell -File link_orphans.ps1 [-DryRun] [-MaxFiles <n>]

param(
    [switch]$DryRun  = $false,  # When set, reports changes without writing any files
    [int]$MaxFiles   = 0        # Limit files processed; 0 = no limit
)

# Load shared MOC definitions and scoring functions
. "$PSScriptRoot\moc_keywords.ps1"

# -- Configuration ------------------------------------------------------------

$vaultPath  = 'D:\Obsidian\Main'       # Root of the Obsidian vault
$orphanList = 'C:\Users\awt\orphan_filtered.txt'  # File produced by orphan detection

# Minimum score a MOC must achieve to be considered a valid match.
# Files with no MOC scoring above this threshold are skipped.
$minScore = 4

# A link classified into a MOC is only considered a correct placement when the
# best MOC score exceeds the runner-up by at least this margin.
# (Prevents ambiguous files from being placed in an arbitrary MOC.)
$marginRequired = 0   # 0 = best score wins; increase to require clearer separation


# -- Helper: add a wikilink to a specific section in a MOC file ---------------
# Inserts "- [[relativePath|fileName]]" after the section header.
# If the section doesn't exist in the file, appends the link at end of file.
function Add-LinkToMOCSection {
    param(
        [string]$MOCFullPath,    # Absolute path to the MOC .md file
        [string]$OrphanName,     # Display name (no extension) for the link
        [string]$OrphanRelPath,  # Vault-relative path for the link target
        [string]$Section         # "## Section Header" to insert after
    )

    if (-not (Test-Path $MOCFullPath)) { return $false }

    $content = Get-Content -Path $MOCFullPath -Raw -Encoding UTF8
    if (-not $content) { return $false }

    # Build the wikilink using vault-relative path as target, name as alias
    $link = "- [[$OrphanRelPath|$OrphanName]]"

    # Check if this file is already linked anywhere in the MOC
    if ($content -match [regex]::Escape("[[$OrphanName]]") -or
        $content -match [regex]::Escape("[[$OrphanRelPath|")) {
        return $false   # Already linked - skip
    }

    if (-not $DryRun) {
        if ($content -match "(?m)^$([regex]::Escape($Section))\s*$") {
            # Insert link on the line immediately after the section header
            $content = $content -replace "(?m)(^$([regex]::Escape($Section))\s*\r?\n)", "`$1$link`n"
        } else {
            # Section not found - append at end of file
            $content = $content.TrimEnd() + "`n`n$link`n"
        }
        Set-Content -Path $MOCFullPath -Value $content -Encoding UTF8 -NoNewline
    }

    return $true
}


# -- Helper: add a MOC nav link to the orphan file itself --------------------
# Adds "- [[MOC path|MOC name]]" to a "## Related Notes" section in the file.
function Add-NavLinkToFile {
    param(
        [string]$FilePath,    # Absolute path to the orphan file
        [string]$MOCTarget,   # Wikilink target for the MOC (e.g. "00 - Home Dashboard/MOC - Recipes")
        [string]$MOCName      # Display name for the link alias
    )

    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return $false }

    # Skip if MOC link already present
    if ($content -match [regex]::Escape("[[$MOCTarget")) { return $false }

    $navLink = "- [[$MOCTarget|$MOCName]]"

    if (-not $DryRun) {
        if ($content -match '## Related Notes') {
            $content = $content -replace '(## Related Notes[^\n]*\n)', "`$1$navLink`n"
        } else {
            $content = $content.TrimEnd() + "`n`n---`n## Related Notes`n$navLink`n"
        }
        Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
    }

    return $true
}


# -- Main Processing ----------------------------------------------------------

Write-Host "=== Obsidian Orphan File Linker ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN - no files will be modified" -ForegroundColor Yellow
}

if (-not (Test-Path $orphanList)) {
    Write-Host "Orphan list not found: $orphanList" -ForegroundColor Red
    exit 1
}

# Read orphan list - keep only .md files, skip MOC files themselves
$files = Get-Content $orphanList | Where-Object { $_ -like "*.md" -and $_ -notmatch '\\MOC - ' }
Write-Host "Orphan .md files to process: $($files.Count)" -ForegroundColor Gray

if ($MaxFiles -gt 0) {
    $files = $files | Select-Object -First $MaxFiles
    Write-Host "Capped at first $MaxFiles files" -ForegroundColor Yellow
}

# Tracking counters
$processed   = 0    # Files examined
$linked      = 0    # Files that got at least one link added
$mocsUpdated = 0    # MOC entries added
$skipped     = 0    # Files skipped (not found, no match, already linked)

$fileIndex = 0
foreach ($relPath in $files) {
    $fileIndex++
    $fullPath = Join-Path $vaultPath $relPath

    if (-not (Test-Path $fullPath)) {
        $skipped++
        continue
    }

    Write-Progress -Activity "Linking orphan files" `
                   -Status "$fileIndex / $($files.Count): $relPath" `
                   -PercentComplete (($fileIndex / $files.Count) * 100)

    # Read and score the file
    $meta = Get-FileMetadata -FilePath $fullPath
    if (-not $meta) { $skipped++; continue }

    $matches_list = Find-BestMOCMatch -FileMetadata $meta   # Sorted descending by Score
    $best         = $matches_list[0]  # Highest-scoring MOC

    # Skip if no MOC scores above minimum threshold
    if ($best.Score -lt $minScore) {
        Write-Host "  SKIP (no clear match): $($meta.FileName) - best=$($best.MOCTopic) score=$($best.Score)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    $processed++

    # Build paths for the MOC and the orphan's vault-relative link target
    $mocFullPath  = Join-Path $vaultPath "00 - Home Dashboard\$($best.MOCFile)"
    $orphanTarget = $relPath -replace '\\', '/' -replace '\.md$', ''   # vault-relative, forward slashes, no extension
    $mocTarget    = "00 - Home Dashboard/$($best.MOCFile -replace '\.md$', '')"   # for nav link in orphan

    Write-Host "  $($meta.FileName)" -ForegroundColor White -NoNewline
    Write-Host " -> $($best.MOCFile) [$($best.DefaultSection)] score=$($best.Score)" -ForegroundColor Cyan

    # 1. Add orphan link to the correct section in the MOC
    $mocAdded = Add-LinkToMOCSection `
        -MOCFullPath   $mocFullPath `
        -OrphanName    $meta.FileName `
        -OrphanRelPath $orphanTarget `
        -Section       $best.DefaultSection

    if ($mocAdded) { $mocsUpdated++ }

    # 2. Add nav link back to MOC in the orphan file
    $navAdded = Add-NavLinkToFile `
        -FilePath  $fullPath `
        -MOCTarget $mocTarget `
        -MOCName   ($best.MOCFile -replace '\.md$', '')

    if ($mocAdded -or $navAdded) { $linked++ }
}

Write-Progress -Activity "Linking orphan files" -Completed

Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "Files examined:      $($files.Count)" -ForegroundColor White
Write-Host "Matched & processed: $processed"       -ForegroundColor White
Write-Host "Linked (bidirectional): $linked"       -ForegroundColor Green
Write-Host "MOC entries added:   $mocsUpdated"     -ForegroundColor Green
Write-Host "Skipped:             $skipped"         -ForegroundColor DarkGray
if ($DryRun) {
    Write-Host "`n(Dry run - no files were changed)" -ForegroundColor Yellow
}
