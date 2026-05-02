# find_brains.ps1
Get-ChildItem 'D:\Obsidian\Main\01\Health' | Where-Object { \extglob.Name -match 'Brains' } | Select-Object FullName
