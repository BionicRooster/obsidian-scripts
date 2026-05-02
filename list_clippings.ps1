$clippings = "D:\Obsidian\Main\10 - Clippings"
Get-ChildItem -LiteralPath $clippings | ForEach-Object { Write-Host $_.Name }
