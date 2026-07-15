# find_brains.ps1
Get-ChildItem 'C:\Users\awt\Sync\Obsidian\01\Health' | Where-Object { \extglob.Name -match 'Brains' } | Select-Object FullName
