# verify_moc.ps1 - Verify the fixed MOC file
$utf8 = [System.Text.Encoding]::UTF8
$content = [System.IO.File]::ReadAllText('C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Recipes.md', $utf8)

# Check for remaining broken fragments (bullet lines not starting with [[)
$lines = $content -split "`n"
$broken = $lines | Where-Object {
    $t = $_.TrimEnd()
    # A bullet that doesn't start with [[ and isn't empty/section header
    $t -match '^- ' -and $t -notmatch '^- \[\[' -and $t -ne '- '
}
if ($broken.Count -gt 0) {
    Write-Host "BROKEN LINES FOUND:"
    $broken | ForEach-Object { Write-Host "  [$_]" }
} else {
    Write-Host "No broken bullet lines detected - all good!"
}

# Verify the 4 apostrophe links
$checks = @(
    "Dreena's No-fu Love Loaf 1",
    "Romano's Macaroni Grill Focaccia",
    "Gumbo Z'Herbes",
    "Starwest Holiday '09 Newsletter"
)
foreach ($c in $checks) {
    if ($content -match [regex]::Escape($c)) {
        Write-Host "FOUND: $c"
    } else {
        Write-Host "MISSING: $c"
    }
}

# Count total wikilink bullets
$bullets = $lines | Where-Object { $_ -match '^\- \[\[' }
Write-Host "Total wikilink bullets in MOC: $($bullets.Count)"

# Count files with nav in Recipes folder
$recipeFiles = Get-ChildItem 'C:\Users\awt\Sync\Obsidian\01\Recipes\' -Filter '*.md'
$withNav = 0
$withoutNav = 0
foreach ($f in $recipeFiles) {
    $fc = [System.IO.File]::ReadAllText($f.FullName, $utf8)
    if ($fc -match '(?m)^nav:') {
        $withNav++
    } else {
        $withoutNav++
    }
}
Write-Host "Recipe files WITH nav: $withNav"
Write-Host "Recipe files WITHOUT nav: $withoutNav"
