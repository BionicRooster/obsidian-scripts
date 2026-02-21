# Fix the corrupted Alfred W. Talbot Sr _1.md file
# The file contains garbage OCR text - we'll keep only the images

$file = 'D:\Obsidian\Main\20 - Permanent Notes\Alfred W. Talbot Sr _1.md'
$content = Get-Content $file -Raw -Encoding UTF8

# Find all simple Exported image patterns (the clean ones)
$cleanImagePattern = '!\[Exported image\]\(Exported%20image%20\d+-\d+\.png\)'
$cleanMatches = [regex]::Matches($content, $cleanImagePattern)

Write-Host "Found $($cleanMatches.Count) clean Exported image links"

# Build the new clean content
$newContent = @"
#[[Genealogy]]
[[Genealogy]]

"@

foreach ($match in $cleanMatches) {
    $newContent += "$($match.Value)`n`n"
}

# Show what we'll write
Write-Host "`nNew content preview:"
Write-Host $newContent.Substring(0, [Math]::Min(500, $newContent.Length))
Write-Host "..."

# Write the file
Set-Content -Path $file -Value $newContent -Encoding UTF8
Write-Host "`nFile fixed! New size: $((Get-Item $file).Length) bytes"

# Also delete the duplicate file if both exist
$duplicateFile = 'D:\Obsidian\Main\20 - Permanent Notes\Alfred W. Talbot Sr .md'
if (Test-Path $duplicateFile) {
    Remove-Item $duplicateFile
    Write-Host "Deleted duplicate file: Alfred W. Talbot Sr .md"
}
