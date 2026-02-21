# Check for duplicate Abdu'l files
$folder = "D:\Obsidian\Main\20 - Permanent Notes"
$files = Get-ChildItem -Path $folder -Filter "*Abdu*"

Write-Host "Found $($files.Count) file(s) matching 'Abdu':"
Write-Host ""

foreach ($file in $files) {
    $name = $file.Name
    Write-Host "File: $name"
    Write-Host "Full Path: $($file.FullName)"
    Write-Host "Size: $($file.Length) bytes"
    Write-Host "Modified: $($file.LastWriteTime)"
    Write-Host ""
    Write-Host "Character analysis of filename:"
    for ($i = 0; $i -lt $name.Length; $i++) {
        $c = $name[$i]
        $code = [int]$c
        Write-Host ("  Pos {0,2}: '{1}' = U+{2:X4} (decimal {3})" -f $i, $c, $code, $code)
    }
    Write-Host ""
    Write-Host "---"
    Write-Host ""
}
