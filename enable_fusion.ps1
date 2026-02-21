# enable_fusion.ps1 - enable CLR assembly binding log then restart OneNote

$logDir = "C:\FusionLog"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$fusKey = "HKCU:\Software\Microsoft\Fusion"
New-Item -Path $fusKey -Force | Out-Null
Set-ItemProperty -Path $fusKey -Name "EnableLog"   -Value 1 -Type DWord
Set-ItemProperty -Path $fusKey -Name "ForceLog"    -Value 1 -Type DWord
Set-ItemProperty -Path $fusKey -Name "LogFailures" -Value 1 -Type DWord
Set-ItemProperty -Path $fusKey -Name "LogPath"     -Value $logDir
Write-Host "Fusion log enabled -> $logDir"

Stop-Process -Name ONENOTE -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Set-ItemProperty "HKCU:\Software\Microsoft\Office\OneNote\Addins\OneNoteExportAddin.Connect" `
    -Name LoadBehavior -Value 3 -Type DWord
Start-Process ONENOTE.EXE
Write-Host "OneNote restarted"
