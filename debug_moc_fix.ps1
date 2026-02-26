# debug_moc_fix.ps1
# Debug why Find-StartsWith returns wrong results

$vaultPath = "D:\Obsidian\Main"

# Build index same as fix_moc_links.ps1
$allFiles   = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md"
$byBasename = @{}
foreach ($f in $allFiles) {
    $key = $f.BaseName.ToLower()
    if (-not $byBasename.ContainsKey($key)) {
        $byBasename[$key] = [System.Collections.Generic.List[string]]::new()
    }
    $byBasename[$key].Add($f.FullName)
}
Write-Host "Index built: $($byBasename.Count) keys"

# Test specific prefixes that showed "Updated -> D"
$testPrefixes = @(
    "Bryan Burrough HCAS",
    "FOL Organizational I",
    "Black Bean Stew",
    "Asian noodle soup wi",
    "Baker Creek Heirloom"
)

foreach ($prefix in $testPrefixes) {
    $p    = $prefix.ToLower()
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $byBasename.Keys) {
        if ($key.StartsWith($p)) { $hits.AddRange($byBasename[$key]) }
    }
    Write-Host "`nPrefix: '$prefix' -> $($hits.Count) hits"
    foreach ($h in $hits) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($h)
        Write-Host "  Path: $h"
        Write-Host "  Base: $base"
    }
}
