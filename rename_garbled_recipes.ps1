# Rename garbled recipe files: replace Windows-1252 smart-quote chars with clean equivalents
# U+0092 = right single quote (use straight apostrophe ')
# U+0093 = left double quote, U+0094 = right double quote (remove from filename)
# Also fix spurious space in "Da y" -> "Day", "Aya m" -> "Aya m" (keep for now - it's in content)

$ErrorActionPreference = 'Stop'
$recDir = 'D:\Obsidian\Main\01\Recipes'
$recMOC = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Recipes.md'

$u0092 = [char]0x0092  # Windows-1252 right single quote
$u0093 = [char]0x0093  # Windows-1252 left double quote
$u0094 = [char]0x0094  # Windows-1252 right double quote

# --- Soda Bread ---
Write-Output "=== Soda Bread ==="
$sodaFile = Get-ChildItem $recDir | Where-Object { $_.BaseName -like '*Paddy*Da y*' } | Select-Object -First 1
if ($sodaFile) {
    $oldBase = $sodaFile.BaseName
    # Replace U+0092 with straight apostrophe, fix "Da y" -> "Day"
    $newBase = $oldBase -replace [char]0x0092, "'" -replace 'Da y', 'Day'
    $newPath = Join-Path $recDir ($newBase + '.md')
    Write-Output "  Old: [$oldBase]"
    Write-Output "  New: [$newBase]"
    if (Test-Path -LiteralPath $newPath) {
        Write-Output "  WARNING: Target already exists - skipping rename"
    } else {
        Rename-Item -LiteralPath $sodaFile.FullName -NewName ($newBase + '.md')
        Write-Output "  Renamed successfully"
    }

    # Update MOC: replace all variants with garbled chars to the clean name
    $recContent = Get-Content -LiteralPath $recMOC -Encoding UTF8 -Raw
    # Remove all garbled-variant lines (U+0092 version and "Da y" version without apostrophe)
    $lines = $recContent -split "`r`n|`n"
    $cleaned = @()
    $added = $false
    foreach ($line in $lines) {
        # Skip lines with garbled soda bread variants
        if ($line -like "*Paddy$($u0092)*Da y*" -or $line -like "*Paddys Da y*") {
            Write-Output "  Removing MOC line: [$line]"
            if (-not $added) {
                $cleaned += "- [[$newBase]]"
                $added = $true
                Write-Output "  Added clean entry: [[${newBase}]]"
            }
        } else {
            $cleaned += $line
        }
    }
    Set-Content -LiteralPath $recMOC -Value ($cleaned -join "`n") -Encoding UTF8 -NoNewline
    Write-Output "  MOC updated"
} else {
    Write-Output "  Soda Bread garbled file not found"
}

# --- Soto Ayam ---
Write-Output "`n=== Soto Ayam ==="
$sotoFile = Get-ChildItem $recDir | Where-Object { $_.BaseName -like '*Soto Aya m*' -and ($_.BaseName -like "*$($u0093)*" -or $_.BaseName -like "*Inspired *Chicken*") } | Select-Object -First 1
if (-not $sotoFile) {
    # Try broader search
    $sotoFile = Get-ChildItem $recDir | Where-Object { $_.BaseName.Contains($u0093) } | Select-Object -First 1
}
if ($sotoFile) {
    $oldBase = $sotoFile.BaseName
    # Remove U+0093 and U+0094 (curly double quotes around "Chicken")
    $newBase = $oldBase -replace [char]0x0093, '' -replace [char]0x0094, ''
    # Clean up double spaces
    while ($newBase -match '  ') { $newBase = $newBase -replace '  ', ' ' }
    $newBase = $newBase.Trim()
    $newPath = Join-Path $recDir ($newBase + '.md')
    Write-Output "  Old: [$oldBase]"
    Write-Output "  New: [$newBase]"
    if (Test-Path -LiteralPath $newPath) {
        Write-Output "  WARNING: Target already exists - skipping rename, using existing"
        $newBase = $sotoFile.BaseName  # keep old name for MOC update
    } else {
        Rename-Item -LiteralPath $sotoFile.FullName -NewName ($newBase + '.md')
        Write-Output "  Renamed successfully"
    }

    # Update MOC: replace garbled variant
    $recContent2 = Get-Content -LiteralPath $recMOC -Encoding UTF8 -Raw
    $lines2 = $recContent2 -split "`r`n|`n"
    $cleaned2 = @()
    $added2 = $false
    foreach ($line in $lines2) {
        if ($line.Contains($u0093) -or $line.Contains($u0094)) {
            Write-Output "  Removing garbled MOC line: [$line]"
            if (-not $added2) {
                $cleaned2 += "- [[$newBase]]"
                $added2 = $true
                Write-Output "  Added clean entry: [[${newBase}]]"
            }
        } else {
            $cleaned2 += $line
        }
    }
    Set-Content -LiteralPath $recMOC -Value ($cleaned2 -join "`n") -Encoding UTF8 -NoNewline
    Write-Output "  MOC updated"
} else {
    Write-Output "  Soto garbled file not found"
}

Write-Output "`n=== Done ==="
