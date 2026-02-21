# Rename file with curly apostrophe to standard apostrophe (two-step via temp)
$folder = 'D:\Obsidian\Main\10 - Clippings'
$old = Get-ChildItem $folder | Where-Object { $_.Name -match 'cataclysmic' } | Select-Object -First 1
if ($old) {
    $newName = $old.Name -replace [char]0x2019, "'"
    $tempName = $old.Name + '.tmp'
    Rename-Item -LiteralPath $old.FullName -NewName $tempName
    Rename-Item -LiteralPath (Join-Path $folder $tempName) -NewName $newName
    Write-Host "Renamed: $($old.Name) -> $newName"
} else {
    Write-Host "File not found"
}
