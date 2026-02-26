# cleanup_misplaced_links.ps1 - Remove Misplaced Links from MOCs
# Uses the same keyword scoring as link_orphans.ps1 to determine correct placement,
# so classify and clean always agree on where a note belongs.
#
# A link is removed from a MOC when the shared scoring gives a different MOC
# a score at least $misplacedMargin points higher than the current MOC.
#
# Usage:
#   powershell -File cleanup_misplaced_links.ps1 [-DryRun] [-Limit <n>]

param(
    [switch]$DryRun  = $false,  # When set, reports removals without writing files
    [int]$Limit      = 0        # Cap links processed per MOC; 0 = no limit
)

# Load shared MOC definitions and scoring functions
. "$PSScriptRoot\moc_keywords.ps1"

# -- Configuration ------------------------------------------------------------

$vaultPath = 'D:\Obsidian\Main'
$mocFolder = '00 - Home Dashboard'

# Number of score points the best alternative MOC must exceed the current MOC
# before the link is flagged as misplaced and removed.
# Higher = more conservative (removes fewer links).
$misplacedMargin = 8


# -- Helper: collect all MOC files --------------------------------------------
function Get-MOCFiles {
    $files = Get-ChildItem -Path (Join-Path $vaultPath $mocFolder) `
                           -Filter "MOC - *.md" -ErrorAction SilentlyContinue
    return $files | ForEach-Object {
        $topic = [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -replace '^MOC - ', ''
        [PSCustomObject]@{
            FileName = $_.Name
            Topic    = $topic
            FullPath = $_.FullName
        }
    } | Sort-Object Topic
}


# -- Helper: remove a single wikilink line from a MOC file --------------------
function Remove-LinkFromMOC {
    param(
        [string]$MOCPath,      # Absolute path to MOC file
        [string]$LinkTarget    # The target text inside [[ ]]
    )

    $content = Get-Content -Path $MOCPath -Raw -Encoding UTF8
    $escaped = [regex]::Escape($LinkTarget)

    # Match the full bullet line containing this link (with or without alias)
    $pattern = "(?m)^- \[\[$escaped(?:\|[^\]]+)?\]\]\r?\n?"

    if ($content -notmatch $pattern) { return $false }

    $newContent = $content -replace $pattern, ''

    # Collapse any triple+ blank lines left behind
    $newContent = $newContent -replace "(`r?`n){3,}", "`n`n"

    if (-not $DryRun) {
        Set-Content -Path $MOCPath -Value $newContent -Encoding UTF8 -NoNewline
    }

    return $true
}


# -- Main Processing ----------------------------------------------------------

Write-Host "=== MOC Link Cleanup ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN - no files will be modified" -ForegroundColor Yellow
}

$mocs         = Get-MOCFiles
$totalRemoved = 0     # Links removed across all MOCs
$totalChecked = 0     # Links evaluated
$totalSkipped = 0     # Links skipped (file not found or unresolvable)

foreach ($moc in $mocs) {
    Write-Host "`nChecking: $($moc.Topic)" -ForegroundColor Cyan

    $links = Get-MOCLinks -MOCFilePath $moc.FullPath
    if ($links.Count -eq 0) { Write-Host "  (no links)" -ForegroundColor DarkGray; continue }

    # Apply per-MOC cap if requested
    $linksToCheck = if ($Limit -gt 0) { $links | Select-Object -First $Limit } else { $links }

    $removedInMOC = 0   # Links removed from this specific MOC

    foreach ($link in $linksToCheck) {
        $filePath = Resolve-WikiLink -LinkTarget $link.Target -VaultPath $vaultPath
        if (-not $filePath) { $totalSkipped++; continue }

        $meta = Get-FileMetadata -FilePath $filePath
        if (-not $meta) { $totalSkipped++; continue }

        $totalChecked++
        $allScores = Find-BestMOCMatch -FileMetadata $meta

        # Score of the MOC this link currently lives in
        $currentScore = ($allScores | Where-Object { $_.MOCTopic -eq $moc.Topic }).Score
        if ($null -eq $currentScore) { $currentScore = 0 }

        $best = $allScores[0]   # Highest-scoring MOC

        # Determine if this link is misplaced
        $isMisplaced = ($best.MOCTopic -ne $moc.Topic) -and
                       ($best.Score -ge ($currentScore + $misplacedMargin) -or
                        ($currentScore -eq 0 -and $best.Score -gt 0))

        if ($isMisplaced) {
            $removed = Remove-LinkFromMOC -MOCPath $moc.FullPath -LinkTarget $link.Target

            if ($removed) {
                $removedInMOC++
                $totalRemoved++
                Write-Host ("  REMOVED: $($meta.FileName)" +
                            "  (was in $($moc.Topic) score=$currentScore," +
                            " better: $($best.MOCTopic) score=$($best.Score))") `
                           -ForegroundColor Yellow
            }
        }
    }

    if ($removedInMOC -eq 0) {
        Write-Host "  No misplaced links found" -ForegroundColor DarkGray
    } else {
        Write-Host "  Removed $removedInMOC misplaced link(s)" -ForegroundColor Green
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "MOCs checked:          $($mocs.Count)"  -ForegroundColor White
Write-Host "Links evaluated:       $totalChecked"   -ForegroundColor White
Write-Host "Links skipped (missing file): $totalSkipped" -ForegroundColor DarkGray
Write-Host "Misplaced links removed: $totalRemoved" -ForegroundColor Green
if ($DryRun) {
    Write-Host "`n(Dry run - no files were changed)" -ForegroundColor Yellow
}
