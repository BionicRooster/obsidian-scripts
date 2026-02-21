$filePath = "D:\Obsidian\Main\20 - Permanent Notes\The Living Descendants of British Royal Blood Talbot, Field.md"
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# Remove leading ? characters
while ($content.StartsWith("?")) {
    $content = $content.Substring(1)
}

# Remove stray * characters that are OCR errors
$content = $content -replace "\*", ""

# Save
[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)

Write-Host "Fixed! First 800 chars:"
Write-Host $content.Substring(0, 800)
