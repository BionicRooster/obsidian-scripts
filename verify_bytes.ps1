# verify_bytes.ps1
# Verify the actual UTF-8 bytes for Bahá'í in the description line

$path = "D:\Obsidian\Main\2010 Personal Calendar Summary.md"
$bytes = [System.IO.File]::ReadAllBytes($path)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
$lines = $text -split "`n"

# Find the description line
$descLine = $lines | Where-Object { $_ -match '^description:' } | Select-Object -First 1

# Find "Bah" in the description and show the next 12 bytes
$idx = $descLine.IndexOf("Bah")
if ($idx -ge 0) {
    $slice = $descLine.Substring($idx, [Math]::Min(12, $descLine.Length - $idx))
    $sliceBytes = [System.Text.Encoding]::UTF8.GetBytes($slice)
    $hex = ($sliceBytes | ForEach-Object { $_.ToString('X2') }) -join ' '
    Write-Output "Hex of 'Bah...': $hex"
    # Expected: 42 61 68 C3 A1 27 C3 AD = Bahá'í (apostrophe=27, á=C3A1, í=C3AD)
    # C3 A1 = á (U+00E1) GOOD
    # E2 80 99 = ' (curly apostrophe U+2019)
    # C3 AD = í (U+00ED) GOOD
}
