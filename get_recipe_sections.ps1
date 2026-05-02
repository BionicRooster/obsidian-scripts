Get-Content 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Recipes.md' -Encoding UTF8 |
  Where-Object { $_ -match '^##' }
