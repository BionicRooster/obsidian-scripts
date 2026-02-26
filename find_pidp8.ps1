# find_pidp8.ps1
# Find all files containing [pidp8] in their name

Get-ChildItem 'D:\Obsidian\Main' -Recurse -Filter '*.md' | Where-Object {
    $_.Name -like '*[[]pidp8[]]*.md'
} | Select-Object FullName | ForEach-Object { Write-Host $_.FullName }
