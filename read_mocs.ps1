# read_mocs.ps1 - Read MOC files needed for classification

$mocDir = 'D:\Obsidian\Main\00 - Home Dashboard'   # Folder with all MOC files

# Find Bahai MOC (name may have diacriticals)
$bahaiMoc = Get-ChildItem $mocDir | Where-Object { $_.Name -match 'Bah' -and $_.Name -match 'Faith' } | Select-Object -First 1
# Home MOC
$homeMoc = Join-Path $mocDir 'MOC - Home & Practical Life.md'
# Tech MOC
$techMoc = Join-Path $mocDir 'MOC - Technology & Computers.md'

Write-Host "=== BAHAI MOC: $($bahaiMoc.FullName) ===" -ForegroundColor Cyan
[System.IO.File]::ReadAllText($bahaiMoc.FullName, [System.Text.Encoding]::UTF8)

Write-Host "`n=== HOME MOC ===" -ForegroundColor Cyan
[System.IO.File]::ReadAllText($homeMoc, [System.Text.Encoding]::UTF8)

Write-Host "`n=== TECH MOC ===" -ForegroundColor Cyan
[System.IO.File]::ReadAllText($techMoc, [System.Text.Encoding]::UTF8)
