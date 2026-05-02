# check_lsa_chars.ps1
# Verify diacritical bytes in BE161.md

$filePath = 'D:\Obsidian\Main\LSA\Year in Review\BE161.md'
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
$titleLine = ($text -split "`n")[1]

# Find "Bah" in title and show surrounding bytes
$idx = $titleLine.IndexOf("Bah")
if ($idx -ge 0) {
    $slice = $titleLine.Substring($idx, [Math]::Min(12, $titleLine.Length - $idx))
    $sliceBytes = [System.Text.Encoding]::UTF8.GetBytes($slice)
    $hex = ($sliceBytes | ForEach-Object { $_.ToString('X2') }) -join ' '
    Write-Output "Hex of 'Bah...': $hex"
    # Expected: 42 61 68 C3 A1 27 C3 AD 73 = Bahá'ís
    # C3 A1 = á (U+00E1)
    # C3 AD = í (U+00ED)
}
