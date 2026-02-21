$files = Get-ChildItem 'D:\Obsidian\Main\10 - Clippings\All in*'
foreach ($f in $files) {
    Write-Host "NAME: $($f.Name)"
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    Write-Host $text.Substring(0, [Math]::Min(500, $text.Length))
}
$files2 = Get-ChildItem 'D:\Obsidian\Main\10 - Clippings\Dunning*'
foreach ($f in $files2) {
    Write-Host "NAME: $($f.Name)"
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    Write-Host $text.Substring(0, [Math]::Min(500, $text.Length))
}
