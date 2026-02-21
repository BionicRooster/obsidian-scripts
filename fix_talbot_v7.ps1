# Script to clean remaining garbage sequences
# After v6, we have leftover apostrophe/period patterns like '' '' ''' ''''...'

$filePath = "D:\Obsidian\Main\20 - Permanent Notes\The Living Descendants of British Royal Blood Talbot, Field.md"

$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

$originalSize = $content.Length
Write-Host "Original size: $originalSize characters"

# Remove sequences of apostrophes, periods, commas, and spaces that form garbage
# Pattern: 3+ consecutive chars from the set [' . , _]
$content = [regex]::Replace($content, "['\.\,_\s]{4,}", " ")

# Remove leading ?? or ?
$content = [regex]::Replace($content, "^\?+", "")

# Remove isolated ? that aren't part of question marks
$content = [regex]::Replace($content, "\?(?![a-zA-Z\s])", "")

# Clean double spaces
$content = [regex]::Replace($content, "[ ]{2,}", " ")

# Clean up spaces around punctuation
$content = [regex]::Replace($content, "\s+\.", ".")
$content = [regex]::Replace($content, "\s+,", ",")
$content = [regex]::Replace($content, "\s+;", ";")

# Clean multiple newlines
$content = [regex]::Replace($content, "\n{3,}", "`n`n")

# Trim lines
$lines = $content -split "`n"
$lines = $lines | ForEach-Object { $_.Trim() }
$content = $lines -join "`n"

$newSize = $content.Length
Write-Host "Final size: $newSize characters"
Write-Host "Removed: $($originalSize - $newSize) characters"

# Write result
[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)

Write-Host "`nFile cleaned!"
Write-Host "`n--- PREVIEW ---"
Write-Host $content.Substring(0, [Math]::Min(3000, $content.Length))
