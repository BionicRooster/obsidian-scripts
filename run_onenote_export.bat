@echo off
:: run_onenote_export.bat
:: Double-click this file (or bind it to a hotkey) to export the
:: currently focused OneNote page to your Obsidian vault.
cd /d "%~dp0"
python onenote_to_obsidian.py
if %ERRORLEVEL% NEQ 0 pause
