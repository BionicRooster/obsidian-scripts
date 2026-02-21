# Move Raklet CRM note to 01\Bahá'í folder
$vault = "D:\Obsidian\Main"
$src = Join-Path $vault "A Summary of Raklet CRM.md"
# Find the Bahá'í folder dynamically
$bahaiDir = Get-ChildItem (Join-Path $vault "01") -Directory | Where-Object { $_.Name -match "Bah" }
$dest = Join-Path $bahaiDir.FullName "A Summary of Raklet CRM.md"
Move-Item -Path $src -Destination $dest -Force
Write-Output "MOVED: A Summary of Raklet CRM.md -> 01\$($bahaiDir.Name)"
