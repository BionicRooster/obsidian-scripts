# Check add-in load status
$lb = (Get-ItemProperty 'HKCU:\Software\Microsoft\Office\OneNote\Addins\OneNoteExportAddin.Connect').LoadBehavior
Write-Host "LoadBehavior: $lb"
if ($lb -eq 3) { Write-Host "Good - add-in connected!" -ForegroundColor Green }
else            { Write-Host "Still failing (expected 3)" -ForegroundColor Red }

$logFile = 'C:\Users\awt\onenote_addin_log.txt'
if (Test-Path $logFile) {
    Write-Host "=== Add-in log ===" -ForegroundColor Green
    Get-Content $logFile
} else {
    Write-Host "No log file"
}
