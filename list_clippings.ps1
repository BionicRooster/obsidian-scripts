$clippings = "C:\Users\awt\Sync\Obsidian\10 - Clippings"
Get-ChildItem -LiteralPath $clippings | ForEach-Object { Write-Host $_.Name }
