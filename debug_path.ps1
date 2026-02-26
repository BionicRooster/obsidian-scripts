# debug_path.ps1 - show actual path returned by Find-StartsWith

$vaultPath = "D:\Obsidian\Main"
$allFiles   = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md"
$byBasename = @{}
foreach ($f in $allFiles) {
    $key = $f.BaseName.ToLower()
    if (-not $byBasename.ContainsKey($key)) {
        $byBasename[$key] = [System.Collections.Generic.List[string]]::new()
    }
    $byBasename[$key].Add($f.FullName)
}

function Find-StartsWith($prefix) {
    $p    = $prefix.ToLower()
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $byBasename.Keys) {
        if ($key.StartsWith($p)) { $hits.AddRange($byBasename[$key]) }
    }
    return $hits
}

$sw = Find-StartsWith "Asian noodle soup wi"
Write-Host "Count: $($sw.Count)"
Write-Host "sw[0] type: $($sw[0].GetType().FullName)"
Write-Host "sw[0] value: '$($sw[0])'"
Write-Host "sw[0] length: $($sw[0].Length)"
$base = [System.IO.Path]::GetFileNameWithoutExtension($sw[0])
Write-Host "GetFileNameWithoutExtension: '$base'"

# Print each character
Write-Host "Characters in sw[0]:"
for ($i = 0; $i -lt [Math]::Min(10, $sw[0].Length); $i++) {
    $c = $sw[0][$i]
    Write-Host "  [$i] = '$c' (U+$([int][char]$c).ToString('X4'))"
}
