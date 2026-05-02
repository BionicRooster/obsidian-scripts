# fix_docx_preview.ps1
# Fixes File Explorer preview pane not showing .docx and other Word files.
# Covers three scenarios:
#   1. Preview pane disabled in Explorer settings
#   2. Word preview handler not registered for .docx extension
#   3. 32-bit Office on 64-bit Windows (handler present but not loadable by 64-bit Explorer)

# --- Require Administrator privileges ---
# The HKLM registry paths below require elevation.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator. Re-launching elevated..."
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- GUID for the Microsoft Word Preview Handler ---
# This is the COM CLSID registered by Office for previewing Word documents.
$wordPreviewGuid = "{84F66100-FF7C-4fb4-B0C0-02CD7FB668FE}"

# --- Extensions to register the Word preview handler for ---
# Covers the main Word formats: modern (.docx, .docm) and legacy (.doc, .dot, .dotx, .dotm)
$wordExtensions = @(".doc", ".docx", ".docm", ".dot", ".dotx", ".dotm")

# --- ShellEx subkey used by File Explorer for preview handlers ---
$previewShellExKey = "ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}"

Write-Host "`n=== Step 1: Enable preview pane in Explorer settings ===" -ForegroundColor Cyan

# HKCU path that controls whether the preview pane is shown
$explorerAdvanced = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# EnablePreviewPane = 1 turns the preview pane on
Set-ItemProperty -Path $explorerAdvanced -Name "EnablePreviewPane" -Value 1 -Type DWord -Force
Write-Host "  EnablePreviewPane set to 1"

# AlwaysShowIcons = 0 allows thumbnails and previews (1 disables them)
Set-ItemProperty -Path $explorerAdvanced -Name "AlwaysShowIcons" -Value 0 -Type DWord -Force
Write-Host "  AlwaysShowIcons set to 0 (previews/thumbnails allowed)"

Write-Host "`n=== Step 2: Register Word preview handler for Word extensions ===" -ForegroundColor Cyan

foreach ($ext in $wordExtensions) {
    # Registry path under HKCR for each file extension's ShellEx preview handler
    $regPath = "Registry::HKEY_CLASSES_ROOT\$ext\$previewShellExKey"

    # Create the key if it doesn't exist, then set the default value to the Word handler GUID
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value $wordPreviewGuid -Force
    Write-Host "  Registered handler for $ext"
}

Write-Host "`n=== Step 3: Register handler in 64-bit PreviewHandlers list ===" -ForegroundColor Cyan

# HKLM path where named preview handlers are listed for 64-bit Explorer.
# Adding the Word handler GUID here allows 64-bit Explorer to find and load
# the 32-bit Word preview handler via surrogate hosting (AppID WOW64 bridge).
$previewHandlerKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers"

if (-not (Test-Path $previewHandlerKey)) {
    New-Item -Path $previewHandlerKey -Force | Out-Null
}
Set-ItemProperty -Path $previewHandlerKey -Name $wordPreviewGuid -Value "Microsoft Word previewer" -Force
Write-Host "  Added '$wordPreviewGuid' to 64-bit PreviewHandlers list"

# Also register in the WOW6432Node path for completeness (used by some Office versions)
$previewHandlerKeyWow = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\PreviewHandlers"

if (-not (Test-Path $previewHandlerKeyWow)) {
    New-Item -Path $previewHandlerKeyWow -Force | Out-Null
}
Set-ItemProperty -Path $previewHandlerKeyWow -Name $wordPreviewGuid -Value "Microsoft Word previewer" -Force
Write-Host "  Added '$wordPreviewGuid' to WOW6432Node PreviewHandlers list"

Write-Host "`n=== Step 4: Restart Windows Explorer to apply changes ===" -ForegroundColor Cyan

# Kill Explorer and let Windows restart it automatically (standard approach)
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# If Explorer didn't auto-restart, launch it manually
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer
}

Write-Host "  Explorer restarted"

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Open File Explorer, click a .docx file, and check the preview pane."
Write-Host "If previews still don't appear, try: Start > Apps > Microsoft Office > Modify > Quick Repair"
