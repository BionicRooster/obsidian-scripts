# preview_clippings.ps1 - Show first 20 lines of each file in 10 - Clippings
$folder = 'D:\Obsidian\Main\10 - Clippings'
$files = Get-ChildItem $folder -Filter '*.md' | Sort-Object Name
foreach ($f in $files) {
    Write-Host "=== $($f.Name) ===" -ForegroundColor Cyan
    $lines = Get-Content $f.FullName -TotalCount 20 -Encoding UTF8
    $lines | ForEach-Object { Write-Host $_ }
    Write-Host ""
}
