# Script to find the Baha'i folder in 01/ using wildcard to avoid diacritical issues
# The folder name contains á and í characters which cannot be used inline
$base = 'D:\Obsidian\Main\01'

# Use wildcard to find folder starting with Bah
$folder = Get-ChildItem -Path $base -Directory | Where-Object { $_.Name -like 'Bah*' }
foreach ($f in $folder) {
    Write-Output "PATH: $($f.FullName)"
    Write-Output "NAME: $($f.Name)"
}
