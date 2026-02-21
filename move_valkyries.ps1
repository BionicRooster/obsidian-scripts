# Fix filename (remove trailing comma) and move to 01\Social
$vault = "D:\Obsidian\Main"
$src = Join-Path $vault "Origin and myths of the Valkyries,.md"
$dst = Join-Path $vault "01\Social\Origin and Myths of the Valkyries.md"

if (Test-Path $src) {
    Move-Item $src $dst -Force
    Write-Host "Moved and renamed: Origin and myths of the Valkyries, -> 01\Social\Origin and Myths of the Valkyries.md"
} else {
    Write-Host "Not found: $src"
}
