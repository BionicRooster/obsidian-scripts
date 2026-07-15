# Check remaining unclassified items

# 1. Brian K. White - exact filename vs MOC link
Write-Output "=== Brian K. White ==="
$bkwFiles = Get-ChildItem 'C:\Users\awt\Sync\Obsidian\01\Technology' | Where-Object { $_.Name -like 'Brian K*' }
foreach ($f in $bkwFiles) {
    Write-Output "  File BaseName: [$($f.BaseName)]"
    # Hex of key chars
    $name = $f.BaseName
    $chars = @()
    for ($i=0; $i -lt [Math]::Min($name.Length,30); $i++) { $chars += [int][char]$name[$i] }
    Write-Output "  Hex(0-30): $($chars -join ',')"
}
$techMOC = 'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Technology & Computers.md'
$techContent = Get-Content -LiteralPath $techMOC -Encoding UTF8 -Raw
$bkwLine = ($techContent -split "`r`n|`n") | Where-Object { $_ -like '*Brian K*' }
Write-Output "  MOC line: [$bkwLine]"

# 2. IFTTT - exact filename vs MOC link
Write-Output "`n=== IFTTT Thankful ==="
$iftttFile = Get-ChildItem 'C:\Users\awt\Sync\Obsidian\01\Technology' | Where-Object { $_.Name -like '*IFTTT*Thankful*' }
foreach ($f in $iftttFile) {
    Write-Output "  File BaseName: [$($f.BaseName)]"
    $name = $f.BaseName
    # Show last 5 chars
    for ($i=[Math]::Max(0,$name.Length-5); $i -lt $name.Length; $i++) {
        Write-Output "  Char[$i]: U+$([int][char]$name[$i] | ForEach-Object { '{0:X4}' -f $_ }) = [$($name[$i])]"
    }
}
$iftttLine = ($techContent -split "`r`n|`n") | Where-Object { $_ -like '*IFTTT*Thankful*' }
Write-Output "  MOC line: [$iftttLine]"
if ($iftttLine) {
    $chars = @()
    for ($i=0; $i -lt $iftttLine.Length; $i++) {
        if ([int][char]$iftttLine[$i] -gt 127 -or [int][char]$iftttLine[$i] -eq 39 -or [int][char]$iftttLine[$i] -eq 8217) {
            Write-Output "  Notable char[$i] U+$([int][char]$iftttLine[$i] | ForEach-Object { '{0:X4}' -f $_ })"
        }
    }
}

# 3. Garbled recipe files - show exact names and hex
Write-Output "`n=== Garbled recipes ==="
$garbled = Get-ChildItem 'C:\Users\awt\Sync\Obsidian\01\Recipes' | Where-Object { $_.Name -match '\?' }
foreach ($f in $garbled) {
    Write-Output "  [$($f.Name)]"
}
# Also check recipes MOC for these titles
$recMOC = 'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Recipes.md'
$recContent = Get-Content -LiteralPath $recMOC -Encoding UTF8 -Raw
$sodaLine = ($recContent -split "`r`n|`n") | Where-Object { $_ -like '*Soda Bread*' -or $_ -like '*Paddy*' }
$sotoLine = ($recContent -split "`r`n|`n") | Where-Object { $_ -like '*Soto*' -or $_ -like '*Javanese*' }
Write-Output "  Recipes MOC - Soda Bread line: [$sodaLine]"
Write-Output "  Recipes MOC - Soto line: [$sotoLine]"

# 4. 16 - Organizations.md - first few lines
Write-Output "`n=== 16 - Organizations.md ==="
$orgContent = Get-Content -LiteralPath 'C:\Users\awt\Sync\Obsidian\16 - Organizations\16 - Organizations.md' -Encoding UTF8 -TotalCount 5
$orgContent | ForEach-Object { Write-Output "  $_" }

# 5. Link Recommendations file
Write-Output "`n=== Link Recommendations ==="
$lrPath = 'C:\Users\awt\Sync\Obsidian\01\NLP\Link Recommendations for 10 Additional Obsidian Notes Batch 2.md'
if (Test-Path -LiteralPath $lrPath) {
    Write-Output "  EXISTS - first line:"
    $lr = Get-Content -LiteralPath $lrPath -Encoding UTF8 -TotalCount 1
    Write-Output "  $lr"
}
