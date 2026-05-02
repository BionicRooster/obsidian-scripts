# Check and fix remaining Ridvan issues

$vault   = 'D:\Obsidian\Main'
$dotD    = [char]0x1E0D
$aAcute  = [char]0x00E1

# ------- Check actual MOC content for any remaining Ridvan -------
Write-Output "=== Lines in MOC Baha'i Faith with Ridvan (wrong d) ==="
$bahai = Get-ChildItem "$vault\00 - Home Dashboard" |
         Where-Object { $_.Name -like 'MOC - Bah*Faith*' } | Select-Object -First 1
$mocContent = Get-Content -LiteralPath $bahai.FullName -Encoding UTF8 -Raw
$mocLines = $mocContent -split "`r`n|`n"
$badLines = $mocLines | Where-Object {
    # Has 'ridv' with ASCII d (U+0064) - check byte by byte
    $lc = $_.ToLower()
    $idx = $lc.IndexOf('ridv')
    if ($idx -ge 0) {
        [int][char]$_[$idx + 2] -eq 0x0064   # d = U+0064
    } else { $false }
}
$badLines | ForEach-Object { Write-Output "  [$_]" }

# ------- Check if those files still exist with old names -------
Write-Output "`n=== Files still named Ridvan (without dotted d) ==="
Get-ChildItem "$vault\01" -Recurse -Filter '*.md' | Where-Object {
    $_.BaseName -match 'Ridvan' -or $_.BaseName -match "Ridv$aAcute`n"
} | Where-Object {
    # Only those where d is still ASCII (not dotted)
    $name = $_.BaseName
    $idx = $name.ToLower().IndexOf('ridv')
    if ($idx -ge 0) { [int][char]$name[$idx + 2] -eq 0x0064 } else { $false }
} | ForEach-Object {
    Write-Output "  $($_.FullName)"
}

# ------- Fix: apply the replacement to those specific files -------
Write-Output "`n=== Applying targeted fix to MOC and any remaining files ==="

# Fix MOC content
$fixed = $mocContent
# Replace Ridvan (plain a, no accent) wikilinks
$fixed = [regex]::Replace($fixed, "Ridvan", "Ri$($dotD)v$($aAcute)n")
# Replace any Ridvan (with accent already) that still has plain d
$fixed = [regex]::Replace($fixed, "Ridv$($aAcute)n", "Ri$($dotD)v$($aAcute)n")
if ($fixed -ne $mocContent) {
    Set-Content -LiteralPath $bahai.FullName -Value $fixed -Encoding UTF8 -NoNewline
    Write-Output "  Fixed MOC - Baha'i Faith.md"
}

# Fix any remaining .md files in vault
Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.FullName -notlike '*\.obsidian\*' -and $_.FullName -notlike '*\.trash\*'
} | ForEach-Object {
    $c = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if (-not $c) { return }
    $hasBadD = $c -cmatch "Ridv[a$aAcute]n"
    if ($hasBadD) {
        $fc = [regex]::Replace($c, "Ridvan", "Ri$($dotD)v$($aAcute)n")
        $fc = [regex]::Replace($fc, "Ridv$($aAcute)n", "Ri$($dotD)v$($aAcute)n")
        if ($fc -ne $c) {
            Set-Content -LiteralPath $_.FullName -Value $fc -Encoding UTF8 -NoNewline
            Write-Output "  Fixed: $($_.Name)"
        }
    }
}

# Rename any still-wrong filenames
Write-Output "`n=== Renaming remaining wrongly-named files ==="
Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.FullName -notlike '*\.obsidian\*' -and $_.FullName -notlike '*\.trash\*'
} | ForEach-Object {
    $name = $_.BaseName
    $idx = $name.ToLower().IndexOf('ridv')
    if ($idx -ge 0 -and [int][char]$name[$idx + 2] -eq 0x0064) {
        # Still has plain d - rename
        $newBase = [regex]::Replace($name, "Ridvan", "Ri$($dotD)v$($aAcute)n")
        $newBase = [regex]::Replace($newBase, "Ridv$($aAcute)n", "Ri$($dotD)v$($aAcute)n")
        $newFile = $newBase + '.md'
        $dir     = Split-Path $_.FullName -Parent
        $tmp     = Join-Path $dir ($newFile + '.tmp')
        $dest    = Join-Path $dir $newFile
        Rename-Item -LiteralPath $_.FullName -NewName ($newFile + '.tmp')
        Rename-Item -LiteralPath $tmp -NewName $newFile
        Write-Output "  Renamed: [$($_.Name)] -> [$newFile]"
    }
}

# Final count check
Write-Output "`n=== Final check: any remaining wrong d? ==="
$bad = 0
Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.FullName -notlike '*\.obsidian\*' -and $_.FullName -notlike '*\.trash\*'
} | ForEach-Object {
    $c = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if ($c -and ($c -cmatch "Ridv[a$aAcute]n")) { $bad++ }
}
Write-Output "  Files with remaining wrong d: $bad"
