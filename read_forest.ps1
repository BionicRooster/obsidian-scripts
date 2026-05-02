# Read the file with smart apostrophes in name
$clippings = "D:\Obsidian\Main\10 - Clippings"
$files = Get-ChildItem $clippings | Where-Object { $_.Name -like "*Forest*" -or $_.Name -like "*forest*" }
foreach ($f in $files) {
    Write-Host "=== $($f.FullName) ==="
    Get-Content $f.FullName -Encoding UTF8 | ForEach-Object { Write-Host $_ }
}
