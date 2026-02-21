# FixHKLM.ps1
# Run as Administrator.
# Writes the InprocServer32 values that RegAsm should have written but missed.
# Also fixes the HKLM ProgId -> CLSID lookup.

$clsid   = "{C1E7A840-D4B5-4E8B-B63F-0A4E7C3A9E1F}"
$progId  = "OneNoteExportAddin.Connect"
$dllPath = "C:\Users\awt\OneNoteExportAddin\bin\Release\net48\OneNoteExportAddin.dll"
$codeBase = "file:///" + $dllPath.Replace("\", "/")
$assembly = "OneNoteExportAddin, Version=1.0.0.0, Culture=neutral"
$runtime  = "v4.0.30319"

Write-Host "Writing HKLM InprocServer32 values..." -ForegroundColor Cyan

$inprocKey = "HKLM:\Software\Classes\CLSID\$clsid\InprocServer32"
New-Item -Path $inprocKey -Force | Out-Null
Set-ItemProperty -Path $inprocKey -Name "(Default)"      -Value "mscoree.dll"
Set-ItemProperty -Path $inprocKey -Name "Class"          -Value $progId
Set-ItemProperty -Path $inprocKey -Name "Assembly"       -Value $assembly
Set-ItemProperty -Path $inprocKey -Name "RuntimeVersion" -Value $runtime
Set-ItemProperty -Path $inprocKey -Name "CodeBase"       -Value $codeBase
Set-ItemProperty -Path $inprocKey -Name "ThreadingModel" -Value "Both"
Write-Host "  InprocServer32 values written"

# Write HKLM ProgId -> CLSID mapping
$progIdClsidKey = "HKLM:\Software\Classes\$progId\CLSID"
New-Item -Path $progIdClsidKey -Force | Out-Null
Set-ItemProperty -Path $progIdClsidKey -Name "(Default)" -Value $clsid

$progIdKey = "HKLM:\Software\Classes\$progId"
Set-ItemProperty -Path $progIdKey -Name "(Default)" -Value $progId
Write-Host "  HKLM ProgId key written"

# Verify
Write-Host "`n=== Verification ===" -ForegroundColor Cyan
Get-ItemProperty $inprocKey | Format-List "(Default)", Class, Assembly, RuntimeVersion, CodeBase, ThreadingModel

Write-Host "Done. Restart OneNote to test." -ForegroundColor Green
