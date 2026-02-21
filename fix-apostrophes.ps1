# Script to find and rename files with curly apostrophes
$folders = @(
    "D:\Obsidian\Main\20 - Permanent Notes",
    "D:\Obsidian\Main\09 - Kindle Clippings"
)

foreach ($folder in $folders) {
    Get-ChildItem -Path $folder -Filter "*.md" | ForEach-Object {
        $oldName = $_.Name
        # Check for curly apostrophe (Unicode U+2019)
        if ($oldName -match [char]0x2019) {
            $newName = $oldName -replace [char]0x2019, "'"
            Write-Host "Renaming: $oldName -> $newName"
            Rename-Item -Path $_.FullName -NewName $newName
        }
    }
}
Write-Host "Done!"
