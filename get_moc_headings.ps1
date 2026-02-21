# Get all ## headings from MOC files
Get-ChildItem "D:\Obsidian\Main\00 - Home Dashboard" -Filter "MOC*" | ForEach-Object {
    Write-Host "=== $($_.Name) ===" -ForegroundColor Cyan
    Get-Content $_.FullName -Encoding UTF8 | Where-Object { $_ -match '^##\s+' } | ForEach-Object { Write-Host $_ }
    Write-Host ""
}
