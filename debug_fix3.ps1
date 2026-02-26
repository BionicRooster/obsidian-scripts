# debug_fix3.ps1 - verify @() wrapping fix

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

# Without @() wrapping (OLD BUG)
$sw_old = Find-StartsWith "Asian noodle soup wi"
Write-Host "=== WITHOUT @() wrapping ==="
Write-Host "Type: $($sw_old.GetType().Name)"
Write-Host "Count: $($sw_old.Count)"
Write-Host "sw_old[0] type: $($sw_old[0].GetType().Name) value: '$($sw_old[0])'"

# With @() wrapping (FIXED)
$sw_new = @(Find-StartsWith "Asian noodle soup wi")
Write-Host "`n=== WITH @() wrapping ==="
Write-Host "Type: $($sw_new.GetType().Name)"
Write-Host "Count: $($sw_new.Count)"
Write-Host "sw_new[0] type: $($sw_new[0].GetType().Name) value: '$($sw_new[0])'"
$base = [System.IO.Path]::GetFileNameWithoutExtension($sw_new[0])
Write-Host "GetFileNameWithoutExtension: '$base'"
