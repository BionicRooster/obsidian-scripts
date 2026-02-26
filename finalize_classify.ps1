# finalize_classify.ps1
# Adds missing MOC links and fixes nav/frontmatter issues for recently classified files

$vaultPath = 'D:\Obsidian\Main'

# -- Helper: add a wikilink bullet after a section header in a MOC file -----------
function Add-MOCLink {
    param(
        [string]$MOCPath,
        [string]$Section,
        [string]$LinkText    # Full wikilink text, e.g. "[[path|name]]"
    )
    $content = Get-Content $MOCPath -Raw -Encoding UTF8
    if ($content -match [regex]::Escape($LinkText)) {
        Write-Host "  SKIP (already linked): $LinkText" -ForegroundColor DarkGray
        return
    }
    $escaped = [regex]::Escape($Section)
    if ($content -match "(?m)^$escaped\s*$") {
        $content = $content -replace "(?m)(^$escaped\s*\r?\n)", "`$1- $LinkText`n"
    } else {
        $content = $content.TrimEnd() + "`n`n$Section`n- $LinkText`n"
    }
    Set-Content $MOCPath -Value $content -Encoding UTF8 -NoNewline
    Write-Host "  ADDED to $([System.IO.Path]::GetFileNameWithoutExtension($MOCPath)) [$Section]: $LinkText" -ForegroundColor Green
}

# -- Helper: ensure a file has exactly one nav property pointing to a given MOC --
function Set-NavProperty {
    param(
        [string]$FilePath,
        [string]$MOCTarget    # e.g. "00 - Home Dashboard/MOC - Japan & Japanese Culture"
    )
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $navLine = "nav: `"[[$MOCTarget]]`""

    # Remove all existing nav: lines from frontmatter
    $content = $content -replace '(?m)^nav:.*$\r?\n?', ''
    # Remove duplicate blank lines in frontmatter
    $content = $content -replace '(?m)(---\r?\n)\r?\n+', '$1'

    # Insert nav after opening ---
    if ($content -match '^---\r?\n') {
        $content = $content -replace '^(---\r?\n)', "`$1$navLine`n"
    }
    Set-Content $FilePath -Value $content -Encoding UTF8 -NoNewline
    Write-Host "  SET nav -> [[$MOCTarget]] in: $([System.IO.Path]::GetFileName($FilePath))" -ForegroundColor Cyan
}

Write-Host "=== Finalizing Classification ===" -ForegroundColor Cyan

# 1. Beer Yeast Content -> Recipes > ## Beverages
Add-MOCLink `
    -MOCPath  "$vaultPath\00 - Home Dashboard\MOC - Recipes.md" `
    -Section  '## Beverages' `
    -LinkText '[[01/Recipes/Beer Yeast Content|Beer Yeast Content]]'

# 2. A Top Japanese Renovation Expert -> Japan MOC > ## Home & Lifestyle
# (root file - no move)
Add-MOCLink `
    -MOCPath  "$vaultPath\00 - Home Dashboard\MOC - Japan & Japanese Culture.md" `
    -Section  '## Home & Lifestyle' `
    -LinkText "[[A Top Japanese Renovation Expert's Brutal Advice to Foreign Buyers]]"

# 3. New Research Brains -> Health MOC > ## Health Articles & Clippings
# (after file is moved to 01\Health\)
Add-MOCLink `
    -MOCPath  "$vaultPath\00 - Home Dashboard\MOC - Health & Nutrition.md" `
    -Section  '## Health Articles & Clippings' `
    -LinkText "[[01/Health/New Research Reveals Why Some Brains Can't Switch Off at Night|New Research Reveals Why Some Brains Can't Switch Off at Night]]"

# 4. Fix nav on A Top Japanese Renovation Expert (currently wrong -> Home & Practical Life)
# This file has no YAML frontmatter - just inline tags line. Add nav to Related Notes instead.
$japanRenov = "$vaultPath\A Top Japanese Renovation Expert's Brutal Advice to Foreign Buyers.md"
$content = Get-Content $japanRenov -Raw -Encoding UTF8
# Replace the wrong MOC nav link in Related Notes
$content = $content -replace '\[\[00 - Home Dashboard/MOC - Home & Practical Life\|MOC - Home & Practical Life\]\]',
                              '[[00 - Home Dashboard/MOC - Japan & Japanese Culture|MOC - Japan & Japanese Culture]]'
Set-Content $japanRenov -Value $content -Encoding UTF8 -NoNewline
Write-Host "  FIXED nav in: A Top Japanese Renovation Expert..." -ForegroundColor Cyan

# 5. Fix duplicate nav in Bloom's Taxonomy
$bloomPath = "$vaultPath\01\PKM\Bloom's Taxonomy of.md"
Set-NavProperty -FilePath $bloomPath -MOCTarget '00 - Home Dashboard/MOC - Personal Knowledge Management'

# 6. Fix duplicate nav in Jerusalem Archaeology
$jerusalemPath = "$vaultPath\01\Religion\Jerusalem Archaeology Reveals Birth Of Christianity.md"
Set-NavProperty -FilePath $jerusalemPath -MOCTarget '00 - Home Dashboard/MOC - Social Issues'

# 7. Fix garbled frontmatter in Gerry Spence and NLP
$gerryPath = "$vaultPath\01\NLP_Psy\Gerry Spence and NLP.md"
$gc = Get-Content $gerryPath -Raw -Encoding UTF8
# Rewrite the frontmatter cleanly
$cleanFrontmatter = "---`nnav: `"[[00 - Home Dashboard/MOC - NLP & Psychology]]`"`ntags:`n  - NLP`n  - law`n  - NLP_Psy`n---"
$gc = $gc -replace '(?s)^---.*?---', $cleanFrontmatter
Set-Content $gerryPath -Value $gc -Encoding UTF8 -NoNewline
Write-Host "  FIXED frontmatter: Gerry Spence and NLP.md" -ForegroundColor Cyan

Write-Host "`nDone." -ForegroundColor Green
