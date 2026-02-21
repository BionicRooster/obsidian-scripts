# Filter orphan list for Bahá'í-related files
$orphans = Get-Content 'C:\Users\awt\orphan_list.json' | ConvertFrom-Json
$bahaiKeywords = 'Baha|Abdu|Shoghi|LSA|Ridvan|Unity|Spiritual Assembly|Race Amity|Nine Year|Universal House|Prayer|Deepening|GCCMA|Georgetown|Effendi|Bahau|Ahmad|Carmel|Haifa|Prophet|Religion|Faith|Ayyam|Martyr'

$matched = @()
foreach ($orphan in $orphans) {
    if ($orphan.Name -match $bahaiKeywords) {
        $matched += $orphan
    }
}

Write-Host "=== Bahá'í-Related Orphan Files ===" -ForegroundColor Cyan
Write-Host "Found $($matched.Count) files" -ForegroundColor Yellow
Write-Host ""

$i = 1
foreach ($file in $matched) {
    Write-Host "$i. $($file.Name)"
    Write-Host "   Path: $($file.RelativePath)" -ForegroundColor Gray
    $i++
}

# Save to JSON for further processing
$matched | ConvertTo-Json -Depth 3 | Set-Content 'C:\Users\awt\bahai_orphans.json' -Encoding UTF8
