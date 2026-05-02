Get-ChildItem 'D:\Obsidian\Main\10 - Clippings' | Where-Object { $_.Name -match 'Switch' } | Select-Object FullName
Get-ChildItem 'D:\Obsidian\Main\01\Health' | Where-Object { $_.Name -match 'Switch' } | Select-Object FullName
