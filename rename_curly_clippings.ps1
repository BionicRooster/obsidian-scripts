# rename_curly_clippings.ps1
# Renames files in 10 - Clippings that have curly/smart quotes in their names,
# replacing them with standard straight apostrophes/quotes before any file operations.

$folder = 'C:\Users\awt\Sync\Obsidian\10 - Clippings'

$files = Get-ChildItem -Path $folder -Filter '*.md' -ErrorAction SilentlyContinue

foreach ($file in $files) {
    # Build normalized name: replace all smart quote variants with straight equivalents
    $newName = $file.Name `
        -replace [char]0x2018, "'" `   # LEFT single quotation mark -> straight apostrophe
        -replace [char]0x2019, "'" `   # RIGHT single quotation mark -> straight apostrophe
        -replace [char]0x201C, '"' `   # LEFT double quotation mark -> straight quote
        -replace [char]0x201D, '"'     # RIGHT double quotation mark -> straight quote

    if ($newName -ne $file.Name) {
        $destPath = Join-Path $folder $newName
        Rename-Item -Path $file.FullName -NewName $newName -Force -ErrorAction SilentlyContinue
        Write-Output "Renamed: $($file.Name)"
        Write-Output "     To: $newName"
    }
}

Write-Output "Done."
