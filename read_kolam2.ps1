# Read Kolam file - check if it exists and list files
$clippingsPath = "D:\Obsidian\Main\10 - Clippings"
Write-Host "All files matching Kolam or Discover:"
Get-ChildItem -LiteralPath $clippingsPath | Where-Object { $_.Name -like "*Kolam*" -or $_.Name -like "*Discover*" } | ForEach-Object {
    Write-Host "  Found: $($_.Name)"
    $content = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw
    Write-Host "  Length: $($content.Length) chars"
    Write-Host $content
}
Write-Host "Done"
