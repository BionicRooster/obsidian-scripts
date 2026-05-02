# Check if person files already exist in 15 - People or elsewhere in vault
$vault = "D:\Obsidian\Main"
$names = @("Alfred W. Talbot Sr", "Col Mathew Talbot", "Vera Irene Talbot", "Dr. Alfred Carson Waldrep", "John Henry White", "Lee Etta Stanard", "Daniel Norris", "Mike Rowe")

foreach ($name in $names) {
    $results = Get-ChildItem $vault -Recurse -Filter "*.md" | Where-Object { $_.Name -like "*$name*" }
    if ($results) {
        foreach ($r in $results) { Write-Host "FOUND '$name': $($r.FullName)" }
    } else {
        Write-Host "NOT FOUND: $name"
    }
}
