# move_ancient_scrolls.ps1
# Moves the Ancient Scrolls clipping (has em dash in filename) to 01\Science\

$clippingsDir = 'C:\Users\awt\Sync\Obsidian\10 - Clippings'
$targetDir    = 'C:\Users\awt\Sync\Obsidian\01\Science'

# Find the file by partial name match (avoids em dash encoding issues in script source)
$file = Get-ChildItem -Path $clippingsDir | Where-Object { $_.Name -like '*Ancient scrolls*' }

if ($file) {
    $dst = Join-Path $targetDir $file.Name
    Move-Item -Path $file.FullName -Destination $dst -Force
    Write-Output "Moved: $($file.Name)"
} else {
    Write-Output "NOT FOUND: no file matching *Ancient scrolls* in $clippingsDir"
}
