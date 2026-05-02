# Script to read files with special characters in their names
# Uses LiteralPath to avoid path interpretation issues

$clippingsPath = "D:\Obsidian\Main\10 - Clippings"

# Get files matching patterns using wildcard search
$files = Get-ChildItem -LiteralPath $clippingsPath | Where-Object {
    $_.Name -like "*Hero*" -or
    $_.Name -like "*ceiling fan*" -or
    $_.Name -like "*Kolam*" -or
    $_.Name -like "*Weed Killer*" -or
    $_.Name -like "*Prune Fruit*" -or
    $_.Name -like "*Ireland*" -or
    $_.Name -like "*Losing my religion*" -or
    $_.Name -like "*Microfiction*" -or
    $_.Name -like "*Dresden*" -or
    $_.Name -like "*Raised Garden*" -or
    $_.Name -like "*Expense Ratio*" -or
    $_.Name -like "*Mobile Passport*" -or
    $_.Name -like "*When I Die*"
}

foreach ($file in $files) {
    Write-Host "=== FILE: $($file.Name) ==="
    Get-Content -LiteralPath $file.FullName -Encoding UTF8
    Write-Host "=== END FILE ==="
    Write-Host ""
}
