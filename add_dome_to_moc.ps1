# add_dome_to_moc.ps1 - Add Monolithic Dome note to Home MOC > Sustainable Building

$homeMocPath = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Home & Practical Life.md'
$linkText    = 'This Home Survives EF5 Tornadoes Wildfires and Costs $0 to Heat'

# Insert alphabetically in Sustainable Building section, after "Not Your Typical Yurt"
$anchor = '- [[Not Your Typical Yurt]]'

$bytes  = [System.IO.File]::ReadAllBytes($homeMocPath)
$hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
$enc    = [System.Text.Encoding]::UTF8
$text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

if ($text -match [regex]::Escape($linkText)) {
    Write-Host 'Already present' -ForegroundColor DarkGray
} elseif ($text -notmatch [regex]::Escape($anchor)) {
    Write-Host "Anchor not found: $anchor" -ForegroundColor Yellow
} else {
    $newText  = $text -replace [regex]::Escape($anchor), "$anchor`n- [[$linkText]]"
    $outBytes = $enc.GetBytes($newText)
    if ($hasBom) { $outBytes = [byte[]](0xEF, 0xBB, 0xBF) + $outBytes }
    [System.IO.File]::WriteAllBytes($homeMocPath, $outBytes)
    Write-Host "Added [[$linkText]] to MOC - Home & Practical Life > Sustainable Building" -ForegroundColor Green
}
