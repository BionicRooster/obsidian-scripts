$gac = Get-ChildItem 'C:\Program Files (x86)\Microsoft SDKs' -Recurse -Filter 'gacutil.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($gac) { Write-Host "gacutil: $($gac.FullName)" } else { Write-Host "gacutil: not found" }

$sec = "HKCU:\Software\Microsoft\Office\16.0\OneNote\Security"
if (Test-Path $sec) {
    Write-Host "Security key:"
    Get-ItemProperty $sec | Format-List
} else {
    Write-Host "No Office\16.0\OneNote\Security key"
}
