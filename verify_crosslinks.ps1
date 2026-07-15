# Verify files exist for cross-linking
$linksToCheck = @(
    'Advantages and Disadvantages to Planting Moss',
    'Moss and CO2',
    'Soil Microbe Transplants Could Help Restore Damaged Ecosystems',
    'How India''s Air Pollution is Being Turned Into Floor Tiles',
    'The Story of the Manchester Bee Tattoo',
    'The 22 May 2017 Manchester Terrorist Attack - Bee Tattoo',
    'What Ecologists Are Learning from Indigenous People',
    'New Insights Into How the Famed Antikythera Mechanism May Have Worked',
    'Nobody Knows How This Part of Mars Exploded'
)

foreach ($name in $linksToCheck) {
    $found = Get-ChildItem 'C:\Users\awt\Sync\Obsidian' -Recurse -Filter '*.md' -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -eq $name } | Select-Object -First 1
    if ($found) {
        Write-Host "EXISTS: $name"
    } else {
        Write-Host "MISSING: $name"
    }
}
