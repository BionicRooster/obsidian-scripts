# add_nav_frontmatter.ps1 - Add YAML frontmatter nav property to files that lack it

$vaultPath = 'D:\Obsidian\Main'   # Vault root

# Helper: add YAML frontmatter with nav to a file that has no frontmatter at all
function Add-NavFrontmatter {
    param(
        [string]$FilePath,    # Full path to the file
        [string]$MOCTarget,   # MOC path (e.g. "00 - Home Dashboard/MOC - Japan & Japanese Culture")
        [string[]]$Tags       # Array of tag strings to add
    )
    $content = Get-Content $FilePath -Raw -Encoding UTF8

    # Check if file already has YAML frontmatter
    if ($content -match '^---') {
        # Has frontmatter - check if nav is already there
        if ($content -match '(?m)^nav:') {
            Write-Host "  SKIP (nav already in frontmatter): $([System.IO.Path]::GetFileName($FilePath))" -ForegroundColor DarkGray
            return
        }
        # Has frontmatter but no nav - insert nav after opening ---
        $content = $content -replace '^(---\r?\n)', "`$1nav: `"[[$MOCTarget]]`"`n"
        Set-Content $FilePath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  ADDED nav to existing frontmatter: $([System.IO.Path]::GetFileName($FilePath))" -ForegroundColor Cyan
        return
    }

    # No frontmatter - build tags string
    $tagLines = ($Tags | ForEach-Object { "  - $_" }) -join "`n"
    $frontmatter = "---`nnav: `"[[$MOCTarget]]`"`ntags:`n$tagLines`n---`n`n"

    # Prepend frontmatter to file content
    $newContent = $frontmatter + $content
    Set-Content $FilePath -Value $newContent -Encoding UTF8 -NoNewline
    Write-Host "  ADDED frontmatter with nav: $([System.IO.Path]::GetFileName($FilePath))" -ForegroundColor Green
}

Write-Host "=== Adding nav frontmatter ===" -ForegroundColor Cyan

# 1. Japan Renovation Expert (no YAML frontmatter, currently has inline tags)
$japanPath = "$vaultPath\01\Home\A Top Japanese Renovation Expert's Brutal Advice to Foreign Buyers.md"
Add-NavFrontmatter `
    -FilePath  $japanPath `
    -MOCTarget '00 - Home Dashboard/MOC - Japan & Japanese Culture' `
    -Tags      @('JapanRealEstate', 'Akiya', 'Renovation', 'ForeignBuyers', 'Japan')

# 2. New Research Brains - find with wildcard (smart apostrophe in Can't)
$brains = Get-ChildItem "$vaultPath\01\Health" | Where-Object { $_.Name -match "Brains.*Switch" } | Select-Object -First 1
if ($brains) {
    Add-NavFrontmatter `
        -FilePath  $brains.FullName `
        -MOCTarget '00 - Home Dashboard/MOC - Health & Nutrition' `
        -Tags      @('Health', 'Sleep', 'Brain', 'Neuroscience')
} else {
    Write-Host "  NOT FOUND: Brains/Switch Off file in 01\Health" -ForegroundColor Red
}

Write-Host "`nDone." -ForegroundColor Green
