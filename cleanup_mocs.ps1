# MOC Cleanup — remove misplaced links and reassign to correct MOCs
$dashboard = 'D:\Obsidian\Main\00 - Home Dashboard'

# Helper: remove a line containing a specific wikilink from a file
function Remove-MOCLink {
    param([string]$FilePath, [string]$LinkText)
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    # Match the full bullet line containing this link
    $pattern = "(?m)^- \[\[$([regex]::Escape($LinkText))\]\]\r?\n"
    $newContent = [regex]::Replace($content, $pattern, '')
    if ($newContent -ne $content) {
        [System.IO.File]::WriteAllText($FilePath, $newContent, [System.Text.UTF8Encoding]::new($false))
        return $true
    }
    return $false
}

# Helper: insert a link into a section
function Add-MOCLink {
    param([string]$FilePath, [string]$SectionHeader, [string]$LinkText)
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    # Find section header and insert after it
    $pattern = "(?m)(^## $([regex]::Escape($SectionHeader))\r?\n)"
    $replacement = "`$1- [[$LinkText]]`r`n"
    $newContent = [regex]::Replace($content, $pattern, $replacement)
    if ($newContent -ne $content) {
        [System.IO.File]::WriteAllText($FilePath, $newContent, [System.Text.UTF8Encoding]::new($false))
        return $true
    }
    return $false
}

$results = @()

# ── Find Bahá'í Faith MOC (diacritics in filename) ──────────────────────────
$bahaiFaithMoc = Get-ChildItem -Path $dashboard -Filter 'MOC - Bah*.md' | Select-Object -First 1
if (-not $bahaiFaithMoc) {
    Write-Output "ERROR: Could not find Bahá'í Faith MOC"
    exit
}
$bahaiFaithPath = $bahaiFaithMoc.FullName
Write-Output "Found Bahá'í MOC: $($bahaiFaithMoc.Name)"

# 1. Move [[2 Timothy 3 NLT - Th]] from Central Figures to Clippings & Resources
$r = Remove-MOCLink -FilePath $bahaiFaithPath -LinkText '2 Timothy 3 NLT - Th'
if ($r) {
    Add-MOCLink -FilePath $bahaiFaithPath -SectionHeader 'Clippings & Resources' -LinkText '2 Timothy 3 NLT - Th' | Out-Null
    $results += 'MOVED: [[2 Timothy 3 NLT - Th]] Bahai Central Figures -> Bahai Clippings and Resources'
} else { $results += 'NOT FOUND: [[2 Timothy 3 NLT - Th]] in Bahai MOC' }

# 2. Move [[The Titanic's Forgotten Survivor]] from Central Figures to Clippings & Resources
$r = Remove-MOCLink -FilePath $bahaiFaithPath -LinkText "The Titanic's Forgotten Survivor"
if ($r) {
    Add-MOCLink -FilePath $bahaiFaithPath -SectionHeader 'Clippings & Resources' -LinkText "The Titanic's Forgotten Survivor" | Out-Null
    $results += "MOVED: [[The Titanic's Forgotten Survivor]] Bahai Central Figures -> Bahai Clippings and Resources"
} else { $results += "NOT FOUND: [[The Titanic's Forgotten Survivor]] in Bahai MOC" }

# ── NLP & Psychology MOC ────────────────────────────────────────────────────
$nlpMocPath = Join-Path $dashboard 'MOC - NLP & Psychology.md'

# 3. Remove [[HP Retiree Dave Packard]] from Psychology & Behavior (already in Tech MOC)
$r = Remove-MOCLink -FilePath $nlpMocPath -LinkText 'HP Retiree Dave Packard'
if ($r) { $results += 'REMOVED: [[HP Retiree Dave Packard]] from NLP (already in Technology MOC)' }
else { $results += 'NOT FOUND: [[HP Retiree Dave Packard]] in NLP MOC' }

