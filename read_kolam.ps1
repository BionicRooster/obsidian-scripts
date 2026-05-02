# Read the Kolam file using wildcard search then LiteralPath
$clippingsPath = "D:\Obsidian\Main\10 - Clippings"
$files = Get-ChildItem -LiteralPath $clippingsPath | Where-Object { $_.Name -like "*Kolam*" }
foreach ($file in $files) {
    Write-Host "FILE: $($file.Name)"
    Get-Content -LiteralPath $file.FullName -Encoding UTF8
}
