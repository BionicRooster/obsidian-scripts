# Read file with curly apostrophe in name
$file = Get-ChildItem 'D:\Obsidian\Main\10 - Clippings\' | Where-Object { $_.Name -match 'cataclysmic' } | Select-Object -First 1
if ($file) {
    Write-Host "File: $($file.FullName)"
    Get-Content -LiteralPath $file.FullName -Encoding UTF8 | Out-File -FilePath 'C:\Users\awt\temp_content.txt' -Encoding UTF8
    Write-Host "Content written to temp file"
} else {
    Write-Host "File not found"
}
