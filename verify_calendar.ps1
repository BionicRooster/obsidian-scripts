# verify_calendar.ps1
# Spot-check frontmatter on 2010 and 2025 Personal Calendar Summary files

$utf8 = [System.Text.Encoding]::UTF8

foreach ($year in @(2010, 2025)) {
    $path = "D:\Obsidian\Main\$year Personal Calendar Summary.md"
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $text = $utf8.GetString($bytes)
    $lines = $text -split "`n"
    Write-Output "=== $year (first 12 lines) ==="
    for ($i = 0; $i -lt [Math]::Min(12, $lines.Count); $i++) {
        Write-Output $lines[$i]
    }
    Write-Output ""
}
