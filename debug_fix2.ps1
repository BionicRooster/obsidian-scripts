# debug_fix2.ps1
# Trace exactly what happens for specific broken links in fix_moc_links.ps1

$vaultPath = "D:\Obsidian\Main"
$enc       = [System.Text.Encoding]::UTF8

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
Write-Host "Index: $($byBasename.Count) keys"

function Find-StartsWith($prefix) {
    $p    = $prefix.ToLower()
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $byBasename.Keys) {
        if ($key.StartsWith($p)) { $hits.AddRange($byBasename[$key]) }
    }
    return $hits
}

# Test one specific case: "Asian noodle soup wi"
$testLink = "Asian noodle soup wi"
Write-Host "`n=== Testing: [[$testLink]] ==="
$sw = Find-StartsWith $testLink
Write-Host "Find-StartsWith count: $($sw.Count)"
foreach ($hit in $sw) {
    Write-Host "  Hit: $hit"
    $nb = [System.IO.Path]::GetFileNameWithoutExtension($hit)
    Write-Host "  GetFileNameWithoutExtension: '$nb'"
    $repl = "[[$nb]]"
    Write-Host "  Would replace with: $repl"
}

# Simulate the full loop with the Recipes MOC
$recipesFile = "D:\Obsidian\Main\00 - Home Dashboard\MOC - Recipes.md"
$bytes  = [System.IO.File]::ReadAllBytes($recipesFile)
$hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
$text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

Write-Host "`n=== Scanning Recipes MOC for [[Asian noodle ==="
$idx = $text.IndexOf("[[Asian noodle")
if ($idx -ge 0) {
    Write-Host "Found at index $idx"
    Write-Host "Context: '$($text.Substring([Math]::Max(0,$idx-5), [Math]::Min(60, $text.Length-$idx+5)))'"
} else {
    Write-Host "NOT FOUND in text!"
    # Check case-insensitive
    $ltext = $text.ToLower()
    $idx2 = $ltext.IndexOf("[[asian noodle")
    if ($idx2 -ge 0) {
        Write-Host "Found case-insensitive at index $idx2"
        Write-Host "Context: '$($text.Substring([Math]::Max(0,$idx2-5), [Math]::Min(60, $text.Length-$idx2+5)))'"
    } else {
        Write-Host "Not found case-insensitively either!"
    }
}

# Simulate what replace would do
$testOld = "[[Asian noodle soup wi]]"
$testNew = "[[Asian Noodle Soup with Mini Portabellas]]"
if ($text.Contains($testOld)) {
    Write-Host "Old string found in text"
} else {
    Write-Host "Old string NOT in text (already replaced or different content)"
}
