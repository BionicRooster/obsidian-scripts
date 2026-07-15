# Find and move the brains file using wildcard (handles smart apostrophe)
$src = Get-ChildItem 'C:\Users\awt\Sync\Obsidian\10 - Clippings' |
       Where-Object { $_.Name -match 'Switch Off' } |
       Select-Object -First 1

if (-not $src) { Write-Host "NOT FOUND"; exit }

$destDir  = 'C:\Users\awt\Sync\Obsidian\01\Health'
$destPath = Join-Path $destDir $src.Name

Move-Item -Path $src.FullName -Destination $destPath
Write-Host "MOVED: $($src.Name)"
Write-Host "   to: $destPath"
