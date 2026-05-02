# Fix nav properties for people files
$peopleDir = 'D:\Obsidian\Main\15 - People'

# 1. Rex Steven Sikes - fix nav (has breadcrumb content in it)
$sikes = Join-Path $peopleDir 'Rex Steven Sikes.md'
$content = Get-Content $sikes -Encoding UTF8 -Raw
$content = $content -replace 'nav: "\[\[15 - People\]\] \| \[\[MOC - NLP & Psychology\]\]"', 'nav: "[[MOC - NLP & Psychology]]"'
[System.IO.File]::WriteAllText($sikes, $content, [System.Text.Encoding]::UTF8)
Write-Host "Fixed Sikes nav"

# 2. Shelle Rose Charvet - fix nav (same issue)
$charvet = Join-Path $peopleDir 'Shelle Rose Charvet.md'
$content = Get-Content $charvet -Encoding UTF8 -Raw
$content = $content -replace 'nav: "\[\[15 - People\]\] \| \[\[MOC - NLP & Psychology\]\]"', 'nav: "[[MOC - NLP & Psychology]]"'
[System.IO.File]::WriteAllText($charvet, $content, [System.Text.Encoding]::UTF8)
Write-Host "Fixed Charvet nav"

# 3. Jack Wallen - add nav for Technology
$wallen = Join-Path $peopleDir 'Jack Wallen.md'
$content = Get-Content $wallen -Encoding UTF8 -Raw
if ($content -notmatch 'nav:') {
    $content = $content -replace '(---\n\n\[\[15 - People\]\])', "---`nnav: ""[[MOC - Technology & Computers]]""`n`n[[15 - People]] | [[MOC - Technology & Computers]]"
    # Fix the breadcrumb too - it currently just says [[15 - People]]
    [System.IO.File]::WriteAllText($wallen, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Fixed Wallen nav"
} else {
    Write-Host "Wallen already has nav"
}

# 4. Colin Marshall - add nav for Japan/Travel
$colin = Join-Path $peopleDir 'Colin Marshall.md'
$content = Get-Content $colin -Encoding UTF8 -Raw
if ($content -notmatch 'nav:') {
    $content = $content -replace '(---\n\n\[\[15 - People\]\])', "---`nnav: ""[[MOC - Travel & Exploration]]""`n`n[[15 - People]] | [[MOC - Travel & Exploration]]"
    [System.IO.File]::WriteAllText($colin, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Fixed Colin nav"
} else {
    Write-Host "Colin already has nav"
}

# 5. Carolyn Maiers - remove broken Related Note link
$maiers = Join-Path $peopleDir 'Carolyn Maiers.md'
$content = Get-Content $maiers -Encoding UTF8 -Raw
$content = $content -replace '\r?\n- \[\[NLP Forum - DHE Article by Carolyn Maiers \(April 1995\)\]\]', ''
[System.IO.File]::WriteAllText($maiers, $content, [System.Text.Encoding]::UTF8)
Write-Host "Fixed Maiers Related Notes"
