$f = Get-ChildItem 'D:\Obsidian\Main\10 - Clippings\Dunning*' | Select-Object -First 1
Write-Host "Name: $($f.Name)"
Write-Host "FullName: $($f.FullName)"
$c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
Write-Host "Length: $($c.Length)"
Write-Host $c
