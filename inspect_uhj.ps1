# inspect_uhj.ps1
# Diagnose encoding and character patterns in the UHJ Nine Year Plan note
# before making any changes.

$filePath = 'D:\Obsidian\Main\11 - Review\UHJ Nine Year Plan 2022-2031.md'

# Read raw bytes and also as UTF-8 text
$raw  = [System.IO.File]::ReadAllBytes($filePath)
$text = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# -----------------------------------------------------------------------
# SECTION 1: Byte inspection — find 'Bah' and show the bytes that follow
# -----------------------------------------------------------------------
Write-Host '=== BYTES IMMEDIATELY AFTER FIRST "Bah" OCCURRENCE ==='
$searchBytes = [byte[]](0x42, 0x61, 0x68)  # B, a, h
for ($i = 0; $i -lt ($raw.Count - 12); $i++) {
    if ($raw[$i] -eq $searchBytes[0] -and $raw[$i+1] -eq $searchBytes[1] -and $raw[$i+2] -eq $searchBytes[2]) {
        $snippet = $raw[($i+3)..($i+12)] | ForEach-Object { '0x{0:X2}' -f $_ }
        Write-Host "  Byte offset $i : Bah + [ $($snippet -join '  ') ]"
        break
    }
}

# -----------------------------------------------------------------------
# SECTION 2: Catalog every unique non-ASCII character with its count
# -----------------------------------------------------------------------
Write-Host ''
Write-Host '=== ALL UNIQUE NON-ASCII CHARACTERS FOUND IN FILE ==='
$charMap = @{}
foreach ($c in $text.ToCharArray()) {
    $cp = [int]$c
    if ($cp -gt 127) {
        $key = 'U+{0:X4}  char=[{1}]' -f $cp, $c
        if (-not $charMap.ContainsKey($key)) { $charMap[$key] = 0 }
        $charMap[$key]++
    }
}
$charMap.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0}   count={1}" -f $_.Name, $_.Value)
}

# -----------------------------------------------------------------------
# SECTION 3: Show every line that contains a non-ASCII character,
#             with its line number, so we can see context
# -----------------------------------------------------------------------
Write-Host ''
Write-Host '=== LINES CONTAINING NON-ASCII CHARACTERS (line# : content) ==='
$lines = $text -split "`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    $hasNonAscii = $false
    foreach ($c in $lines[$i].ToCharArray()) {
        if ([int]$c -gt 127) { $hasNonAscii = $true; break }
    }
    if ($hasNonAscii) {
        Write-Host ("  Line {0,4}:  {1}" -f ($i+1), $lines[$i])
    }
}
