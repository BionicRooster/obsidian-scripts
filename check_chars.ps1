$filePath = "D:\Obsidian\Main\20 - Permanent Notes\The Living Descendants of British Royal Blood Talbot, Field.md"
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

Write-Host "First 15 character codes:"
for ($i = 0; $i -lt 15; $i++) {
    $code = [int]$content[$i]
    $char = $content[$i]
    Write-Host "  Position $i : Code $code (char: $char)"
}

# Remove any char with code > 127 from the first 5 positions
$sb = [System.Text.StringBuilder]::new()
$skip = 0
for ($i = 0; $i -lt $content.Length; $i++) {
    $code = [int]$content[$i]
    if ($i -lt 5 -and $code -gt 127) {
        $skip++
        continue
    }
    [void]$sb.Append($content[$i])
}

$newContent = $sb.ToString()
Write-Host "`nSkipped $skip chars from start"

[System.IO.File]::WriteAllText($filePath, $newContent, [System.Text.Encoding]::UTF8)
Write-Host "Saved! New first 300 chars:"
Write-Host $newContent.Substring(0, 300)
