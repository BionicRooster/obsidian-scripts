# Find and move the Kolams file using wildcard
$vault = 'D:\Obsidian\Main'
$homeDir = "$vault\01\Home"
$socialDir = "$vault\01\Social"

# List all files in Home dir
$files = Get-ChildItem $homeDir -Filter '*.md'
Write-Host "Files in Home dir:"
foreach ($f in $files) {
    Write-Host "  $($f.Name) [bytes: $($f.Name.Length)]"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($f.Name)
    Write-Host "    hex: $([BitConverter]::ToString($bytes))"
}

# Try to find Discover file
$file = $files | Where-Object { $_.Name -like 'Discover*' }
if ($file) {
    $destFile = Join-Path $socialDir $file.Name
    Move-Item -LiteralPath $file.FullName -Destination $destFile -Force
    Write-Host "`nMOVED: $($file.Name) -> $socialDir"
} else {
    Write-Host "`nNo Discover file found"
}
