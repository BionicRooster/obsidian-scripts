# analyze_moc_links.ps1 - MOC Link Analyzer
# Finds links in MOC files that score better against a different MOC than
# the one they currently appear in, and reports them as potentially misplaced.
#
# Usage:
#   powershell -File analyze_moc_links.ps1 [-Limit <n>] [-ReportPath <path>] [-ExportJson]

param(
    [int]$Limit        = 0,                                  # Cap misplaced links reported; 0 = all
    [string]$ReportPath = "C:\Users\awt\moc_analysis_report.txt",  # Text report output path
    [switch]$ExportJson                                      # Also save a .json export
)

# Load shared MOC definitions and scoring functions
. "$PSScriptRoot\moc_keywords.ps1"

# -- Configuration ------------------------------------------------------------

$vaultPath = 'D:\Obsidian\Main'
$mocFolder = '00 - Home Dashboard'

# A link is flagged as misplaced when the best-matching MOC scores at least
# this many points higher than the MOC the link currently lives in.
$misplacedMargin = 5


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


# -- Main Analysis -------------------------------------------------------------

if (Test-Path $ReportPath) { Remove-Item $ReportPath -Force }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        "SUCCESS" { "[SUCCESS]" }; "WARNING" { "[WARNING]" }
        "ERROR"   { "[ERROR]  " }; default   { "[INFO]   " }
    }
    $color = switch ($Level) {
        "SUCCESS" { "Green" }; "WARNING" { "Yellow" }
        "ERROR"   { "Red"   }; default   { "White"  }
    }
    Write-Host "[$ts] $prefix $Message" -ForegroundColor $color
    "[$ts] $prefix $Message" | Add-Content -Path $ReportPath -Encoding UTF8
}

Write-Log "MOC LINK ANALYZER" "INFO"
Write-Log "Vault: $vaultPath"
Write-Log "Report: $ReportPath"

$mocs          = Get-MOCFiles
$misplaced     = @()
$analyzedCount = 0
$skippedCount  = 0

Write-Log "MOC files found: $($mocs.Count)"

foreach ($moc in $mocs) {
    Write-Log "Analyzing: $($moc.Topic)"

    $links = Get-MOCLinks -MOCFilePath $moc.FullPath
    Write-Log "  Links: $($links.Count)"

    foreach ($link in $links) {
        $filePath = Resolve-WikiLink -LinkTarget $link.Target -VaultPath $vaultPath
        if (-not $filePath) { $skippedCount++; continue }

        $meta = Get-FileMetadata -FilePath $filePath
        if (-not $meta) { $skippedCount++; continue }

        $analyzedCount++
        $allScores = Find-BestMOCMatch -FileMetadata $meta

        # Score of the MOC this link currently lives in
        $currentScore = ($allScores | Where-Object { $_.MOCTopic -eq $moc.Topic }).Score
        if ($null -eq $currentScore) { $currentScore = 0 }

        $best = $allScores[0]   # Highest-scoring MOC

        # Flag as misplaced if best MOC is different and sufficiently better
        $isMisplaced = ($best.MOCTopic -ne $moc.Topic) -and
                       ($best.Score -ge ($currentScore + $misplacedMargin) -or
                        ($currentScore -eq 0 -and $best.Score -gt 0))

        if ($isMisplaced) {
            $misplaced += [PSCustomObject]@{
                FileName       = $meta.FileName
                FilePath       = $filePath
                CurrentMOC     = $moc.Topic
                CurrentSection = $link.Section
                CurrentScore   = $currentScore
                BestMOC        = $best.MOCTopic
                BestScore      = $best.Score
                BestReason     = $best.Reason
                LinkTarget     = $link.Target
                TopScores      = $allScores | Select-Object -First 3
            }
        }
    }
}

Write-Log ""
Write-Log "Files analyzed: $analyzedCount"
Write-Log "Files skipped (not found): $skippedCount" "WARNING"
Write-Log "Potentially misplaced links: $($misplaced.Count)" "WARNING"

if ($Limit -gt 0 -and $misplaced.Count -gt $Limit) {
    Write-Log "Limiting report to first $Limit entries"
    $misplaced = $misplaced | Select-Object -First $Limit
}

if ($misplaced.Count -gt 0) {
    Write-Log ""
    Write-Log "---- MISPLACED LINKS ----"
    $i = 1
    foreach ($ml in $misplaced) {
        Write-Log "[$i] $($ml.FileName)" "WARNING"
        Write-Log "    In:        MOC - $($ml.CurrentMOC) / $($ml.CurrentSection)  (score: $($ml.CurrentScore))"
        Write-Log "    Suggested: MOC - $($ml.BestMOC)  (score: $($ml.BestScore))" "SUCCESS"
        Write-Log "    Reason:    $($ml.BestReason)"
        $i++
    }
}

if ($ExportJson) {
    $jsonPath = $ReportPath -replace '\.txt$', '.json'
    $misplaced | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Log "JSON export: $jsonPath" "SUCCESS"
}

Write-Log "Analysis complete. Report: $ReportPath" "SUCCESS"

# Return summary for programmatic use
return @{
    AnalyzedCount  = $analyzedCount
    SkippedCount   = $skippedCount
    MisplacedCount = $misplaced.Count
    MisplacedLinks = $misplaced
    ReportPath     = $ReportPath
}