# 4. Remove [[The Art of the Apology]] from PKM Systems, add to NLP Psychology & Behavior
$pkmMocPath = Join-Path $dashboard 'MOC - Personal Knowledge Management.md'
$r = Remove-MOCLink -FilePath $pkmMocPath -LinkText 'The Art of the Apology'
if ($r) {
    Add-MOCLink -FilePath $nlpMocPath -SectionHeader 'Psychology & Behavior' -LinkText 'The Art of the Apology' | Out-Null
    $results += 'MOVED: [[The Art of the Apology]] PKM Systems -> NLP Psychology and Behavior'
} else { $results += 'NOT FOUND: [[The Art of the Apology]] in PKM MOC' }

# ── Home & Practical Life MOC ───────────────────────────────────────────────
$homeMocPath = Join-Path $dashboard 'MOC - Home & Practical Life.md'
$genealogyMocPath = Join-Path $dashboard 'MOC - Genealogy.md'
$financeMocPath = Join-Path $dashboard 'MOC - Finance & Investment.md'

# 5. Move [[Bettinger-Wayne-Genetic Genealogy in Practice]] to Genealogy > Resources & How-Tos
$r = Remove-MOCLink -FilePath $homeMocPath -LinkText 'Bettinger-Wayne-Genetic Genealogy in Practice'
if ($r) {
    Add-MOCLink -FilePath $genealogyMocPath -SectionHeader 'Resources & How-Tos' -LinkText 'Bettinger-Wayne-Genetic Genealogy in Practice' | Out-Null
    $results += 'MOVED: [[Bettinger-Wayne-Genetic Genealogy in Practice]] Home -> Genealogy Resources'
} else { $results += 'NOT FOUND: [[Bettinger-Wayne-Genetic Genealogy in Practice]] in Home MOC' }

# 6. Move [[DNA]] to Genealogy > DNA & Genetic Genealogy
$r = Remove-MOCLink -FilePath $homeMocPath -LinkText 'DNA'
if ($r) {
    Add-MOCLink -FilePath $genealogyMocPath -SectionHeader 'DNA & Genetic Genealogy' -LinkText 'DNA' | Out-Null
    $results += 'MOVED: [[DNA]] Home Practical Tips -> Genealogy DNA section'
} else { $results += 'NOT FOUND: [[DNA]] in Home MOC' }

# 7. Move [[IRS Wash Sale Rules]] to Finance > Financial Management
$r = Remove-MOCLink -FilePath $homeMocPath -LinkText 'IRS Wash Sale Rules'
if ($r) {
    Add-MOCLink -FilePath $financeMocPath -SectionHeader 'Financial Management' -LinkText 'IRS Wash Sale Rules' | Out-Null
    $results += 'MOVED: [[IRS Wash Sale Rules]] Home Practical Tips -> Finance Financial Management'
} else { $results += 'NOT FOUND: [[IRS Wash Sale Rules]] in Home MOC' }

# ── Science & Nature MOC ────────────────────────────────────────────────────
$scienceMocPath = Join-Path $dashboard 'MOC - Science & Nature.md'

# 8. Remove [[IBM Research Thinks]] from Science Articles (already in Technology MOC)
$r = Remove-MOCLink -FilePath $scienceMocPath -LinkText 'IBM Research Thinks'
if ($r) { $results += 'REMOVED: [[IBM Research Thinks]] from Science Articles (already in Technology MOC)' }
else { $results += 'NOT FOUND: [[IBM Research Thinks]] in Science MOC' }

# 9. Remove [[Powdered Booze Could]] from Science Articles (already in Health MOC)
$r = Remove-MOCLink -FilePath $scienceMocPath -LinkText 'Powdered Booze Could'
if ($r) { $results += 'REMOVED: [[Powdered Booze Could]] from Science Articles (already in Health MOC)' }
else { $results += 'NOT FOUND: [[Powdered Booze Could]] in Science MOC' }

# ── Summary ─────────────────────────────────────────────────────────────────
Write-Output ""
Write-Output "=== MOC Cleanup Summary ==="
$results | ForEach-Object { Write-Output "  $_" }
Write-Output ""
Write-Output "Total changes: $($results.Count)"
