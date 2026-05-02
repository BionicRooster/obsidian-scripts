# check_lsa_em_dash.ps1
# Verify what character is used after "TX " in BE161.md title line

$filePath = 'D:\Obsidian\Main\LSA\Year in Review\BE161.md'
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
$titleLine = ($text -split "`n")[1]

Write-Output "Title line: $titleLine"

# Find the separator after "TX "
$idx = $titleLine.IndexOf("TX ")
if ($idx -ge 0) {
    $slice = $titleLine.Substring($idx, [Math]::Min(10, $titleLine.Length - $idx))
    $sliceBytes = [System.Text.Encoding]::UTF8.GetBytes($slice)
    $hex = ($sliceBytes | ForEach-Object { $_.ToString('X2') }) -join ' '
    Write-Output "Hex after 'TX ': $hex"
    # E2 80 94 = em dash (U+2014)
    # 2D = hyphen-minus
    # 75 7B 32 30 31 34 7D = u{2014} (literal text)
}
