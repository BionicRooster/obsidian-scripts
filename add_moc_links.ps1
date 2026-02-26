# add_moc_links.ps1 - Add MOC links for recently classified files

$vaultPath = 'D:\Obsidian\Main'   # Vault root

# Helper: insert a wikilink bullet after a section header in a MOC file
function Add-MOCLink {
    param(
        [string]$MOCPath,    # Full path to the MOC file
        [string]$Section,    # Section header text (e.g. "## Fermented Foods")
        [string]$LinkText    # Full wikilink (e.g. "[[path|title]]")
    )
    $content = Get-Content $MOCPath -Raw -Encoding UTF8
    # Skip if already linked
    if ($content -match [regex]::Escape($LinkText)) {
        Write-Host "  SKIP (already linked): $LinkText" -ForegroundColor DarkGray
        return
    }
    $escaped = [regex]::Escape($Section)
    if ($content -match "(?m)^$escaped\s*$") {
        # Section found: insert link on line after section header
        $content = $content -replace "(?m)(^$escaped\s*\r?\n)", "`$1- $LinkText`n"
    } else {
        # Section not found: append at end
        $content = $content.TrimEnd() + "`n`n$Section`n- $LinkText`n"
    }
    Set-Content $MOCPath -Value $content -Encoding UTF8 -NoNewline
    Write-Host "  ADDED [$Section]: $LinkText" -ForegroundColor Green
}

Write-Host "=== Adding MOC links ===" -ForegroundColor Cyan

# 1. Medieval Monks -> Recipes > ## Fermented Foods
Add-MOCLink `
    -MOCPath  "$vaultPath\00 - Home Dashboard\MOC - Recipes.md" `
    -Section  '## Fermented Foods' `
    -LinkText "[[20 - Permanent Notes/Medieval Monks Knew Something About Vinegar We've Completely Forgot|Medieval Monks Knew Something About Vinegar We've Completely Forgot]]"

# 2. Medieval Monks -> Science & Nature > ## Biology & Animal Science (already in Related Notes, but add to MOC)
Add-MOCLink `
    -MOCPath  "$vaultPath\00 - Home Dashboard\MOC - Science & Nature.md" `
    -Section  '## Biology & Animal Science' `
    -LinkText "[[20 - Permanent Notes/Medieval Monks Knew Something About Vinegar We've Completely Forgot|Medieval Monks Knew Something About Vinegar We've Completely Forgot]]"

# 3. Japan Renovation -> Japan MOC (should already be there from previous session, but verify)
Add-MOCLink `
    -MOCPath  "$vaultPath\00 - Home Dashboard\MOC - Japan & Japanese Culture.md" `
    -Section  '## Home & Lifestyle' `
    -LinkText "[[01/Home/A Top Japanese Renovation Expert's Brutal Advice to Foreign Buyers|A Top Japanese Renovation Expert's Brutal Advice to Foreign Buyers]]"

Write-Host "`nDone." -ForegroundColor Green
