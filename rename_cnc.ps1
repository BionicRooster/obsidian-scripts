$src = "D:\Obsidian\Main\10 - Clippings\CNCs That Won\u2019t Take Your Whole Garage.md"
# Find the file with smart apostrophe
$files = Get-ChildItem 'D:\Obsidian\Main\10 - Clippings\' | Where-Object { $_.Name -like '*CNC*' }
foreach ($f in $files) {
    $newName = $f.Name -replace [char]0x2019, "'"
    if ($newName -ne $f.Name) {
        Rename-Item -LiteralPath $f.FullName -NewName $newName
        Write-Host "Renamed to: $newName"
    }
}
