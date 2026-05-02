$dir = "D:\Obsidian\Main\02 - Working Projects\2024 Columbia River Trip"
$f = Get-ChildItem $dir | Where-Object { $_.Name -like "Reed*" } | Select-Object -First 1
Write-Host "File: $($f.FullName)"
$c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
($c -split '\r?\n') | Select-Object -First 30
