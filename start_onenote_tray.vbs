' start_onenote_tray.vbs
' Launches onenote_tray.py using pythonw.exe so no console window appears.
' Double-click this file to start the tray icon.

Dim shell
Set shell = CreateObject("WScript.Shell")
shell.Run "pythonw """ & shell.CurrentDirectory & "\onenote_tray.py""", 0, False
Set shell = Nothing
