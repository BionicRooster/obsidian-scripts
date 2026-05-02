# add_clipping_to_moc.ps1
# Adds Bates Head First Design Patterns to Technology MOC under Computer Sciences

$techMocPath = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Technology & Computers.md'   # Path to tech MOC

# Read raw bytes to preserve BOM
$bytes   = [System.IO.File]::ReadAllBytes($techMocPath)
$hasBom  = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF   # UTF-8 BOM flag
$enc     = [System.Text.Encoding]::UTF8   # Encoding to use
$text    = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }   # Decoded text

# Check if already present
if ($text -match 'Bates_et_al-Head First Design Patterns') {
    Write-Host "Already in MOC - skipping" -ForegroundColor Yellow
    exit 0
}

# Insert after [[Batch File Help]] (alphabetically correct position)
$insertAfter  = '- [[Batch File Help]]'        # Anchor line to insert after
$newEntry     = '- [[Bates_et_al-Head First Design Patterns]]'   # New link to add
$newText      = $text -replace [regex]::Escape($insertAfter), "$insertAfter`n$newEntry"   # Insert new line after anchor

if ($newText -eq $text) {
    Write-Host "Anchor '[[Batch File Help]]' not found - cannot insert" -ForegroundColor Red
    exit 1
}

# Write back with BOM if original had one
$outBytes = $enc.GetBytes($newText)   # Encode modified text
if ($hasBom) {
    $bomBytes = [byte[]](0xEF, 0xBB, 0xBF)   # UTF-8 BOM bytes
    $outBytes = $bomBytes + $outBytes
}
[System.IO.File]::WriteAllBytes($techMocPath, $outBytes)   # Write to disk
Write-Host "Added [[Bates_et_al-Head First Design Patterns]] to MOC - Technology & Computers > Computer Sciences" -ForegroundColor Green
