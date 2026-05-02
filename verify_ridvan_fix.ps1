# Verify the Ridvan -> Ridvan rename results and check ajson file locations

$vault = 'D:\Obsidian\Main'
$dotD   = [char]0x1E0D
$aAcute = [char]0x00E1

# 1. Verify renamed .md files exist with correct names
Write-Output "=== Renamed .md files (should show dotted-d) ==="
Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.Name -match [regex]::Escape("Ri$($dotD)v")
} | ForEach-Object {
    Write-Output "  OK: $($_.Name)"
}

# 2. Check .ajson file locations
Write-Output "`n=== Renamed .ajson files and their paths ==="
Get-ChildItem $vault -Recurse -Filter '*.ajson' | Where-Object {
    $_.Name -match [regex]::Escape("Ri$($dotD)v") -or $_.Name -like '*Ridv*'
} | ForEach-Object {
    Write-Output "  Path: $($_.FullName)"
}

# 3. Check if any .md files still have incorrect spelling
Write-Output "`n=== Any remaining incorrect Ridvan spellings (should be 0) ==="
$remaining = 0
Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.FullName -notlike '*\.obsidian\*' -and $_.FullName -notlike '*\.trash\*'
} | ForEach-Object {
    $c = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if ($c -and ($c -cmatch "Ridv[$aAcute`a]n")) {
        $m = [regex]::Matches($c, "Ridv[$aAcute`a]n")
        Write-Output "  STILL BAD [$($m.Count)x]: $($_.FullName)"
        $remaining += $m.Count
    }
}
if ($remaining -eq 0) { Write-Output "  None remaining - all fixed!" }

# 4. Sample check: verify dotted-d in a replaced file
Write-Output "`n=== Sample verification (Bahá'í Faith MOC - Ridvan heading) ==="
$bahai = Get-ChildItem "$vault\00 - Home Dashboard" | Where-Object { $_.Name -like 'MOC - Bah*Faith*' } | Select-Object -First 1
if ($bahai) {
    $lines = Get-Content -LiteralPath $bahai.FullName -Encoding UTF8
    $lines | Where-Object { $_ -imatch 'ridv' } | Select-Object -First 5 | ForEach-Object {
        # Show hex of d-position character
        $idx = $_.IndexOf('idv')
        if ($idx -ge 0) {
            $dChar = $_.[$idx + 2]  # wait, d is at idx+0 in 'idv', but we want d after i
            # Actually d is at position idx+1 (i=idx, d=idx+1, v=idx+2)
        }
        Write-Output "  [$_]"
        # Show code point of the 'd' in Ridvan
        $ridIdx = $_.ToLower().IndexOf('ridv')
        if ($ridIdx -ge 0) {
            $dCode = [int][char]$_.[$ridIdx + 2]  # d is at ridIdx+2 (R=0,i=1,d=2,v=3)
            Write-Output "    d-char U+$( '{0:X4}' -f $dCode ) (want U+1E0D)"
        }
    }
}
