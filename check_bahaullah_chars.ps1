# check_bahaullah_chars.ps1
# Finds the Daily Reading file and reports the Unicode codepoints of every character in its name

$vaultPath = "D:\Obsidian\Main"

$file = Get-ChildItem -Path $vaultPath -Recurse -Filter "*Daily Reading*" | Select-Object -First 1

if (-not $file) {
    Write-Host "File not found." -ForegroundColor Red
    exit
}

Write-Host "Found: $($file.FullName)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Character codepoints in filename:" -ForegroundColor Yellow

$name = $file.Name
for ($i = 0; $i -lt $name.Length; $i++) {
    $ch = $name[$i]
    $cp = [int][char]$ch
    $hex = "U+{0:X4}" -f $cp
    Write-Host ("  [{0,3}] '{1}'  {2}  (decimal {3})" -f $i, $ch, $hex, $cp)
}

Write-Host ""
Write-Host "Full path codepoints for non-ASCII chars:" -ForegroundColor Yellow
$path = $file.FullName
for ($i = 0; $i -lt $path.Length; $i++) {
    $ch = $path[$i]
    $cp = [int][char]$ch
    if ($cp -gt 127) {
        $hex = "U+{0:X4}" -f $cp
        Write-Host ("  [{0,3}] '{1}'  {2}  in context: ...{3}..." -f $i, $ch, $hex, $path.Substring([Math]::Max(0,$i-3), [Math]::Min(7, $path.Length-[Math]::Max(0,$i-3))))
    }
}
