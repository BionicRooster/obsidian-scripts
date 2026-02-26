# debug_allwords.ps1
# Test Find-AllWords for broken link names in Recipes MOC

$vaultPath = "D:\Obsidian\Main"

# Build index
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

function Find-AllWords($target) {
    $words = ($target -split '[\s\-_,\.]+') | Where-Object { $_.Length -ge 4 } |
             ForEach-Object { $_.ToLower() }
    if ($words.Count -eq 0) { return @() }
    Write-Host "    Words: $($words -join ', ')"
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $byBasename.Keys) {
        $match = $true
        foreach ($w in $words) {
            if (-not $key.Contains($w)) { $match = $false; break }
        }
        if ($match) { $hits.AddRange($byBasename[$key]) }
    }
    return $hits
}

# Test the broken links that showed "Updated -> D"
$testLinks = @(
    "Black Bean Stew",
    "Asian noodle soup wi",
    "Curried Apple Daal S",
    "Lentil Chili",
    "Curried Millet Cakes",
    "Spaghetti with White",
    "Easy Quinoa Tabboule",
    "Romano's Macaroni Gr",
    "Homemade Corn Tortil",
    "Sweet Potato Cassava"
)

foreach ($link in $testLinks) {
    Write-Host "`n=== '$link' ==="
    $sw = Find-StartsWith $link
    Write-Host "StartsWith count: $($sw.Count)"
    if ($sw.Count -eq 1) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($sw[0])
        Write-Host "  -> Would update to: $base"
    } elseif ($sw.Count -gt 1) {
        Write-Host "  -> Ambiguous SW, trying AllWords..."
        $aw = Find-AllWords $link
        Write-Host "  AllWords count: $($aw.Count)"
        if ($aw.Count -eq 1) {
            $base = [System.IO.Path]::GetFileNameWithoutExtension($aw[0])
            Write-Host "  -> Would update to: $base"
        }
    } else {
        Write-Host "  -> No SW match, trying AllWords..."
        $aw = Find-AllWords $link
        Write-Host "  AllWords count: $($aw.Count)"
        if ($aw.Count -eq 1) {
            $base = [System.IO.Path]::GetFileNameWithoutExtension($aw[0])
            Write-Host "  -> Would update to: $base"
        } elseif ($aw.Count -gt 1) {
            Write-Host "  -> Ambiguous AW: $($aw.Count) hits"
            foreach ($h in $aw) { Write-Host "     $h" }
        } else {
            Write-Host "  -> NOT FOUND"
        }
    }
}
