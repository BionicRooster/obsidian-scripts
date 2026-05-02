$vault   = 'D:\Obsidian\Main'
$dotD    = [char]0x1E0D
$aAcute  = [char]0x00E1

# 1. Renamed .md files with correct dotted-d
Write-Output "=== Renamed .md files ==="
Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.Name.Contains($dotD)
} | ForEach-Object {
    Write-Output "  OK: $($_.Name)"
}

# 2. .ajson file locations
Write-Output "`n=== .ajson files containing dotted-d (where are they?) ==="
Get-ChildItem $vault -Recurse | Where-Object {
    $_.Extension -eq '.ajson' -and $_.Name.Contains($dotD)
} | Select-Object -First 5 | ForEach-Object {
    Write-Output "  $($_.FullName)"
}

# 3. Any remaining incorrect spellings
Write-Output "`n=== Remaining incorrect Ridvan spellings ==="
$remaining = 0
Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.FullName -notlike '*\.obsidian\*' -and $_.FullName -notlike '*\.trash\*'
} | ForEach-Object {
    $c = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if ($c) {
        $m = [regex]::Matches($c, "Ridv[$aAcute`a]n")
        if ($m.Count -gt 0) {
            Write-Output "  [$($m.Count)x] $($_.Name)"
            $remaining += $m.Count
        }
    }
}
if ($remaining -eq 0) { Write-Output "  None - all fixed!" } else { Write-Output "  Total remaining: $remaining" }

# 4. Verify the MOC heading
Write-Output "`n=== MOC Ridvan heading character check ==="
$bahai = Get-ChildItem "$vault\00 - Home Dashboard" | Where-Object { $_.Name -like 'MOC - Bah*Faith*' } | Select-Object -First 1
if ($bahai) {
    $lines = Get-Content -LiteralPath $bahai.FullName -Encoding UTF8
    $ridLines = $lines | Where-Object { $_ -imatch 'ridv' } | Select-Object -First 3
    foreach ($line in $ridLines) {
        Write-Output "  Line: [$line]"
        $ridIdx = $line.ToLower().IndexOf('ridv')
        if ($ridIdx -ge 0) {
            $dChar = $line[$ridIdx + 2]
            $dCode = [int][char]$dChar
            $status = if ($dCode -eq 0x1E0D) { 'CORRECT (U+1E0D dotted-d)' } else { "WRONG (U+$( '{0:X4}' -f $dCode ))" }
            Write-Output "    d-char: $status"
        }
    }
}
