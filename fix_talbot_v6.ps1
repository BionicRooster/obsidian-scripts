# Script to fix garbage characters in the Talbot file
# Aggressive removal of mojibake character sequences

$filePath = "D:\Obsidian\Main\20 - Permanent Notes\The Living Descendants of British Royal Blood Talbot, Field.md"

$bytes = [System.IO.File]::ReadAllBytes($filePath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

$originalSize = $content.Length
Write-Host "Original size: $originalSize characters"

# The garbage is mojibake - UTF-8 misinterpreted multiple times
# Main garbage chars (by Unicode code point):
# 195 (Ã), 194 (Â), 162 (¢), 226 (â), 8218 (‚), 8364 (€)
# 172 (¬), 198 (Æ), 353 (š), 161 (¡), 8230 (…), 382 (ž)

# Build the set of garbage characters
$garbageChars = @(
    [char]195,  # Ã
    [char]194,  # Â
    [char]162,  # ¢
    [char]226,  # â
    [char]8218, # ‚ (single low-9 quote)
    [char]8364, # €
    [char]172,  # ¬
    [char]198,  # Æ
    [char]353,  # š
    [char]161,  # ¡
    [char]8230, # … (ellipsis)
    [char]382,  # ž
    [char]166,  # ¦
    [char]190,  # ¾
    [char]183,  # ·
    [char]157,  # control char
    [char]129,  # control char
    [char]163   # £
)

$garbageSet = [System.Collections.Generic.HashSet[char]]::new()
foreach ($c in $garbageChars) {
    [void]$garbageSet.Add($c)
}

# Process character by character
# Keep track of "good text" vs "garbage sequences"
$result = [System.Text.StringBuilder]::new()
$i = 0

while ($i -lt $content.Length) {
    $char = $content[$i]
    $code = [int]$char

    # Check if this is a garbage character or part of garbage sequence
    if ($garbageSet.Contains($char)) {
        # Skip this garbage character
        $i++
        continue
    }

    # Check for A' pattern (common mojibake start)
    if ($char -eq 'A' -and ($i + 1) -lt $content.Length) {
        $nextChar = $content[$i + 1]
        if ($nextChar -eq "'" -or $garbageSet.Contains($nextChar)) {
            # Check if followed by more garbage
            $j = $i + 1
            $garbageRun = 0
            while ($j -lt $content.Length -and $j -lt $i + 50) {
                $testChar = $content[$j]
                if ($garbageSet.Contains($testChar) -or $testChar -eq "'" -or $testChar -eq 'A' -or $testChar -eq '?' -or $testChar -eq '.' -or $testChar -eq ',' -or $testChar -eq '_' -or $testChar -eq ' ') {
                    $garbageRun++
                } else {
                    break
                }
                $j++
            }
            if ($garbageRun -gt 10) {
                # This is a garbage sequence, skip it
                $i = $j
                continue
            }
        }
    }

    # Keep regular characters
    [void]$result.Append($char)
    $i++
}

$content = $result.ToString()

# Clean up remaining issues
$content = $content -replace "'", "'"  # Normalize apostrophes
$content = $content -replace "[ ]{2,}", " "  # Multiple spaces
$content = $content -replace "[ ]+`n", "`n"  # Trailing spaces
$content = $content -replace "`n[ ]+", "`n"  # Leading spaces
$content = $content -replace "`n{3,}", "`n`n"  # Multiple newlines

$newSize = $content.Length
Write-Host "Final size: $newSize characters"
Write-Host "Removed: $($originalSize - $newSize) characters ($([math]::Round(($originalSize - $newSize) / $originalSize * 100, 1))%)"

# Write result
[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)

Write-Host "`nFile cleaned!"
Write-Host "`n--- PREVIEW ---"
Write-Host $content.Substring(0, [Math]::Min(3000, $content.Length))
