# Script to fix garbage characters in the Talbot file
# Using character-by-character approach

$filePath = "D:\Obsidian\Main\20 - Permanent Notes\The Living Descendants of British Royal Blood Talbot, Field.md"

# Read as bytes to preserve exact content
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

$originalSize = $content.Length
Write-Host "Original size: $originalSize characters"

# The garbage patterns all contain these specific character sequences
# Let's identify them by their actual Unicode values

# Common garbage substrings to remove (exact matches)
$garbagePatterns = @(
    "A?'�'A? 'A?'�? 'A?'�'A��,� A?'A�A��?sA�A��?zA�A?'�'A? 'A?'A�A��?sA� A?'�'A,A�A?'A�A��,�?...�A,A�A?'A�A��,�?..._A,A�A?'�'A? 'A?'�? 'A?'�'A,A�A?'A�A��,�?...�A,A�A?'.A,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A,"
    "A?'�'A? 'A?'�? 'A?'�'A��,� A?'A�A��?sA�A��?zA�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�? 'A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�?sA,A�A?'�'A,A�A?'A�A��?sA�A.A�A?'�?sA,A�A?'�'A��,�A�A?'�?sA,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�? 'A?'�'A,A�A?'A�A��,�?...�A,A�A?'.A,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�"
    "A?'�'A? 'A?'�? 'A?'�'A��,� A?'A�A��?sA�A��?zA�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�? 'A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�?sA,A�A?'�'A,A�A?'A�A��?sA�A.A�A?'�?sA,A�A?'�'A��,�A�A?'�?sA,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�? 'A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�?sA,A�A?'�'A,A�A?'A�A��,�?...�A,A�A?'.A,A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A?"
    "A?'�'A? 'A?'�? 'A?'�'A��,� A?'A�A��?sA�A��?zA�A?'�'A? 'A?'A�A��?sA� A?'�'A,A�A?'A�A��,�?...�A,A�A?'A�A��,�?..._A,A�A?'�'A? 'A?'�? 'A?'�'A,A�A?'A�A��,�?...�A,A�A?'.A,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,"
    "A?'�'A? 'A?'�? 'A?'�'A��,� A?'A�A��?sA�A��?zA�A?'�'A? 'A?'A�A��?sA� A?'�'A,A�A?'A�A��,�?...�A,A�A?'A�A��,�?..._A,A�A?'�'A? 'A?'�? 'A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�?sA,A�A?'�'A,A�A?'A�A��,�?...�A,A�A?'.A,A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,"
    "A?'�'A? 'A?'�? 'A?'�'A��,� A?'A�A��?sA�A��?zA�A?'�'A? 'A?'�?sA,A�A?'�'A,A�A?'A�A��?sA�A.A�A?'�?sA,A�A?'�'A��,�A�A?'�?sA,A�A?'�'A? 'A?'�? 'A?'�'A,A�A?'A�A��,�?...�A,A�A?'.A,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�"
    "A?'�'A? 'A?'�? 'A?'�'A��,� A?'A�A��?sA�A��?zA�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�? 'A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�?sA,A�A?'�'A,A�A?'A�A��?sA�A.A�A?'�?sA,A�A?'�'A��,�A�A?'�?sA,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�? 'A?'�'A,A�A?'A�A��,�?...�A,A�A?'.A,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A?"
    "A?'�'A? 'A?'�? 'A?'�'A��,� A?'A�A��?sA�A��?zA�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�? 'A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�?sA,A�A?'�'A,A�A?'A�A��,�?...�A,A�A?'.A,A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'A�A��?sA�A,A�A?'�'A��,�?...�A?'�?sA,A�A?'�'A? 'A?'�? 'A?'�'A,A�A?'A�A��,�?...�A,A�A?'.A,A�A?'�'A? 'A?'A�A��?sA�A.A�A?'�'A��,�?...�A?'�?sA,A�"
)

# First pass - remove exact long garbage patterns
foreach ($pattern in $garbagePatterns) {
    $content = $content.Replace($pattern, "")
}

Write-Host "After removing long patterns: $($content.Length) characters"

# Second pass - use regex to catch variations
# The core garbage unit seems to be: A?'...A...
$content = [regex]::Replace($content, "A\?'[^a-zA-Z0-9\s\[\]\(\)\.,;:!\-]{3,}?(?=[a-zA-Z0-9\s\[\]\(\)]|$)", "")

Write-Host "After regex pass: $($content.Length) characters"

# Third pass - remove any remaining isolated garbage characters
# These special chars appear in garbage: � ' '
$content = $content -replace '�', ''
$content = $content -replace ''', "'"
$content = $content -replace ''', "'"

# Clean multiple spaces and newlines
$content = $content -replace '  +', ' '
$content = $content -replace ' +\r?\n', "`n"
$content = $content -replace '\r?\n +', "`n"
$content = $content -replace '(\r?\n){3,}', "`n`n"

$newSize = $content.Length
Write-Host "Final size: $newSize characters"
Write-Host "Removed: $($originalSize - $newSize) characters ($([math]::Round(($originalSize - $newSize) / $originalSize * 100, 1))%)"

# Write cleaned content back
[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)

Write-Host "`nFile cleaned successfully!"

# Show preview
Write-Host "`n--- PREVIEW (first 2000 chars) ---"
Write-Host $content.Substring(0, [Math]::Min(2000, $content.Length))
