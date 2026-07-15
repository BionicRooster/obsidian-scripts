Set-Location 'C:\Users\awt\Sync\Obsidian'
# Search all commits for Science & Nature
git log --all --oneline -- "00 - Home Dashboard/MOC - Science & Nature.md"
Write-Host "---"
# Check if there's a .trash or backup folder
$trash = Get-ChildItem '.' -Filter '.trash' -Hidden -Directory -ErrorAction SilentlyContinue
Write-Host "Trash folder: $($trash -ne $null)"
Get-ChildItem '.obsidian' -ErrorAction SilentlyContinue | Select-Object Name
