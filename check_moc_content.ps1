$paths = @(
    'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Science & Nature.md',
    'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Recipes.md',
    'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Technology & Computers.md'
)
foreach ($p in $paths) {
    $name = [System.IO.Path]::GetFileName($p)
    $bytes = (Get-Item $p).Length
    $lines = (Get-Content $p -Encoding UTF8 -ErrorAction SilentlyContinue).Count
    Write-Host "$name : $bytes bytes, $lines lines"
    Get-Content $p -Encoding UTF8 -ErrorAction SilentlyContinue | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
}
