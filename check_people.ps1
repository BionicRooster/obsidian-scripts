# Check for existing people files
$people = "D:\Obsidian\Main\15 - People"
$names = @("Talbot", "Waldrep", "Norris", "Rowe", "White", "Stanard", "Waldrep")
Get-ChildItem $people -Filter "*.md" | Where-Object {
    $n = $_.Name
    $match = $false
    foreach ($name in $names) { if ($n -like "*$name*") { $match = $true } }
    $match
} | Select-Object -ExpandProperty Name
