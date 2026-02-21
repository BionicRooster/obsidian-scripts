$base = 'D:\Obsidian\Main\10 - Clippings'
$files = Get-ChildItem "$base\Ukraine*"
foreach ($f in $files) {
    Write-Host "=== $($f.Name) ==="
    $lines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
    $lines[0..14] | ForEach-Object { Write-Host $_ }
}
$files2 = Get-ChildItem "$base\TV dialogue*"
foreach ($f in $files2) {
    Write-Host "=== $($f.Name) ==="
    $lines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
    $lines[0..14] | ForEach-Object { Write-Host $_ }
}
$files3 = Get-ChildItem "$base\Winegard*"
foreach ($f in $files3) {
    Write-Host "=== $($f.Name) ==="
    $lines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
    $lines[0..14] | ForEach-Object { Write-Host $_ }
}
