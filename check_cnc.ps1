$files = Get-ChildItem 'D:\Obsidian\Main\10 - Clippings\' | Where-Object { $_.Name -like '*CNC*' }
foreach ($f in $files) {
    Write-Host "Name: $($f.Name)"
    Write-Host "FullName: $($f.FullName)"
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($f.Name)
    $hex = ($bytes | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
    Write-Host "Hex: $hex"
}
