Get-ChildItem 'C:\Users\awt\Sync\Obsidian\10 - Clippings' | Where-Object { $_.Name -match 'Switch' } | Select-Object FullName
Get-ChildItem 'C:\Users\awt\Sync\Obsidian\01\Health' | Where-Object { $_.Name -match 'Switch' } | Select-Object FullName
