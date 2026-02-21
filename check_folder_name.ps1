# Check the folder name character encoding
$folderPath = "D:\Obsidian\Main\00 - Images\Evernote-Resources"
$folders = Get-ChildItem -Path $folderPath -Directory | Where-Object { $_.Name -like "*Wright*" }

foreach ($folder in $folders) {
    Write-Host "Folder: $($folder.Name)"
    Write-Host ""
    Write-Host "Character analysis:"
    for ($i = 0; $i -lt $folder.Name.Length; $i++) {
        $c = $folder.Name[$i]
        $code = [int]$c
        Write-Host ("Position {0}: Char='{1}' Unicode=U+{2:X4} Decimal={3}" -f $i, $c, $code, $code)
    }
}
