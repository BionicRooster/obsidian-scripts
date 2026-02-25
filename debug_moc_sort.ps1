# Debug: check what link lines are found and if any are out of order
$path = "D:\Obsidian\Main\00 - Home Dashboard\MOC - Japan & Japanese Culture.md"
$enc  = [System.Text.Encoding]::UTF8

$bytes  = [System.IO.File]::ReadAllBytes($path)
$hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
$text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

# Use simple line split to check
$lines = $text -split "`n"
Write-Host "Total lines: $($lines.Count)"
Write-Host "Link lines:"
$links = $lines | Where-Object { $_.TrimEnd() -match '^- \[\[' }
$links | ForEach-Object { Write-Host "  [$_]" }
Write-Host "Total links: $($links.Count)"

# Check Arts & Culture section specifically
$inSection = $false
$sectionLinks = [System.Collections.Generic.List[string]]::new()
foreach ($l in $lines) {
    if ($l -match '^## Arts') { $inSection = $true; continue }
    if ($l -match '^## ' -and $inSection) { break }
    if ($inSection -and $l.TrimEnd() -match '^- \[\[') { $sectionLinks.Add($l) }
}
Write-Host "`nArts section links:"
$sectionLinks | ForEach-Object { Write-Host "  $_" }
$sorted = $sectionLinks | Sort-Object { $_ -replace '^- \[\[','' } -CaseSensitive:$false
Write-Host "Sorted:"
$sorted | ForEach-Object { Write-Host "  $_" }
Write-Host "Same? $(($sectionLinks -join '') -eq ($sorted -join ''))"
