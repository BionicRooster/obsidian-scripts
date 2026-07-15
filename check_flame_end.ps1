$f = Get-ChildItem 'C:\Users\awt\Sync\Obsidian\01\Bah*' -Recurse | Where-Object { $_.Name -like 'A Flame of Fire*' } | Select-Object -First 1
$lines = Get-Content $f.FullName -Encoding UTF8
Write-Host "Total lines: $($lines.Count)"
$lines | Select-Object -Last 15 | ForEach-Object { Write-Host $_ }
