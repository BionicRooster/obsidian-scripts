Write-Host "=== Tech MOC last 12 lines ==="
Get-Content 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Technology & Computers.md' -Encoding UTF8 | Select-Object -Last 12 | ForEach-Object { Write-Host $_ }

Write-Host ""
Write-Host "=== Travel MOC last 12 lines ==="
Get-Content 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Travel & Exploration.md' -Encoding UTF8 | Select-Object -Last 12 | ForEach-Object { Write-Host $_ }
