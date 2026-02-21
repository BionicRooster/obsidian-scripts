# Fix the duplicate Abdu'l files
$folder = "D:\Obsidian\Main\20 - Permanent Notes"
$standardApos = [char]0x0027  # '
$smartApos = [char]0x2019     # '

$files = Get-ChildItem -Path $folder -Filter "*Abdu*"

$stubFile = $null
$realFile = $null

foreach ($file in $files) {
    $apostropheChar = $file.Name[18]
    if ([int]$apostropheChar -eq 0x0027) {
        $stubFile = $file
        Write-Host "Found STUB file (standard apostrophe): $($file.Name) - $($file.Length) bytes"
    } else {
        $realFile = $file
        Write-Host "Found REAL file (smart apostrophe): $($file.Name) - $($file.Length) bytes"
    }
}

if ($stubFile -and $realFile) {
    # Delete the stub file
    Write-Host ""
    Write-Host "Deleting stub file: $($stubFile.FullName)"
    Remove-Item -Path $stubFile.FullName -Force
    Write-Host "Deleted successfully."

    # Rename the real file to use standard apostrophe
    $newName = $realFile.Name.Replace($smartApos, $standardApos)
    Write-Host ""
    Write-Host "Renaming real file:"
    Write-Host "  From: $($realFile.Name)"
    Write-Host "  To:   $newName"
    Rename-Item -Path $realFile.FullName -NewName $newName
    Write-Host "Renamed successfully."
} else {
    Write-Host "Could not find both files to process."
}
