' run_prn_watcher.vbs
' Launches watch_prn_files.ps1 completely hidden using WScript.Shell Run with window style 0 (vbHide).
' This is the reliable way to suppress the PowerShell console window from Task Scheduler.

Dim WShell
Set WShell = CreateObject("WScript.Shell")

' Window style 0 = vbHide (completely hidden, no flash, no taskbar entry)
' bWaitOnReturn = False (fire and forget - VBS exits immediately, PS keeps running)
WShell.Run "powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\Users\awt\watch_prn_files.ps1""", 0, False

Set WShell = Nothing
