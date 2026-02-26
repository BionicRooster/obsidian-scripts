# rebuild_science_moc.ps1 - Reconstruct MOC - Science & Nature.md from nav properties
# Groups files from 01\Science\ by topic keywords into sections

$vaultPath = 'D:\Obsidian\Main'   # Root of Obsidian vault
$mocPath   = "$vaultPath\00 - Home Dashboard\MOC - Science & Nature.md"

# Find all files in 01\Science that have nav pointing to Science & Nature
$scienceFiles = Get-ChildItem "$vaultPath\01\Science" -Filter '*.md' -Recurse |
  Where-Object {
    $content = Get-Content $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    $content -match 'MOC - Science & Nature'
  } |
  ForEach-Object {
    $base = $_.BaseName
    [PSCustomObject]@{
      Name     = $base
      FileName = $_.Name
      RelPath  = $_.FullName.Replace($vaultPath + '\', '') -replace '\\', '/'
    }
  } |
  Sort-Object Name

Write-Host "Found $($scienceFiles.Count) files in 01\Science referencing Science & Nature"

# Keyword patterns for section grouping
$sections = [ordered]@{
    '## Micrometeorites' = @('micrometeorite', 'stardust', 'cosmic dust', 'meteor')
    '## Archaeology & Ancient Civilizations' = @('archaeol', 'ancient', 'neanderthal', 'mammoth', 'mummy', 'inca', 'roman', 'greek', 'maya', 'aztec', 'hannibal', 'teotihu', 'antikythera', 'polynesi', 'biblical', 'extinction', 'earliest', 'historical', 'paleolith', 'prehistoric')
    '## Astronomy & Space' = @('mars', 'space', 'nasa', 'planet', 'star ', 'cosmos', 'alien', 'tsunami wave', 'aurora', 'sidereal', 'synodic', 'asteroid')
    '## Geology & Earth Science' = @('flood', 'bretz', 'volcanic', 'geology', 'sahara', 'continent', 'dune', 'ice age', 'sulphur', 'sulphur pyramid', 'chernobyl', 'dam removal')
    '## Biology & Animal Science' = @('bird', 'cardinal', 'octopi', 'reptile', 'dinosaur', 'woolly', 'reviving', 'extinct species', 'thunderbird', 'allergies', 'genetic', 'human disease', 'marine', 'nut ', 'pecan', 'lizard')
    '## Gardening & Botany' = @('garden', 'plant', 'vegetable', 'moss', 'tree', 'apricot', 'fruit', 'potato', 'apple', 'forest', 'ecologist', 'soil microbe', 'botany', 'cherry', 'medieval veg', 'maslin bread', 'blenheim', 'planting')
    '## Science Articles & Clippings' = @()  # Catch-all
}

# Assign each file to a section
$assigned = @{}   # file name -> section key
foreach ($file in $scienceFiles) {
    $nameLower = $file.Name.ToLower()
    $matched   = $false
    foreach ($section in $sections.Keys) {
        if ($section -eq '## Science Articles & Clippings') { continue }  # Skip catch-all in first pass
        $keywords = $sections[$section]
        foreach ($kw in $keywords) {
            if ($nameLower -match [regex]::Escape($kw)) {
                $assigned[$file.Name] = $section
                $matched = $true
                break
            }
        }
        if ($matched) { break }
    }
    if (-not $matched) {
        $assigned[$file.Name] = '## Science Articles & Clippings'
    }
}

# Build MOC content
$lines = @()
$lines += '---'
$lines += 'nav: "[[Master MOC Index]]"'
$lines += 'tags:'
$lines += '  - MOC'
$lines += '  - science'
$lines += '  - nature'
$lines += '---'
$lines += ''
$lines += '# MOC - Science & Nature'
$lines += ''
$lines += '> *Earth science, astronomy, biology, archaeology, gardening, and the natural world*'
$lines += ''
$lines += '---'
$lines += ''

foreach ($section in $sections.Keys) {
    $sectionFiles = $scienceFiles | Where-Object { $assigned[$_.Name] -eq $section }
    if ($sectionFiles.Count -eq 0) { continue }
    $lines += $section
    foreach ($f in $sectionFiles) {
        $lines += "- [[$($f.RelPath)|$($f.Name)]]"
    }
    $lines += ''
}

# Write the MOC
$content = $lines -join "`n"
Set-Content -Path $mocPath -Value $content -Encoding UTF8 -NoNewline

Write-Host "MOC rebuilt with $($scienceFiles.Count) links at: $mocPath"

# Summary by section
foreach ($section in $sections.Keys) {
    $count = ($scienceFiles | Where-Object { $assigned[$_.Name] -eq $section }).Count
    if ($count -gt 0) { Write-Host "  $section : $count files" }
}
