# Get the correct Bahai folder name
$bahaiFolder = (Get-ChildItem -Path "D:\Obsidian\Main\01" -Directory | Where-Object { $_.Name -match "^Bah" }).FullName
Write-Host "Bahai folder: $bahaiFolder"

# Delete the empty file in 01/Bahai
$emptyFile = Join-Path $bahaiFolder "Universal House of Justice.md"
if (Test-Path $emptyFile) {
    Remove-Item -Path $emptyFile -Force
    Write-Host "Deleted empty file: $emptyFile"
}

# Move the comprehensive file from 20 - Permanent Notes
$sourceFile = "D:\Obsidian\Main\20 - Permanent Notes\Universal House of Justice.md"
$destFile = Join-Path $bahaiFolder "Universal House of Justice.md"
if (Test-Path $sourceFile) {
    Move-Item -Path $sourceFile -Destination $destFile
    Write-Host "Moved: $sourceFile -> $destFile"
}

# Delete the duplicate obituary (the one in 01/Genealogy is better)
$dupObituary = "D:\Obsidian\Main\20 - Permanent Notes\Obituary - John Henry White.md"
if (Test-Path $dupObituary) {
    Remove-Item -Path $dupObituary -Force
    Write-Host "Deleted duplicate: $dupObituary"
}
