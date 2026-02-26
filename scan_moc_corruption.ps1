# scan_moc_corruption.ps1
# Finds corrupted/suspicious wikilinks in MOC files

$mocDir = "D:\Obsidian\Main\00 - Home Dashboard"   # folder to scan
$enc    = [System.Text.Encoding]::UTF8              # UTF-8 for all I/O

Get-ChildItem $mocDir -Filter "MOC - *.md" | Sort-Object Name | ForEach-Object {
    $bytes  = [System.IO.File]::ReadAllBytes($_.FullName)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

    # Short wikilinks (1-3 chars) - likely corrupted
    $short = [regex]::Matches($text, '\[\[([^\]]{1,3})\]\]') | ForEach-Object { $_.Groups[1].Value }

    # Malformed links: -[[ without space (e.g., -[[D]])
    $malformed = [regex]::Matches($text, '(?m)^-\[\[[^\]]+\]\]') | ForEach-Object { $_.Value }

    if ($short.Count -gt 0 -or $malformed.Count -gt 0) {
        Write-Host "`n[$($_.Name)]"
        foreach ($s in $short)     { Write-Host "  SHORT:    [[$s]]" }
        foreach ($m in $malformed) { Write-Host "  MALFORMED: $m" }
    }
}
Write-Host "`nScan complete."
