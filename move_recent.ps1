# Move recently classified files to 01 subdirectories
$vault = "D:\Obsidian\Main"

# GCCMA Black Author Panel -> 01\Social (alongside GCCMA Overview.md)
$src1 = Join-Path $vault "10 - Clippings\GCCMA Black Author Panel.md"
$dst1 = Join-Path $vault "01\Social\GCCMA Black Author Panel.md"
if (Test-Path $src1) {
    Move-Item $src1 $dst1 -Force
    Write-Host "Moved: GCCMA Black Author Panel -> 01\Social"
} else {
    Write-Host "Not found: $src1"
}

# Little V. Llano County -> 01\Social
$src2 = Join-Path $vault "10 - Clippings\Little V. Llano County Legalized Library Censorship. What Exactly Does This Mean Book Censorship News, February 13, 2026.md"
$dst2 = Join-Path $vault "01\Social\Little V. Llano County Legalized Library Censorship. What Exactly Does This Mean Book Censorship News, February 13, 2026.md"
if (Test-Path $src2) {
    Move-Item $src2 $dst2 -Force
    Write-Host "Moved: Little V. Llano County -> 01\Social"
} else {
    Write-Host "Not found: $src2"
}
