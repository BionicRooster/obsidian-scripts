# Fix Kolam nav - simpler approach
$clippings = "D:\Obsidian\Main\10 - Clippings"
$files = Get-ChildItem -LiteralPath $clippings
Write-Host "Found files with Kolam in name:"
foreach ($f in $files) {
    if ($f.Name -like "*olam*") {
        Write-Host "  $($f.Name)"
        $c = Get-Content -LiteralPath $f.FullName -Encoding UTF8 -Raw
        Write-Host "  Has nav: $($c -match '(?m)^nav:')"
        Write-Host "  First 200: $($c.Substring(0, [Math]::Min(200, $c.Length)))"
    }
}
