# Find recent files in 04 - GMail folder (last 7 days)
$folder = "D:\Obsidian\Main\04 - GMail"
$cutoff = (Get-Date).AddDays(-7)

Write-Host "=== Recent files in 04 - GMail (last 7 days) ===" -ForegroundColor Cyan
$files = Get-ChildItem -Path $folder -Filter "*.md" -File | Where-Object {
    $_.CreationTime -gt $cutoff
} | Sort-Object CreationTime -Descending

foreach ($file in $files) {
    Write-Host "$($file.CreationTime.ToString('yyyy-MM-dd HH:mm')) | $($file.Name)"
}

Write-Host "`nTotal: $($files.Count) files"
