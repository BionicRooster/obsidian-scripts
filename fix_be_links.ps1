# Update [[Be1xx]] -> [[BE1xx]] wikilinks in People Index and 15-People files

$vault = 'D:\Obsidian\Main'

# Collect all files to update
$candidates = @()
$candidates += Join-Path $vault 'People Index.md'
Get-ChildItem (Join-Path $vault '15 - People') -Filter '*.md' | ForEach-Object {
    $candidates += $_.FullName
}

$totalUpdated = 0
foreach ($filePath in $candidates) {
    if (-not (Test-Path -LiteralPath $filePath)) { continue }
    $c = Get-Content -LiteralPath $filePath -Encoding UTF8 -Raw
    # Case-sensitive match: [[Be followed by digit
    if ($c -cmatch '\[\[Be\d') {
        $count = ([regex]::Matches($c, '\[\[Be\d')).Count
        $fixed = $c -replace '\[\[Be(\d)', '[[BE$1'
        Set-Content -LiteralPath $filePath -Value $fixed -Encoding UTF8 -NoNewline
        Write-Output "  Fixed $count link(s) in: $(Split-Path $filePath -Leaf)"
        $totalUpdated += $count
    }
}
Write-Output "`nTotal links updated: $totalUpdated"
