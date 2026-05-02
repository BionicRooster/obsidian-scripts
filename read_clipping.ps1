$path = (Get-ChildItem 'D:\Obsidian\Main\10 - Clippings' | Where-Object { $_.Name -match 'Switch Off' }).FullName
Get-Content $path -Encoding UTF8 | Select-Object -First 30
