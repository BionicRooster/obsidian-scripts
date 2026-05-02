# Read Kindle Clippings files for classification

$files = @(
    'D:\Obsidian\Main\09 - Kindle Clippings\Bates_et_al-Head First Design Patterns.md',
    'D:\Obsidian\Main\09 - Kindle Clippings\Collins-Waking Up Dead.md'
)

foreach ($f in $files) {
    Write-Host "`n=== $f ===" -ForegroundColor Cyan
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text = if ($hasBom) {
        [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    } else {
        [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    # Print first 30 lines
    ($text -split "`n") | Select-Object -First 30 | ForEach-Object { Write-Host $_ }
}
