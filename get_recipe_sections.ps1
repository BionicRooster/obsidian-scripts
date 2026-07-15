Get-Content 'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Recipes.md' -Encoding UTF8 |
  Where-Object { $_ -match '^##' }
