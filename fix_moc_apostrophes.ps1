# fix_moc_apostrophes.ps1
# Repairs broken wikilinks in MOC - Recipes.md that were split by apostrophes

$utf8 = [System.Text.Encoding]::UTF8
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$mocPath = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Recipes.md'

# Read content
$content = [System.IO.File]::ReadAllText($mocPath, $utf8)

Write-Host "=== Current lines containing fragments ==="
$lines = $content -split "`n"
$lineNum = 0
foreach ($line in $lines) {
    $lineNum++
    $t = $line.TrimEnd()
    if ($t -match "^- s No-fu|^- s Macaroni|^Herbes|^- 09 Newsletter" -or $t -eq "- '") {
        Write-Host "Line ${lineNum}: '$t'"
    }
}

Write-Host "`n=== Applying fixes ==="

# Fix 1: Dreena's No-fu Love Loaf 1
# Broken form: "- [[Dreena`n- '`n- s No-fu Love Loaf 1]]"
$before = $content
$content = $content -replace "- \[\[Dreena\r?\n- '\r?\n- s No-fu Love Loaf 1\]\]", "- [[Dreena's No-fu Love Loaf 1]]"
if ($content -ne $before) { Write-Host "Fixed: Dreena's No-fu Love Loaf 1" } else { Write-Host "No change: Dreena's (check pattern)" }

# Fix 2: Romano's Macaroni Grill Focaccia
$before = $content
$content = $content -replace "- \[\[Romano\r?\n- '\r?\n- s Macaroni Grill Focaccia\]\]", "- [[Romano's Macaroni Grill Focaccia]]"
if ($content -ne $before) { Write-Host "Fixed: Romano's Macaroni Grill Focaccia" } else { Write-Host "No change: Romano's (check pattern)" }

# Fix 3: Green Gumbo (Gumbo Z'Herbes)
$before = $content
$content = $content -replace "- \[\[Green Gumbo \(Gumbo Z\r?\n- '\r?\n- Herbes\)\]\]", "- [[Green Gumbo (Gumbo Z'Herbes)]]"
if ($content -ne $before) { Write-Host "Fixed: Green Gumbo (Gumbo Z'Herbes)" } else { Write-Host "No change: Green Gumbo (check pattern)" }

# Fix 4: Starwest Holiday '09 Newsletter with Savings!
$before = $content
$content = $content -replace "- \[\[Starwest Holiday \r?\n- '\r?\n- 09 Newsletter with Savings!\]\]", "- [[Starwest Holiday '09 Newsletter with Savings!]]"
if ($content -ne $before) { Write-Host "Fixed: Starwest Holiday '09 Newsletter" } else { Write-Host "No change: Starwest Holiday (check pattern)" }

# Also try alternate line ending patterns (CRLF vs LF)
# Some systems may have \r\n, try without the optional \r
$before = $content
$content = $content -replace "- \[\[Dreena`n- '`n- s No-fu Love Loaf 1\]\]", "- [[Dreena's No-fu Love Loaf 1]]"
if ($content -ne $before) { Write-Host "Fixed (LF): Dreena's" }

$before = $content
$content = $content -replace "- \[\[Romano`n- '`n- s Macaroni Grill Focaccia\]\]", "- [[Romano's Macaroni Grill Focaccia]]"
if ($content -ne $before) { Write-Host "Fixed (LF): Romano's" }

$before = $content
$content = $content -replace "- \[\[Green Gumbo \(Gumbo Z`n- '`n- Herbes\)\]\]", "- [[Green Gumbo (Gumbo Z'Herbes)]]"
if ($content -ne $before) { Write-Host "Fixed (LF): Green Gumbo" }

$before = $content
$content = $content -replace "- \[\[Starwest Holiday `n- '`n- 09 Newsletter with Savings!\]\]", "- [[Starwest Holiday '09 Newsletter with Savings!]]"
if ($content -ne $before) { Write-Host "Fixed (LF): Starwest Holiday '09" }

# Write back
[System.IO.File]::WriteAllText($mocPath, $content, $utf8NoBom)

Write-Host "`n=== Verification ==="
$content2 = [System.IO.File]::ReadAllText($mocPath, $utf8)
Write-Host "Dreena's No-fu Love Loaf 1: $(if ($content2 -match [regex]::Escape(`"Dreena's No-fu Love Loaf 1`")) { 'FOUND' } else { 'MISSING' })"
Write-Host "Romano's Macaroni: $(if ($content2 -match [regex]::Escape(`"Romano's Macaroni`")) { 'FOUND' } else { 'MISSING' })"
Write-Host "Gumbo Z'Herbes: $(if ($content2 -match `"Gumbo Z'Herbes`") { 'FOUND' } else { 'MISSING' })"
Write-Host "Starwest Holiday '09: $(if ($content2 -match `"Starwest Holiday '09`") { 'FOUND' } else { 'MISSING' })"
