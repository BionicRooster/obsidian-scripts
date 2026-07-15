Set-Location 'C:\Users\awt\Sync\Obsidian'
git log --all --oneline -- "00 - Home Dashboard/MOC - Science & Nature.md" | Select-Object -First 5
Write-Host '---'
git log --all --oneline -- "00 - Home Dashboard/MOC - Recipes.md" | Select-Object -First 5
