# Read NLP/Psychology and Science/Nature MOCs for classification targets

$mocDir = 'D:\Obsidian\Main\00 - Home Dashboard'

$mocs = @(
    'MOC - NLP & Psychology.md',
    'MOC - Science & Nature.md',
    'MOC - Travel & Exploration.md'
)

foreach ($name in $mocs) {
    $path = Join-Path $mocDir $name
    Write-Host "`n=== $name ===" -ForegroundColor Cyan
    $bytes  = [System.IO.File]::ReadAllBytes($path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) { [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3) } else { [System.Text.Encoding]::UTF8.GetString($bytes) }
    Write-Host $text
}
