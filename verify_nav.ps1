$names = @('Rex Steven Sikes','Shelle Rose Charvet','Jack Wallen','Colin Marshall')
foreach ($name in $names) {
    $f = Join-Path 'D:\Obsidian\Main\15 - People' ($name + '.md')
    Write-Host "=== $name ==="
    Get-Content $f -Encoding UTF8 | Select-Object -First 14 | ForEach-Object { Write-Host $_ }
    Write-Host ""
}
