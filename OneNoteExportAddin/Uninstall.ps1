# Uninstall.ps1
#
# Removes all registry keys added by Install.ps1.
# Run if you want to disable or remove the add-in.

Set-StrictMode -Version Latest

# Identifiers — must match Install.ps1 / Connect.cs
$Clsid  = "{C1E7A840-D4B5-4E8B-B63F-0A4E7C3A9E1F}"
$ProgId = "OneNoteExportAddin.Connect"

Write-Host "Uninstalling OneNote Obsidian Export add-in..." -ForegroundColor Cyan

# Remove COM CLSID key
$clsidPath = "HKCU:\Software\Classes\CLSID\$Clsid"
if (Test-Path $clsidPath) {
    Remove-Item -Path $clsidPath -Recurse -Force
    Write-Host "  Removed CLSID key"
}

# Remove ProgId key
$progIdPath = "HKCU:\Software\Classes\$ProgId"
if (Test-Path $progIdPath) {
    Remove-Item -Path $progIdPath -Recurse -Force
    Write-Host "  Removed ProgId key"
}

# Remove OneNote add-in key
$addinPath = "HKCU:\Software\Microsoft\Office\OneNote\Addins\$ProgId"
if (Test-Path $addinPath) {
    Remove-Item -Path $addinPath -Recurse -Force
    Write-Host "  Removed OneNote add-in key"
}

Write-Host ""
Write-Host "Uninstall complete." -ForegroundColor Green
Write-Host "Restart OneNote to remove the button from the ribbon."
