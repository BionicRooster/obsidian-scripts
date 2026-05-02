# Check exactly where 'nav:' appears in BE161.md

$yearDir = Get-ChildItem 'D:\Obsidian\Main\01' -Recurse -Directory |
           Where-Object { $_.Name -eq 'Year in Review' } | Select-Object -First 1
$f = Join-Path $yearDir.FullName 'BE161.md'
$lines = Get-Content -LiteralPath $f -Encoding UTF8
$lineNum = 0
foreach ($line in $lines) {
    $lineNum++
    if ($line -match '^nav:' -or $line -match 'nav:') {
        Write-Output "Line $lineNum`: [$line]"
    }
    if ($lineNum -le 15) {
        Write-Output "  [$lineNum] $line"
    }
}
Write-Output "Total lines: $lineNum"
