Get-ChildItem 'D:\Obsidian\Main\01' -Directory | Sort-Object Name | ForEach-Object { Write-Host $_.Name }
