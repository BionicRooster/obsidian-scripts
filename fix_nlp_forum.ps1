# Fix NLP Forum file that has literal \n instead of real newlines
# Use Get-ChildItem to avoid em-dash path encoding issues

$dir = 'D:\Obsidian\Main\01\NLP'

# Find the file by partial name pattern
$file = Get-ChildItem -Path $dir -Filter '*NLP Forum*Contest*' | Select-Object -First 1

if ($null -eq $file) {
    Write-Output "File not found"
    exit
}

Write-Output "Found: $($file.FullName)"

# Read as UTF-8 using the file's FullName from the FileInfo object
$content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

Write-Output "File length: $($content.Length) chars"
Write-Output "Contains literal backslash-n: $($content.Contains('\n'))"

# Replace literal \n (backslash + n) with real newlines
$fixed = $content -replace '\\n', "`n"

# Remove garbage Related Notes entries
$fixed = $fixed -replace '- \[\[me\. If\]\]\r?\n', ''
$fixed = $fixed -replace '- \[\[sudden ethical pangs\.\]\]\r?\n', ''
$fixed = $fixed -replace '- \[\[People Index\]\]\r?\n', ''

# Write back as UTF-8
[System.IO.File]::WriteAllText($file.FullName, $fixed, [System.Text.Encoding]::UTF8)

Write-Output "Done."
