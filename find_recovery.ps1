# Find Obsidian file recovery snapshots
$appdata = $env:APPDATA
$localdata = $env:LOCALAPPDATA

# Obsidian stores snapshots in AppData\Roaming\obsidian\backups or similar
$candidates = @(
    "$appdata\obsidian",
    "$localdata\obsidian",
    "$appdata\Obsidian",
    "$localdata\Obsidian"
)

foreach ($p in $candidates) {
    if (Test-Path $p) {
        Write-Host "EXISTS: $p"
        Get-ChildItem $p -ErrorAction SilentlyContinue | Select-Object Name | Format-Table
    } else {
        Write-Host "MISSING: $p"
    }
}
