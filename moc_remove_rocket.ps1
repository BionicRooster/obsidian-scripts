# Remove 'How to Build a Rocket Stove Using Cement Blocks' from Science MOC
# (file has been moved to Home folder; it belongs in Home & Practical Life)
$sciPath = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Science & Nature.md'
$sciContent = Get-Content -LiteralPath $sciPath -Raw -Encoding UTF8

if ($sciContent -match '\[\[How to Build a Rocket Stove Using Cement Blocks\]\]') {
    $sciContent = $sciContent -replace "- \[\[How to Build a Rocket Stove Using Cement Blocks\]\]\r?\n", ""
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($sciContent)
    [System.IO.File]::WriteAllBytes($sciPath, $bytes)
    Write-Host "Removed Rocket Stove from Science MOC"
} else {
    Write-Host "Not found in Science MOC"
}
