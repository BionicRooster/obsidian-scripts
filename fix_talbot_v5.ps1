# Script to fix garbage characters in the Talbot file
# Using character-by-character approach

$filePath = "D:\Obsidian\Main\20 - Permanent Notes\The Living Descendants of British Royal Blood Talbot, Field.md"

# Read as bytes to preserve exact content
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

$originalSize = $content.Length
Write-Host "Original size: $originalSize characters"

# First, let's identify the garbage by looking at character codes
# Build a list of character frequencies to understand what we're dealing with
$charCodes = @{}
foreach ($char in $content.ToCharArray()) {
    $code = [int]$char
    if ($code -gt 127 -or $char -eq '?') {
        if (-not $charCodes.ContainsKey($code)) {
            $charCodes[$code] = 0
        }
        $charCodes[$code]++
    }
}

Write-Host "`nNon-ASCII character frequencies:"
$charCodes.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20 | ForEach-Object {
    $char = [char]$_.Key
    Write-Host "  Code $($_.Key) ($char): $($_.Value) occurrences"
}

# The main garbage pattern starts with "A?" followed by special chars
# Let's remove sequences that match: A followed by ? followed by garbage

# Strategy: Find and remove sequences starting with "A?" that contain
# primarily non-printable/garbage characters

$sb = [System.Text.StringBuilder]::new()
$i = 0
$removed = 0

while ($i -lt $content.Length) {
    $char = $content[$i]

    # Check if this looks like start of garbage sequence (A?)
    if ($char -eq 'A' -and ($i + 1) -lt $content.Length -and $content[$i + 1] -eq '?') {
        # Scan ahead to see if this is garbage
        $scanEnd = [Math]::Min($i + 300, $content.Length)
        $garbageCount = 0
        $totalScanned = 0

        for ($j = $i + 2; $j -lt $scanEnd; $j++) {
            $scanChar = $content[$j]
            $code = [int]$scanChar
            $totalScanned++

            # Count garbage indicators
            if ($code -gt 127 -or $scanChar -eq '?' -or $scanChar -eq [char]0x2019 -or $scanChar -eq [char]0x2018) {
                $garbageCount++
            }

            # If we hit a clear word boundary with normal text, stop
            if ($totalScanned -gt 5) {
                $remaining = $content.Substring($j, [Math]::Min(20, $content.Length - $j))
                if ($remaining -match "^[a-zA-Z]{3,}") {
                    break
                }
            }
        }

        # If more than 50% garbage characters, skip this sequence
        if ($totalScanned -gt 5 -and $garbageCount / $totalScanned -gt 0.3) {
            # Skip to end of garbage
            $skipTo = $i + $totalScanned
            $removed += ($skipTo - $i)
            $i = $skipTo
            continue
        }
    }

    # Keep this character
    [void]$sb.Append($char)
    $i++
}

$content = $sb.ToString()
Write-Host "`nAfter removing garbage sequences: $($content.Length) characters"

# Remove any remaining special unicode chars that are clearly garbage
$content = $content -replace [char]0xFFFD, ""  # Replacement character
$content = $content -replace [char]0x2019, "'"  # Right single quote to apostrophe
$content = $content -replace [char]0x2018, "'"  # Left single quote to apostrophe

# Clean multiple spaces
$content = $content -replace "[ ]{2,}", " "
$content = $content -replace "[ ]+`n", "`n"
$content = $content -replace "`n[ ]+", "`n"

# Clean excessive newlines
$content = $content -replace "`n{3,}", "`n`n"

$newSize = $content.Length
Write-Host "Final size: $newSize characters"
Write-Host "Removed: $($originalSize - $newSize) characters ($([math]::Round(($originalSize - $newSize) / $originalSize * 100, 1))%)"

# Write cleaned content back
[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)

Write-Host "`nFile cleaned successfully!"

# Show preview
Write-Host "`n--- PREVIEW (first 2000 chars) ---"
Write-Host $content.Substring(0, [Math]::Min(2000, $content.Length))
