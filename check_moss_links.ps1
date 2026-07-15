# check_moss_links.ps1 - Verify existence and relevance of Moss and CO2 related notes

$vault = 'C:\Users\awt\Sync\Obsidian'   # Vault root

# Each entry: display name and search term (filename stem)
$candidates = @(
    'Rava Idli Recipe',
    'Authentication in Windows BlueTooth Rohos device',
    'Groasis Waterboxx Greening the World',
    'Home and Hearth',
    'More kissing less kimchi',
    'SCORM',
    'Master MOC Index',
    'The boy who harnessed the wind',
    'World Peace',
    'Why humans have allergies'
)

foreach ($name in $candidates) {
    # Search vault for file matching this name (case-insensitive partial match)
    $found = Get-ChildItem $vault -Recurse -Filter '*.md' -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -like "*$name*" } |
        Select-Object -First 1
    if ($found) {
        Write-Host "FOUND   | $name" -ForegroundColor Green
        Write-Host "        | $($found.FullName)"
    } else {
        Write-Host "MISSING | $name" -ForegroundColor Red
    }
}
