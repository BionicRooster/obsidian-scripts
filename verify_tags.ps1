$base = 'D:\Obsidian\Main\10 - Clippings'
$files = @(
    "'Anything that can be built can be taken down'.md",
    "Chasing Quicksilver History in Beautiful Big Bend.md",
    "The Prof's Book Alan.md",
    "Winxvideo AI receipt.md",
    "Statement by the Republic of Slovenia.md"
)
foreach ($fname in $files) {
    $f = Get-ChildItem "$base\$fname" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $f) { $f = Get-ChildItem "$base\$($fname.Substring(0,15))*" | Select-Object -First 1 }
    if ($f) {
        $lines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
        Write-Host "=== $($f.Name) ==="
        $lines[0..([Math]::Min(14, $lines.Count-1))] | ForEach-Object { Write-Host $_ }
        Write-Host ""
    }
}
