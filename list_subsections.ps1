# List all MOCs and subsections from link_largest_orphan.ps1

$scriptContent = Get-Content "C:\Users\awt\link_largest_orphan.ps1" -Raw
$lines = $scriptContent -split "`n"
$parsingKeywords = $false
$currentMOC = ""
$subsections = @()

foreach ($line in $lines) {
    if ($line -match '^\$subsectionKeywords\s*=\s*@\{') {
        $parsingKeywords = $true
        continue
    }
    if ($parsingKeywords -and $line -match '^#endregion Configuration') {
        break
    }
    if (-not $parsingKeywords) { continue }

    if ($line -match '^\s*"([^"]+)"\s*=\s*@\{\s*$') {
        $currentMOC = $Matches[1]
    }
    if ($line -match '^\s*"([^"]+)"\s*=\s*@\(\s*$') {
        $subsections += [PSCustomObject]@{
            MOC = $currentMOC
            Subsection = $Matches[1]
        }
    }
}

Write-Host "Total MOCs: $($subsections | Select-Object -Unique -Property MOC | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host "Total Subsections: $($subsections.Count)"
Write-Host ""

$grouped = $subsections | Group-Object MOC
foreach ($g in $grouped) {
    Write-Host "=== $($g.Name) ===" -ForegroundColor Cyan
    foreach ($s in $g.Group) {
        Write-Host "  - $($s.Subsection)"
    }
    Write-Host ""
}
