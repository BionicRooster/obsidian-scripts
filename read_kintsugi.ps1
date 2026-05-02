# Read the Kintsugi file content and display it
$file = Get-ChildItem 'D:\Obsidian\Main\01\NLP\' | Where-Object { $_.Name -match 'Kintsugi' }
Write-Host "File: $($file.FullName)"
Get-Content -Path $file.FullName -Encoding UTF8 -Raw
