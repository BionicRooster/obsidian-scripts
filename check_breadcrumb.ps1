$content = Get-Content 'D:\Obsidian\Main\15 - People\Jack Wallen.md' -Encoding UTF8
Write-Host "=== Wallen lines 13-18 ==="
$content | Select-Object -First 18 | Select-Object -Last 6 | ForEach-Object { Write-Host $_ }

Write-Host ""
$content2 = Get-Content 'D:\Obsidian\Main\15 - People\Colin Marshall.md' -Encoding UTF8
Write-Host "=== Colin lines 13-18 ==="
$content2 | Select-Object -First 18 | Select-Object -Last 6 | ForEach-Object { Write-Host $_ }
