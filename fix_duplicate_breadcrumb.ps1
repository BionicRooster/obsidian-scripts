# Fix duplicate breadcrumb caused by double replacement
$wallenPath = 'D:\Obsidian\Main\15 - People\Jack Wallen.md'
$content = Get-Content $wallenPath -Encoding UTF8 -Raw
$content = $content -replace '\[\[15 - People\]\] \| \[\[MOC - Technology & Computers\]\] \| \[\[MOC - Technology & Computers\]\]', '[[15 - People]] | [[MOC - Technology & Computers]]'
[System.IO.File]::WriteAllText($wallenPath, $content, [System.Text.Encoding]::UTF8)
Write-Host "Fixed Wallen breadcrumb"

$colinPath = 'D:\Obsidian\Main\15 - People\Colin Marshall.md'
$content = Get-Content $colinPath -Encoding UTF8 -Raw
$content = $content -replace '\[\[15 - People\]\] \| \[\[MOC - Travel & Exploration\]\] \| \[\[MOC - Travel & Exploration\]\]', '[[15 - People]] | [[MOC - Travel & Exploration]]'
[System.IO.File]::WriteAllText($colinPath, $content, [System.Text.Encoding]::UTF8)
Write-Host "Fixed Colin breadcrumb"
