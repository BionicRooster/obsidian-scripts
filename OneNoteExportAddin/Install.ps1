# Install.ps1
#
# Registers the OneNoteExportAddin COM add-in for the current user only.
# Does NOT require administrator rights — all keys go under HKCU.
#
# Run once:
#   powershell -ExecutionPolicy Bypass -File "C:\Users\awt\OneNoteExportAddin\Install.ps1"
#
# To uninstall, run Uninstall.ps1 (or delete the same registry keys).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Paths and identifiers — must match Connect.cs exactly
# ---------------------------------------------------------------------------

# $DllPath : absolute path to the compiled add-in DLL
$DllPath   = "C:\Users\awt\OneNoteExportAddin\bin\Release\net48\OneNoteExportAddin.dll"

# $Clsid   : the [Guid] on the Connect class in Connect.cs
$Clsid     = "{C1E7A840-D4B5-4E8B-B63F-0A4E7C3A9E1F}"

# $ProgId  : the [ProgId] on the Connect class in Connect.cs
$ProgId    = "OneNoteExportAddin.Connect"

# $AsmName : full assembly identity used by the CLR to load the DLL
$AsmName   = "OneNoteExportAddin, Version=1.0.0.0, Culture=neutral"

# $Runtime : the .NET Framework runtime version the DLL targets
$Runtime   = "v4.0.30319"

# ---------------------------------------------------------------------------
# Verify the DLL exists before touching the registry
# ---------------------------------------------------------------------------

if (-not (Test-Path $DllPath)) {
    Write-Error "DLL not found at: $DllPath`nRun 'dotnet build -c Release' in the project folder first."
    exit 1
}

Write-Host "Installing OneNote Obsidian Export add-in..." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 1. COM server registration under HKCU\Software\Classes
#
# These keys teach Windows/COM how to locate and load our DLL when a caller
# asks for the ProgId or CLSID.  Equivalent to what RegAsm /codebase writes
# to HKLM, but scoped to the current user only.
# ---------------------------------------------------------------------------

# file:// URI used in the CodeBase value (forward slashes, URL-encoded)
$CodeBase = "file:///" + $DllPath.Replace("\", "/")

# ---- CLSID key ----
$ClsidBase = "HKCU:\Software\Classes\CLSID\$Clsid"

# Default value: human-readable class name
New-Item         -Path $ClsidBase -Force | Out-Null
Set-ItemProperty -Path $ClsidBase -Name "(Default)" -Value $ProgId

# ---- InprocServer32 ----
# mscoree.dll is the CLR host; it reads the extra values to know which
# managed assembly to load.
$InProc = "$ClsidBase\InprocServer32"
New-Item         -Path $InProc -Force | Out-Null
Set-ItemProperty -Path $InProc -Name "(Default)"      -Value "mscoree.dll"
Set-ItemProperty -Path $InProc -Name "Class"          -Value $ProgId
Set-ItemProperty -Path $InProc -Name "Assembly"       -Value $AsmName
Set-ItemProperty -Path $InProc -Name "RuntimeVersion" -Value $Runtime
Set-ItemProperty -Path $InProc -Name "CodeBase"       -Value $CodeBase
Set-ItemProperty -Path $InProc -Name "ThreadingModel" -Value "Both"

Write-Host "  COM CLSID registered: $Clsid"

# ---- ProgId → CLSID mapping ----
$ProgIdKey = "HKCU:\Software\Classes\$ProgId"
New-Item         -Path $ProgIdKey            -Force | Out-Null
Set-ItemProperty -Path $ProgIdKey -Name "(Default)" -Value $ProgId

$ProgIdClsid = "$ProgIdKey\CLSID"
New-Item         -Path $ProgIdClsid -Force | Out-Null
Set-ItemProperty -Path $ProgIdClsid -Name "(Default)" -Value $Clsid

Write-Host "  ProgId registered: $ProgId"

# ---------------------------------------------------------------------------
# 2. OneNote add-in registration
#
# HKCU\Software\Microsoft\Office\OneNote\Addins\{ProgId}
# tells OneNote to load this add-in at startup (LoadBehavior = 3).
# ---------------------------------------------------------------------------

$AddinKey = "HKCU:\Software\Microsoft\Office\OneNote\Addins\$ProgId"
New-Item         -Path $AddinKey -Force | Out-Null

# FriendlyName: displayed in the OneNote COM Add-ins dialog
Set-ItemProperty -Path $AddinKey -Name "FriendlyName"   -Value "Export to Obsidian"

# Description: tooltip text in the COM Add-ins dialog
Set-ItemProperty -Path $AddinKey -Name "Description"    -Value "Exports the current OneNote page to your Obsidian vault"

# LoadBehavior: 3 = load at startup and connect immediately
#   0 = disconnected, 1 = connected, 2 = load at startup, 3 = startup+connect
Set-ItemProperty -Path $AddinKey -Name "LoadBehavior"   -Value 3 -Type DWord

# CommandLineSafe: 0 = not safe to load during command-line automation
Set-ItemProperty -Path $AddinKey -Name "CommandLineSafe" -Value 0 -Type DWord

Write-Host "  OneNote add-in key registered"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "Restart OneNote and look for the 'Export' tab in the ribbon."
