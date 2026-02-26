$mocs = @(
    'D:\Obsidian\Main\00 - Home Dashboard\MOC - Social Issues.md',
    'D:\Obsidian\Main\00 - Home Dashboard\MOC - Home & Practical Life.md',
    'D:\Obsidian\Main\00 - Home Dashboard\MOC - Music & Record.md',
    "D:\Obsidian\Main\00 - Home Dashboard\MOC - Bah\u00e1'\u00ed Faith.md"
)
foreach ($path in $mocs) {
    $lines = Get-Content $path -Encoding UTF8 | Where-Object { $_ -match '^\- \[\[' }
    $dupes = $lines | Group-Object | Where-Object { $_.Count -gt 1 }
    $name = Split-Path $path -Leaf
    if ($dupes) {
        Write-Output "DUPES in $name :"
        $dupes | ForEach-Object { Write-Output "  ($($_.Count)x) $($_.Name)" }
    } else {
        Write-Output "Clean: $name"
    }
}
