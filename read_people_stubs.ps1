# Read all stub and partial people files
$files = @('Malinda Lloyd','Jonathan Rice','Job Backer','Carolyn Maiers','Rex Steven Sikes','Jack Wallen','Colin Marshall','Shelle Rose Charvet')
foreach ($name in $files) {
    $f = Get-ChildItem 'D:\Obsidian\Main\15 - People' | Where-Object { $_.BaseName -eq $name } | Select-Object -First 1
    if ($f) {
        Write-Host "=== $($f.Name) ==="
        Get-Content $f.FullName -Encoding UTF8 | Out-String
        Write-Host ""
    }
}
