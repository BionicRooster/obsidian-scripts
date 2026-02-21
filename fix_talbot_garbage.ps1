# Script to fix garbage characters in the Talbot file
# The file has severe multi-level encoding corruption (mojibake)

$filePath = "D:\Obsidian\Main\20 - Permanent Notes\The Living Descendants of British Royal Blood Talbot, Field.md"
$content = Get-Content $filePath -Raw -Encoding UTF8

$originalSize = $content.Length
Write-Host "Original size: $originalSize characters"

# The garbage patterns are variations of badly encoded characters
# They follow patterns like: A?'something with special chars

# Remove the main garbage pattern blocks (long sequences of garbage)
# Pattern: A? followed by various garbage chars repeated
$content = $content -replace "A\?'[^a-zA-Z0-9\[\]\(\)\.,;:\-\!\?\s\n\r]{5,}", ""

# Remove remaining A?' patterns with garbage
$content = $content -replace "A\?'[�'A\?sA,zA\.�]+", ""
$content = $content -replace "A\?'A�[^a-zA-Z\n]+", ""

# Remove standalone garbage sequences
$content = $content -replace "�[^a-zA-Z\s]{2,}", ""
$content = $content -replace "\?s[A,zA\.�]+", ""
$content = $content -replace "A�[^a-zA-Z\s]{2,}", ""

# Clean A?' with trailing garbage
$content = $content -replace "A\?'[^a-zA-Z\s]{1,}", ""

# Clean up any remaining isolated garbage chars
$content = $content -replace "�+", ""
$content = $content -replace "A\?", ""

# Clean multiple spaces
$content = $content -replace "  +", " "
$content = $content -replace " +`n", "`n"
$content = $content -replace "`n +", "`n"

# Clean multiple newlines (more than 2)
$content = $content -replace "(`n){3,}", "`n`n"

$newSize = $content.Length
Write-Host "New size: $newSize characters"
Write-Host "Removed: $($originalSize - $newSize) characters"

# Write cleaned content back
$content | Set-Content $filePath -Encoding UTF8 -NoNewline

Write-Host "`nFile cleaned successfully!"

# Show preview of first part
Write-Host "`n--- PREVIEW (first 1500 chars) ---"
Write-Host $content.Substring(0, [Math]::Min(1500, $content.Length))
