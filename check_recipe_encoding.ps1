# Check exact character encoding in garbled recipe filenames vs MOC entries

$recMOC = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Recipes.md'
$recContent = Get-Content -LiteralPath $recMOC -Encoding UTF8 -Raw

# --- Soda Bread ---
Write-Output "=== Soda Bread ==="
$sodaFiles = Get-ChildItem 'D:\Obsidian\Main\01\Recipes' | Where-Object { $_.BaseName -like '*Soda Bread*Paddy*' }
foreach ($f in $sodaFiles) {
    $bn = $f.BaseName
    Write-Output "  BaseName: [$bn]"
    # Show hex of full basename
    $hexArr = @()
    for ($i=0; $i -lt $bn.Length; $i++) {
        $cp = [int][char]$bn[$i]
        if ($cp -gt 127 -or $cp -eq 39 -or $cp -eq 63) {
            $hexArr += "[$i]=U+$( '{0:X4}' -f $cp )"
        }
    }
    if ($hexArr) { Write-Output "  Notable chars: $($hexArr -join ', ')" }

    # Does MOC contain exact BaseName?
    $escaped = [regex]::Escape($bn)
    if ($recContent -match $escaped) {
        Write-Output "  MOC match: YES"
    } else {
        Write-Output "  MOC match: NO - checking MOC lines"
        $mocLine = ($recContent -split "`r`n|`n") | Where-Object { $_ -like '*Paddy*Da y*' }
        Write-Output "  MOC line: [$mocLine]"
        if ($mocLine) {
            # Show notable chars in MOC line
            $hexMoc = @()
            for ($i=0; $i -lt $mocLine.Length; $i++) {
                $cp = [int][char]$mocLine[$i]
                if ($cp -gt 127 -or $cp -eq 39 -or $cp -eq 63) {
                    $hexMoc += "[$i]=U+$( '{0:X4}' -f $cp )"
                }
            }
            if ($hexMoc) { Write-Output "  MOC notable chars: $($hexMoc -join ', ')" }
        }
    }
}

# --- Soto Ayam ---
Write-Output "`n=== Soto Ayam ==="
$sotoFiles = Get-ChildItem 'D:\Obsidian\Main\01\Recipes' | Where-Object { $_.BaseName -like '*Soto*' -or $_.BaseName -like '*Javanese*' }
foreach ($f in $sotoFiles) {
    $bn = $f.BaseName
    Write-Output "  BaseName: [$bn]"
    $hexArr = @()
    for ($i=0; $i -lt $bn.Length; $i++) {
        $cp = [int][char]$bn[$i]
        if ($cp -gt 127 -or $cp -eq 39 -or $cp -eq 63) {
            $hexArr += "[$i]=U+$( '{0:X4}' -f $cp )"
        }
    }
    if ($hexArr) { Write-Output "  Notable chars: $($hexArr -join ', ')" }

    $escaped = [regex]::Escape($bn)
    if ($recContent -match $escaped) {
        Write-Output "  MOC match: YES"
    } else {
        Write-Output "  MOC match: NO"
        $mocLine = ($recContent -split "`r`n|`n") | Where-Object { $_ -like '*Soto Aya*' }
        Write-Output "  MOC line: [$mocLine]"
        if ($mocLine) {
            $hexMoc = @()
            for ($i=0; $i -lt $mocLine.Length; $i++) {
                $cp = [int][char]$mocLine[$i]
                if ($cp -gt 127 -or $cp -eq 39 -or $cp -eq 63) {
                    $hexMoc += "[$i]=U+$( '{0:X4}' -f $cp )"
                }
            }
            if ($hexMoc) { Write-Output "  MOC notable chars: $($hexMoc -join ', ')" }
        }
    }
}
