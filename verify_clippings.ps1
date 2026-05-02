# Verify updated clippings files - check nav property exists
$clippings = "D:\Obsidian\Main\10 - Clippings"
$files = Get-ChildItem -LiteralPath $clippings -Filter "*.md" | Where-Object { $_.Name -ne "10 - Clippings.md" }

$withNav = 0
$withoutNav = @()

foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    if ($content -match '(?m)^nav:') {
        $withNav++
    } else {
        $withoutNav += $file.Name
    }
}

Write-Host "Files WITH nav: $withNav"
Write-Host "Files WITHOUT nav: $($withoutNav.Count)"
foreach ($f in $withoutNav) {
    Write-Host "  MISSING: $f"
}
