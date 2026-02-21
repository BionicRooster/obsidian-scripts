# Read content of both Abdu'l files
$folder = "D:\Obsidian\Main\20 - Permanent Notes"
$files = Get-ChildItem -Path $folder -Filter "*Abdu*"

foreach ($file in $files) {
    $name = $file.Name
    $apostropheChar = $name[18]
    $code = [int]$apostropheChar

    if ($code -eq 0x0027) {
        Write-Host "=== FILE WITH STANDARD APOSTROPHE (U+0027) ===" -ForegroundColor Yellow
    } else {
        Write-Host "=== FILE WITH SMART APOSTROPHE (U+2019) ===" -ForegroundColor Cyan
    }

    Write-Host "Size: $($file.Length) bytes"
    Write-Host "Path: $($file.FullName)"
    Write-Host ""
    Write-Host "Content preview (first 50 lines):"
    Write-Host "---"
    Get-Content -Path $file.FullName -TotalCount 50
    Write-Host "---"
    Write-Host ""
}
