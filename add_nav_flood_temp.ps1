# Add nav property to the cataclysmic flood file
$folder = 'D:\Obsidian\Main\10 - Clippings'
$file = Get-ChildItem $folder | Where-Object { $_.Name -match "cataclysmic" } | Select-Object -First 1
if ($file) {
    $content = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav after the tags block
    $content = $content -replace '(tags:\r?\n  - Geology\r?\n  - Megaflood\r?\n  - Climatology\r?\n---)', "tags:`n  - Geology`n  - Megaflood`n  - Climatology`nnav: `"[[MOC - Science & Nature]]`"`n---"
    Set-Content -LiteralPath $file.FullName -Value $content -Encoding UTF8
    Write-Host "Updated: $($file.Name)"
} else {
    Write-Host "File not found"
}
