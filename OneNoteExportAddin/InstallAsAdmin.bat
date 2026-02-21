@echo off
:: InstallAsAdmin.bat
:: Run this ONE TIME as Administrator to register the COM add-in in HKLM.
:: After this, the "Export to Obsidian" button will appear in OneNote's ribbon.
::
:: How to run:
::   Right-click this file -> "Run as administrator"

echo Installing OneNote Obsidian Export add-in (admin)...
echo.

set DLL=C:\Users\awt\OneNoteExportAddin\bin\Release\net48\OneNoteExportAddin.dll
set REGASM=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe
set PROGID=OneNoteExportAddin.Connect

:: 1. Register the COM server in HKLM (requires admin)
echo Step 1: Registering COM server...
"%REGASM%" "%DLL%" /codebase /tlb
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: RegAsm failed. Make sure you right-clicked and chose "Run as administrator".
    pause
    exit /b 1
)
echo   Done.

:: 2. Add the OneNote add-in key (version-less path, HKCU -- no admin needed)
echo Step 2: Registering OneNote add-in key...
reg add "HKCU\Software\Microsoft\Office\OneNote\Addins\%PROGID%" /v "FriendlyName"    /t REG_SZ   /d "Export to Obsidian"                                   /f
reg add "HKCU\Software\Microsoft\Office\OneNote\Addins\%PROGID%" /v "Description"     /t REG_SZ   /d "Exports the current OneNote page to your Obsidian vault" /f
reg add "HKCU\Software\Microsoft\Office\OneNote\Addins\%PROGID%" /v "LoadBehavior"    /t REG_DWORD /d 3 /f
reg add "HKCU\Software\Microsoft\Office\OneNote\Addins\%PROGID%" /v "CommandLineSafe" /t REG_DWORD /d 0 /f
echo   Done.

echo.
echo Installation complete!
echo Close and reopen OneNote -- you should see the Export tab in the ribbon.
echo.
pause
