$mocs = @(
    'D:\Obsidian\Main\00 - Home Dashboard\MOC - Science & Nature.md',
    'D:\Obsidian\Main\00 - Home Dashboard\MOC - Recipes.md',
    'D:\Obsidian\Main\00 - Home Dashboard\MOC - Health & Nutrition.md'
)
foreach ($moc in $mocs) {
    Write-Host "`n=== $([System.IO.Path]::GetFileNameWithoutExtension($moc)) ===" -ForegroundColor Cyan
    Get-Content $moc -Encoding UTF8 | Where-Object { $_ -match '^##' }
}
