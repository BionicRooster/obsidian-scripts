# Check exactly what RegAsm wrote to HKLM
$clsid = "{C1E7A840-D4B5-4E8B-B63F-0A4E7C3A9E1F}"
$base  = "HKLM:\Software\Classes\CLSID\$clsid"

Write-Host "=== CLSID root ===" -ForegroundColor Cyan
Get-ItemProperty $base -ErrorAction SilentlyContinue | Format-List

Write-Host "=== InprocServer32 ===" -ForegroundColor Cyan
Get-ItemProperty "$base\InprocServer32" | Format-List

Write-Host "=== ProgId ===" -ForegroundColor Cyan
Get-ItemProperty "$base\ProgId" -ErrorAction SilentlyContinue | Format-List

Write-Host "=== Implemented Categories ===" -ForegroundColor Cyan
Get-ChildItem "$base\Implemented Categories" -ErrorAction SilentlyContinue

Write-Host "=== HKLM ProgId lookup ===" -ForegroundColor Cyan
Get-ItemProperty "HKLM:\Software\Classes\OneNoteExportAddin.Connect\CLSID" -ErrorAction SilentlyContinue | Format-List

# Try to actually CoCreateInstance the object from a WScript.Shell VBScript
# to verify the HKLM registration works independent of PowerShell
Write-Host "=== Testing CoCreateInstance via VBScript ===" -ForegroundColor Cyan
$vbs = @"
On Error Resume Next
Set obj = CreateObject("OneNoteExportAddin.Connect")
If Err.Number = 0 Then
    WScript.Echo "SUCCESS: object created"
Else
    WScript.Echo "FAILED: " & Err.Number & " - " & Err.Description
End If
"@
$vbs | Set-Content "$env:TEMP\test_com.vbs"
$result = & cscript //NoLogo "$env:TEMP\test_com.vbs" 2>&1
Write-Host $result
