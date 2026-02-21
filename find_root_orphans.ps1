# Find markdown files directly in vault root that need classification
$vault = "D:\Obsidian\Main"

Write-Host "=== Files directly in vault root ===" -ForegroundColor Cyan
$rootFiles = Get-ChildItem -Path $vault -Filter "*.md" -File
foreach ($file in $rootFiles) {
    Write-Host $file.Name
}
Write-Host "`nTotal root files: $($rootFiles.Count)"

Write-Host "`n=== Recent files in 10 - Clippings (last 7 days) ===" -ForegroundColor Cyan
$cutoff = (Get-Date).AddDays(-7)
$clippingsFiles = Get-ChildItem -Path "$vault\10 - Clippings" -Filter "*.md" -File | Where-Object {
    $_.CreationTime -gt $cutoff
}
foreach ($file in $clippingsFiles | Sort-Object CreationTime -Descending) {
    Write-Host "$($file.CreationTime.ToString('yyyy-MM-dd')) | $($file.Name)"
}
Write-Host "`nTotal recent clippings: $($clippingsFiles.Count)"
