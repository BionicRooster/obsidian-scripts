# Replace non-ASCII decorative characters in the script files with ASCII equivalents
# U+2500 (box-drawing ─) -> hyphen -
# U+2014 (em-dash —) -> hyphen -
# U+2013 (en-dash –) -> hyphen -

$files = @(
    'C:\Users\awt\cleanup_misplaced_links.ps1',
    'C:\Users\awt\link_orphans.ps1',
    'C:\Users\awt\analyze_moc_links.ps1',
    'C:\Users\awt\moc_keywords.ps1'
)

foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $original = $text

    # Replace decorative non-ASCII dashes with ASCII hyphens
    $text = $text -replace [char]0x2500, '-'   # ─ box drawing light horizontal
    $text = $text -replace [char]0x2014, '-'   # — em dash
    $text = $text -replace [char]0x2013, '-'   # – en dash

    if ($text -ne $original) {
        [System.IO.File]::WriteAllText($f, $text, [System.Text.Encoding]::UTF8)
        Write-Host "Fixed: $f" -ForegroundColor Green
    } else {
        Write-Host "Clean: $f" -ForegroundColor Gray
    }
}
