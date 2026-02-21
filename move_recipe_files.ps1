# Move recipe files from Gmail to 03 - Recipes
# Only move files that have actual recipe content (not just "recipe" in title from forwarding)
$vault = "D:\Obsidian\Main"
$gmail = "$vault\04 - GMail"
$recipes = "$vault\03 - Recipes"

$moved = @()
$skipped = @()

# Get files with "recipe" in the name
$files = Get-ChildItem -Path $gmail -Filter "*.md" | Where-Object { $_.Name -match "recipe" }

Write-Host "Found $($files.Count) potential recipe files"

foreach ($file in $files) {
    # Check if already exists in recipes folder
    $targetPath = Join-Path $recipes $file.Name

    if (Test-Path -LiteralPath $targetPath) {
        Write-Host "SKIP (exists): $($file.Name)"
        $skipped += $file.Name
        # Delete the duplicate from Gmail
        Remove-Item -LiteralPath $file.FullName -Force
        continue
    }

    # Read content to check if it's a real recipe
    $content = (Get-Content -Path $file.FullName -Encoding UTF8) -join "`n"

    # Check for recipe indicators (ingredients, directions, etc.)
    $hasIngredients = $content -match "(Ingredients|INGREDIENTS)"
    $hasDirections = $content -match "(Directions|DIRECTIONS|Instructions|INSTRUCTIONS|Method|Steps)"

    if ($hasIngredients -or $hasDirections) {
        # This is a real recipe - move it
        Move-Item -LiteralPath $file.FullName -Destination $recipes
        Write-Host "MOVED: $($file.Name)" -ForegroundColor Green
        $moved += $file.Name
    } else {
        # Not a real recipe, just has "recipe" in subject - leave in Gmail
        Write-Host "SKIP (no recipe content): $($file.Name)" -ForegroundColor Yellow
        $skipped += $file.Name
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Moved to 03 - Recipes: $($moved.Count)"
Write-Host "Skipped (already exists or no recipe content): $($skipped.Count)"
