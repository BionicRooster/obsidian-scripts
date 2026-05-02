# Look for transcript segments in the engagement panel from saved page
$content = Get-Content 'C:\Users\awt\yt_page.html' -Raw -Encoding UTF8

# Look for transcript cue groups / segments
$patterns = @(
    'transcriptSegmentRenderer',
    'cueGroup',
    '"text":{"runs"',
    'startOffsetMs',
    'snippetText'
)
foreach ($p in $patterns) {
    if ($content -match $p) { Write-Host "Found: $p" } else { Write-Host "Missing: $p" }
}

# Try to find any text with timestamp near the panel
$m = [regex]::Match($content, '"engagementPanelSectionListRenderer"(.{0,5000})', [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($m.Success) {
    Write-Host "`n=== Panel excerpt (first 1000 chars) ==="
    Write-Host $m.Value.Substring(0, [Math]::Min(1000, $m.Value.Length))
}
