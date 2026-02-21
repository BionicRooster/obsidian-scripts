# MoveToProgFiles.ps1  —  run as Administrator
# Copies the add-in DLL to Program Files and re-registers it there.
# This satisfies the security restriction that prevents COM add-ins
# loading from user-profile directories.

$src     = "C:\Users\awt\OneNoteExportAddin\bin\Release\net48\OneNoteExportAddin.dll"
$destDir = "C:\Program Files\OneNoteExportAddin"
$dest    = "$destDir\OneNoteExportAddin.dll"
$clsid   = "{C1E7A840-D4B5-4E8B-B63F-0A4E7C3A9E1F}"
$progId  = "OneNoteExportAddin.Connect"
$asm     = "OneNoteExportAddin, Version=1.0.0.0, Culture=neutral"
$runtime = "v4.0.30319"

# Copy DLL
New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Copy-Item -Path $src -Destination $dest -Force
Write-Host "Copied DLL to $dest"

# Update HKLM InprocServer32 CodeBase to new location
$codeBase  = "file:///" + $dest.Replace("\", "/")
$inprocKey = "HKLM:\Software\Classes\CLSID\$clsid\InprocServer32"
New-Item -Path $inprocKey -Force | Out-Null
Set-ItemProperty -Path $inprocKey -Name "(Default)"      -Value "mscoree.dll"
Set-ItemProperty -Path $inprocKey -Name "Class"          -Value $progId
Set-ItemProperty -Path $inprocKey -Name "Assembly"       -Value $asm
Set-ItemProperty -Path $inprocKey -Name "RuntimeVersion" -Value $runtime
Set-ItemProperty -Path $inprocKey -Name "CodeBase"       -Value $codeBase
Set-ItemProperty -Path $inprocKey -Name "ThreadingModel" -Value "Both"
Write-Host "Updated CodeBase to $codeBase"

# Reset LoadBehavior
Set-ItemProperty "HKCU:\Software\Microsoft\Office\OneNote\Addins\$progId" `
    -Name LoadBehavior -Value 3 -Type DWord
Write-Host "LoadBehavior reset to 3"

Write-Host "Done. Restart OneNote to test." -ForegroundColor Green
