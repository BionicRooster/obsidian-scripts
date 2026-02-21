# Find and move the Kolams file
$vault = 'D:\Obsidian\Main'
$homeDir = "$vault\01\Home"
$socialDir = "$vault\01\Social"

$file = Get-ChildItem $homeDir -Filter 'Discover*' | Where-Object { $_.Name -match 'olams' }
if ($file) {
    $destFile = Join-Path $socialDir $file.Name
    Move-Item -Path $file.FullName -Destination $destFile -Force
    Write-Host "MOVED: $($file.Name) -> $socialDir"
} else {
    Write-Host "File not found in $homeDir"
}
