# Check for remaining dated files
$source = "D:\Obsidian\Main\03 - Recipes"
$dest = "D:\Obsidian\Main\01\Recipes"

$datedFiles = Get-ChildItem -Path $source -Filter "*.md" | Where-Object {
    $_.Name -match "^\d{4}-\d{2}-\d{2}"
}

Write-Host "Remaining dated files in 03 - Recipes: $($datedFiles.Count)"
foreach ($f in $datedFiles | Select-Object -First 10) {
    Write-Host "  - $($f.Name)"
}

$destCount = (Get-ChildItem -Path $dest -Filter "*.md").Count
Write-Host "`nFiles in 01/Recipes: $destCount"

$sourceCount = (Get-ChildItem -Path $source -Filter "*.md").Count
Write-Host "Files in 03 - Recipes: $sourceCount"
