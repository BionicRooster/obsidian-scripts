# Spot-check fixed files - show their Related Notes sections
$files = @(
    'C:\Users\awt\Sync\Obsidian\16 - Organizations\National Spiritual Assembly of the Bahai''s of the United States.md',
    'C:\Users\awt\Sync\Obsidian\01\Psychology\Dunning-Kruger Effect - Wikipedia.md'
)

foreach ($f in $files) {
    if (-not (Test-Path $f)) { Write-Host "NOT FOUND: $f" -ForegroundColor Red; continue }
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text = if ($hasBom) { [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3) } else { [System.Text.Encoding]::UTF8.GetString($bytes) }
    Write-Host "`n=== $(Split-Path $f -Leaf) ===" -ForegroundColor Cyan
    $inRelated = $false
    foreach ($line in ($text -split '\n')) {
        if ($line -match '^## Related') { $inRelated = $true }
        if ($inRelated) { Write-Host $line }
    }
}
