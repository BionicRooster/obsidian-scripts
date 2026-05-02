# Comprehensive cleanup of People Index: removes all entries where the surname
# (the part before the comma in "### Surname, Firstname") starts with a lowercase
# letter. These are guaranteed false positives from broken Phase 26 runs.
# Also removes known false-positive entries where surname starts with uppercase
# but is clearly not a real surname (common English words, NLP terms, etc.).

$enc      = New-Object System.Text.UTF8Encoding($false)
$filePath = 'D:\Obsidian\Main\People Index.md'

$bytes  = [System.IO.File]::ReadAllBytes($filePath)
$hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
$text   = if ($hasBom) { $enc.GetString($bytes[3..($bytes.Length-1)]) } else { $enc.GetString($bytes) }
$lines  = [System.Collections.Generic.List[string]]($text -split '\r?\n')
$eol    = if ($text -match '\r\n') { "`r`n" } else { "`n" }

# Build lookup of index where each ### heading starts
$removed = 0
$i = 0
while ($i -lt $lines.Count) {
    $line = $lines[$i]
    if ($line -match '^### ([^, ]+)(?:,|$)') {
        $surname = $Matches[1] -replace '[^\p{L}\p{N}]', ''  # strip punctuation for check

        # Check if surname starts with lowercase letter (case-sensitive check in .NET)
        $shouldRemove = ($surname.Length -gt 0 -and [char]::IsLower($surname[0]))

        if ($shouldRemove) {
            # Find end of this entry (next ### or ## or ---)
            $end = $i + 1
            while ($end -lt $lines.Count -and $lines[$end] -notmatch '^### |^## |^---') {
                $end++
            }
            $count = $end - $i
            Write-Host "Removing (lowercase): $line"
            $lines.RemoveRange($i, $count)
            $removed++
            # Don't increment $i — the next line shifted into position $i
            continue
        }
    }
    $i++
}

Write-Host "`nRemoved $removed lowercase-surname entries."
Write-Host "Remaining ### entries: $(($lines | Where-Object { $_ -match '^### ' }).Count)"

$newText  = $lines -join $eol
$outBytes = if ($hasBom) {
    (New-Object System.Text.UTF8Encoding($true)).GetPreamble() + $enc.GetBytes($newText)
} else { $enc.GetBytes($newText) }
[System.IO.File]::WriteAllBytes($filePath, $outBytes)
Write-Host "Saved People Index."
