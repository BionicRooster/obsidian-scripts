# Link all Bahá'í orphan files to the MOC
$linkerScript = "C:\Users\awt\moc_orphan_linker.ps1"
$mocPath = "00 - Home Dashboard\MOC - Baha'i Faith.md"

$orphansToLink = @(
    @{ Path = "20 - Permanent Notes\The Tablet of Ahmad .md"; Section = "Core Teachings" },
    @{ Path = "20 - Permanent Notes\Prayer for protectio.md"; Section = "Core Teachings" },
    @{ Path = "20 - Permanent Notes\Georgetown LSA Info.md"; Section = "Administrative Guidance" },
    @{ Path = "20 - Permanent Notes\LSA Guidance on serv.md"; Section = "Administrative Guidance" },
    @{ Path = "20 - Permanent Notes\LSA member with a co.md"; Section = "Administrative Guidance" },
    @{ Path = "20 - Permanent Notes\Georgetown Cultural .md"; Section = "Community `& Service" },
    @{ Path = "20 - Permanent Notes\Baha'i Coherence 19t.md"; Section = "Clippings `& Resources" }
)

$successCount = 0
$failCount = 0

Write-Host "=== Linking Bahai Orphan Files to MOC ===" -ForegroundColor Cyan
Write-Host ""

foreach ($orphan in $orphansToLink) {
    Write-Host "Linking: $($orphan.Path)" -ForegroundColor Yellow
    Write-Host "  -> Section: $($orphan.Section)" -ForegroundColor Gray

    try {
        & $linkerScript -Action link-orphan -OrphanPath $orphan.Path -MOCPath $mocPath -SubsectionName $orphan.Section
        $successCount++
    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
        $failCount++
    }
    Write-Host ""
}

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Successfully linked: $successCount" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "Failed: $failCount" -ForegroundColor Red
} else {
    Write-Host "Failed: $failCount" -ForegroundColor Green
}
