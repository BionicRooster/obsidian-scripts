# Fix all em-dashes/en-dashes in double-quoted Write-Log strings and inline code
# in obsidian_maintenance.ps1 so PowerShell 5.1 doesn't misparse them.

$file = 'C:\Users\awt\obsidian_maintenance.ps1'
$bytes = [System.IO.File]::ReadAllBytes($file)
$hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
$enc = New-Object System.Text.UTF8Encoding($false)
$text = if ($hasBom) { $enc.GetString($bytes[3..($bytes.Length-1)]) } else { $enc.GetString($bytes) }

$emdash  = [char]0x2014  # —
$endash  = [char]0x2013  # –

# Replace em-dash and en-dash with ASCII hyphen-minus in every line that is NOT
# a pure comment (i.e., lines that have code or are inside strings).
# Pure comment lines (trimmed start with #) are left alone — harmless there.
$lines = $text -split '\r?\n'
$changed = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
    $L = $lines[$i]
    # Skip pure comment lines (the dashes in comments are harmless)
    if ($L -match '^\s*#') { continue }
    # Replace em-dash and en-dash with ' - '
    if ($L -match [regex]::Escape($emdash) -or $L -match [regex]::Escape($endash)) {
        $new = $L -replace [regex]::Escape($emdash), ' - ' -replace [regex]::Escape($endash), '-'
        $lines[$i] = $new
        $changed++
        Write-Host "Fixed line $($i+1): $($new.Substring(0,[Math]::Min(100,$new.Length)))"
    }
}

Write-Host "`nTotal lines fixed: $changed"

$newText  = $lines -join "`n"
$outBytes = if ($hasBom) {
    (New-Object System.Text.UTF8Encoding($true)).GetPreamble() + $enc.GetBytes($newText)
} else { $enc.GetBytes($newText) }
[System.IO.File]::WriteAllBytes($file, $outBytes)
Write-Host "Saved."
