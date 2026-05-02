# rename_curly2.ps1
# Cleans all curly/smart quote characters from filenames in 10 - Clippings.
# Runs all four replacements in a single expression without line continuation comments.

$folder = 'D:\Obsidian\Main\10 - Clippings'

$leftSingle  = [char]0x2018   # LEFT single quotation mark
$rightSingle = [char]0x2019   # RIGHT single quotation mark
$leftDouble  = [char]0x201C   # LEFT double quotation mark
$rightDouble = [char]0x201D   # RIGHT double quotation mark

$files = Get-ChildItem -Path $folder -Filter '*.md' -ErrorAction SilentlyContinue

foreach ($file in $files) {
    $n = $file.Name
    $n = $n -replace $leftSingle,  "'"
    $n = $n -replace $rightSingle, "'"
    $n = $n -replace $leftDouble,  '"'
    $n = $n -replace $rightDouble, '"'

    if ($n -ne $file.Name) {
        Rename-Item -Path $file.FullName -NewName $n -Force
        Write-Output "Renamed: $($file.Name)"
        Write-Output "     To: $n"
    }
}
Write-Output "Done."
