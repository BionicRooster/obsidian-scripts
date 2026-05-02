# Fix Recipes MOC run-together (space-separated items) and garbled recipe filenames

$recMOC = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Recipes.md'
$recDir  = 'D:\Obsidian\Main\01\Recipes'

# -------------------------------------------------------------------
# 1. Fix Recipes MOC: items separated by "]] - [[" on same line
# -------------------------------------------------------------------
Write-Output "=== Fix Recipes MOC run-together ==="
$recContent = Get-Content -LiteralPath $recMOC -Encoding UTF8 -Raw
# Pattern: ]] followed by optional spaces, then - [[ (list item on same line)
$before = $recContent.Length
$fixed = $recContent -replace '\]\]\s*-\s*\[\[', "]]`n- [["
# Also fix ]]## patterns
$fixed = $fixed -replace '(\]\])(#{1,3} )', "`$1`n`$2"
if ($fixed -ne $recContent) {
    Set-Content -LiteralPath $recMOC -Value $fixed -Encoding UTF8 -NoNewline
    $after = $fixed.Length
    Write-Output "  Applied run-together fixes (length: $before -> $after)"
} else {
    Write-Output "  No run-together found"
}

# -------------------------------------------------------------------
# 2. Investigate garbled recipe files
# -------------------------------------------------------------------
Write-Output "`n=== Garbled recipe investigation ==="

# Soda Bread - show first 3 lines of file content
$sodaFiles = Get-ChildItem $recDir | Where-Object { $_.BaseName -match 'Paddy' -and $_.BaseName -match 'Da y' }
foreach ($f in $sodaFiles) {
    Write-Output "  File: [$($f.BaseName)]"
    $firstLines = Get-Content -LiteralPath $f.FullName -Encoding UTF8 -TotalCount 5
    $firstLines | ForEach-Object { Write-Output "    $_" }
    Write-Output "  ---"
}

# Soto - show first 3 lines
$sotoFiles = Get-ChildItem $recDir | Where-Object { $_.BaseName -match 'Soto Aya m' }
foreach ($f in $sotoFiles) {
    Write-Output "  File: [$($f.BaseName)]"
    $firstLines = Get-Content -LiteralPath $f.FullName -Encoding UTF8 -TotalCount 5
    $firstLines | ForEach-Object { Write-Output "    $_" }
    Write-Output "  ---"
}

# -------------------------------------------------------------------
# 3. Show what the MOC now looks like for these entries (after fix)
# -------------------------------------------------------------------
Write-Output "`n=== MOC entries after fix ==="
$recContent2 = Get-Content -LiteralPath $recMOC -Encoding UTF8 -Raw
$sodaMocLines = ($recContent2 -split "`r`n|`n") | Where-Object { $_ -like '*Paddy*' }
$sotoMocLines = ($recContent2 -split "`r`n|`n") | Where-Object { $_ -like '*Soto Aya*' -or $_ -like '*Javanese*Inspired*' }
Write-Output "  Soda Bread MOC entries:"
$sodaMocLines | ForEach-Object { Write-Output "    [$_]" }
Write-Output "  Soto MOC entries:"
$sotoMocLines | ForEach-Object { Write-Output "    [$_]" }
