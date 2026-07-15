Set-Location 'C:\Users\awt\Sync\Obsidian'
# Restore Recipes MOC from last commit
git checkout 2dfa4b4 -- "00 - Home Dashboard/MOC - Recipes.md"
Write-Host "Recipes restored"
# Check byte count
(Get-Item '00 - Home Dashboard\MOC - Recipes.md').Length
