# fix_pilcrow.ps1
# The fix_uhj.ps1 script wrote the pilcrow character (U+00B6) using a literal
# in the PS1 source file.  PowerShell read that PS1 file as Windows-1252 instead
# of UTF-8, so the two UTF-8 bytes 0xC2 0xB6 were interpreted as two separate
# characters: U+00C2 (A-circumflex, Â) and U+00B6 (pilcrow, ¶).
# When written back as UTF-8 those two chars produced four bytes: C3 82 C2 B6.
# This script repairs that by replacing every Â¶ sequence with a single ¶.

$filePath = 'D:\Obsidian\Main\11 - Review\UHJ Nine Year Plan 2022-2031.md'

# Build the correct pilcrow character using its code point (avoids encoding
# issues with literal characters in script source files entirely).
$pilcrow     = [char]0x00B6   # U+00B6 — the paragraph/pilcrow sign: ¶

# The double-encoded form: U+00C2 followed by U+00B6.
# U+00C2 is the Latin capital A-circumflex (Â).
$aCircumflex = [char]0x00C2   # U+00C2

# The bad string that ended up in the file is Â followed by ¶
$badString   = "$aCircumflex$pilcrow"   # Â¶ (2 chars, 4 UTF-8 bytes: C3 82 C2 B6)
$goodString  = "$pilcrow"               # ¶  (1 char,  2 UTF-8 bytes: C2 B6)

# Read the file as UTF-8
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# Count occurrences before repair
$countBefore = ($content.Split($badString).Count - 1)
Write-Host "Double-encoded pilcrow sequences found: $countBefore"

# Replace all double-encoded sequences with the correct single character
$content = $content.Replace($badString, $goodString)

# Verify: count remaining occurrences after repair
$countAfter = ($content.Split($badString).Count - 1)
Write-Host "Remaining after repair: $countAfter"

# Count correct pilcrow sequences now present
$correctCount = ($content.Split($goodString).Count - 1)
Write-Host "Correct pilcrow sequences now in file: $correctCount"

# Write back with UTF-8 no-BOM
$utf8NoBOM = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($filePath, $content, $utf8NoBOM)

Write-Host "Done. File repaired." -ForegroundColor Green

# Quick byte verification: check first ** marker
$raw = [System.IO.File]::ReadAllBytes($filePath)
for ($i = 0; $i -lt $raw.Count - 5; $i++) {
    if ($raw[$i] -eq 0x2A -and $raw[$i+1] -eq 0x2A -and $raw[$i+2] -eq 0xC2 -and $raw[$i+3] -eq 0xB6) {
        $snippet = $raw[$i..($i+10)] | ForEach-Object { '0x{0:X2}' -f $_ }
        Write-Host "VERIFIED: Correct pilcrow bytes at first ** position: $($snippet -join ' ')"
        break
    }
}
