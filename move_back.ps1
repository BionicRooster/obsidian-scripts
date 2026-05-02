# Move files from flat NLP folder back to NLP Master Class subfolder
$flatDir = 'D:\Obsidian\Main\01\NLP'
$destDir = 'D:\Obsidian\Main\01\NLP\NLP Master Class'

$toMove = @(
    'NLP - Change of Experience.md',
    'NLP Change Personal History.md',
    'NLP CompuServe Library Catalog.md',
    'NLP in Training.md',
    'NLP Master Class Week 1.md',
    'NLP Master Class Week 2.md',
    'NLP Master Class Week 3.md',
    'NLP Six-Step Reframe.md'
)

foreach ($name in $toMove) {
    $src = Join-Path $flatDir $name
    $dst = Join-Path $destDir $name

    if (-not (Test-Path $src)) {
        Write-Host "SKIP (not in flat): $name"
        continue
    }

    if (Test-Path $dst) {
        $srcContent = Get-Content $src -Encoding UTF8 -Raw
        $dstContent = Get-Content $dst -Encoding UTF8 -Raw
        if ($srcContent -eq $dstContent) {
            Remove-Item $src
            Write-Host "DELETED flat duplicate (identical): $name"
        } else {
            Remove-Item $src
            Write-Host "DELETED flat version (NLC copy kept, content differed): $name"
        }
    } else {
        Move-Item -Path $src -Destination $dst
        Write-Host "MOVED to NLC: $name"
    }
}

Write-Host ""
Write-Host "Done. NLC contents:"
Get-ChildItem -Path $destDir -File | Select-Object -ExpandProperty Name | Sort-Object
