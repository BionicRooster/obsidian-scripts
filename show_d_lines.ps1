# show_d_lines.ps1
# Shows exact content of lines containing [[D in affected MOC files

$files = @(
    'D:\Obsidian\Main\00 - Home Dashboard\MOC - Travel & Exploration.md',
    'D:\Obsidian\Main\00 - Home Dashboard\MOC - Reading & Literature.md'
)

foreach ($f in $files) {
    Write-Host "=== $f ==="
    $lines = [System.IO.File]::ReadAllLines($f, [System.Text.Encoding]::UTF8)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '\[\[D') {
            Write-Host "  Line $($i+1): '$($lines[$i])'"
        }
    }
}
