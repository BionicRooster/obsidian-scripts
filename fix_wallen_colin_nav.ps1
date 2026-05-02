# Fix Jack Wallen - move nav inside frontmatter and update breadcrumb
$wallenPath = 'D:\Obsidian\Main\15 - People\Jack Wallen.md'
$content = Get-Content $wallenPath -Encoding UTF8 -Raw

# Remove the nav that got placed outside frontmatter, then add it inside
# Current pattern: ...modified: DATE\n---\nnav: "..."\n\n[[15 - People]]
# Target:          ...modified: DATE\nnav: "..."\n---\n\n[[15 - People]] | [[MOC - ...]]
$content = $content -replace '(modified: [^\r\n]+)\r?\n---\r?\nnav: "(\[\[MOC - Technology & Computers\]\])"\r?\n\r?\n\[\[15 - People\]\]', "`$1`nnav: ""[[MOC - Technology & Computers]]""`n---`n`n[[15 - People]] | [[MOC - Technology & Computers]]"

[System.IO.File]::WriteAllText($wallenPath, $content, [System.Text.Encoding]::UTF8)
Write-Host "Fixed Wallen"

# Fix Colin Marshall - same pattern, different MOC
$colinPath = 'D:\Obsidian\Main\15 - People\Colin Marshall.md'
$content = Get-Content $colinPath -Encoding UTF8 -Raw

$content = $content -replace '(modified: [^\r\n]+)\r?\n---\r?\nnav: "(\[\[MOC - Travel & Exploration\]\])"\r?\n\r?\n\[\[15 - People\]\]', "`$1`nnav: ""[[MOC - Travel & Exploration]]""`n---`n`n[[15 - People]] | [[MOC - Travel & Exploration]]"

[System.IO.File]::WriteAllText($colinPath, $content, [System.Text.Encoding]::UTF8)
Write-Host "Fixed Colin"

# Verify
Write-Host "`n--- Wallen first 14 lines ---"
Get-Content $wallenPath -Encoding UTF8 | Select-Object -First 14 | ForEach-Object { Write-Host $_ }
Write-Host "`n--- Colin first 14 lines ---"
Get-Content $colinPath -Encoding UTF8 | Select-Object -First 14 | ForEach-Object { Write-Host $_ }
