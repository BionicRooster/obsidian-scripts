$mocContent = Get-Content 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Social Issues.md' -Raw
$files = Get-ChildItem 'D:\Obsidian\Main\01\Social\*.md' | Select-Object -ExpandProperty BaseName
foreach ($file in $files) {
    if ($mocContent -notmatch [regex]::Escape($file)) {
        Write-Output $file
    }
}
