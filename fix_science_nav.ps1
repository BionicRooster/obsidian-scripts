# Add nav to recently modified Science files missing it
$navValue = "MOC - Science & Nature"
$pattern = '(?s)^(---\r?\n.*?\r?\n)(---)'

$scienceDir = 'D:\Obsidian\Main\01\Science'
$targets = Get-ChildItem -Path $scienceDir -Filter '*.md' | Where-Object {
    $_.LastWriteTime -gt (Get-Date).AddDays(-3) -and $_.Name -notlike "*Ortelius*" -and $_.Name -notlike "*Book Conservation*"
}

foreach ($f in $targets) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match '(?m)^nav:') {
        Write-Host "ALREADY HAS NAV: $($f.Name)"
    } elseif ($content -match $pattern) {
        $newContent = $content -replace $pattern, "`$1nav: `"[[$navValue]]`"`n`$2"
        [System.IO.File]::WriteAllText($f.FullName, $newContent, [System.Text.Encoding]::UTF8)
        Write-Host "UPDATED: $($f.Name)"
    } else {
        Write-Host "NO FRONTMATTER: $($f.Name)"
    }
}
