# Final cleanup pass for Talbot file

$filePath = "D:\Obsidian\Main\20 - Permanent Notes\The Living Descendants of British Royal Blood Talbot, Field.md"

$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

$originalSize = $content.Length
Write-Host "Original size: $originalSize characters"

# Remove leading ?? or ?!
$content = [regex]::Replace($content, "^\?+", "")

# Remove isolated ? that appear to be garbage (not part of real questions)
# Keep ? only if followed by a space and then a capital letter (real question)
$content = [regex]::Replace($content, "\?(?![\s][A-Z]|\s*$)", "")

# Fix common OCR errors that appear in this document
$content = $content -replace "hi 8", "his"
$content = $content -replace "hi8", "his"
$content = $content -replace " eon ", " son "
$content = $content -replace " vlfe", " wife"
$content = $content -replace " vife", " wife"
$content = $content -replace " vae", " was"
$content = $content -replace " vas", " was"
$content = $content -replace " vho", " who"
$content = $content -replace "Vlll", "Will"
$content = $content -replace "Vill", "Will"
$content = $content -replace " v' ", " way "
$content = $content -replace "El ng", "King"
$content = $content -replace "E Ing", "King"
$content = $content -replace "r Ing", "King"
$content = $content -replace "X Ing", "King"

# Remove stray punctuation at start of lines
$content = [regex]::Replace($content, "(?m)^[\s,;:]+", "")

# Clean double spaces again
$content = [regex]::Replace($content, "[ ]{2,}", " ")

# Clean multiple newlines
$content = [regex]::Replace($content, "\n{3,}", "`n`n")

# Trim each line
$lines = $content -split "`n"
$lines = $lines | ForEach-Object { $_.Trim() }
$content = $lines -join "`n"

# Remove empty lines at start
$content = $content.TrimStart()

$newSize = $content.Length
Write-Host "Final size: $newSize characters"
Write-Host "Total removed from original 244KB: $($originalSize - $newSize) characters"

# Write result
[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)

Write-Host "`nFile cleaned!"
Write-Host "`n--- PREVIEW (first 3500 chars) ---"
Write-Host $content.Substring(0, [Math]::Min(3500, $content.Length))
