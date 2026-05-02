$techMOC = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Technology & Computers.md'
$content = Get-Content -LiteralPath $techMOC -Encoding UTF8 -Raw
$fixed = $content -replace '(\[\[Stellar Repair for Access\]\])(##)', "`$1`n`$2"
if ($fixed -ne $content) {
    Set-Content -LiteralPath $techMOC -Value $fixed -Encoding UTF8 -NoNewline
    Write-Output "Fixed run-together after Stellar Repair for Access"
} else {
    Write-Output "No fix needed (already correct or pattern not found)"
}
# Verify result
$check = Get-Content -LiteralPath $techMOC -Encoding UTF8 -Raw
if ($check -match 'Stellar Repair for Access\]\]\r?\n##') {
    Write-Output "Confirmed: newline now present before ##"
} else {
    Write-Output "WARNING: still run-together or not found"
}
