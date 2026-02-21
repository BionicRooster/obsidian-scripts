# Find any COM add-ins registered for OneNote (or any Office app) and show
# how their CLSID is registered in HKLM, so we can mirror the pattern.

$addinPaths = @(
    "HKLM:\Software\Microsoft\Office\OneNote\Addins",
    "HKLM:\Software\Microsoft\Office\16.0\OneNote\Addins",
    "HKCU:\Software\Microsoft\Office\OneNote\Addins",
    "HKCU:\Software\Microsoft\Office\16.0\OneNote\Addins"
)

foreach ($path in $addinPaths) {
    if (-not (Test-Path $path)) { continue }
    $addins = Get-ChildItem $path
    foreach ($addin in $addins) {
        $progId = $addin.PSChildName
        Write-Host "`n=== $progId (from $path) ===" -ForegroundColor Cyan
        Get-ItemProperty $addin.PSPath | Format-List FriendlyName, LoadBehavior

        # Look up the CLSID for this ProgId
        $clsidVal = $null
        foreach ($root in @("HKLM:\Software\Classes", "HKCU:\Software\Classes")) {
            $pk = "$root\$progId\CLSID"
            if (Test-Path $pk) {
                $clsidVal = (Get-ItemProperty $pk)."(default)"
                Write-Host "  ProgId -> CLSID: $clsidVal (from $root)"
                break
            }
        }

        if ($clsidVal) {
            foreach ($root in @("HKLM:\Software\Classes", "HKCU:\Software\Classes")) {
                $ik = "$root\CLSID\$clsidVal\InprocServer32"
                if (Test-Path $ik) {
                    Write-Host "  InprocServer32 (from $root):" -ForegroundColor Yellow
                    Get-ItemProperty $ik | Format-List
                    break
                }
            }
        }
    }
}

# Also look for any .NET COM add-ins in HKLM via Implemented Categories
Write-Host "`n=== .NET COM classes in HKLM (Implemented Categories) ===" -ForegroundColor Cyan
$netCatGuid = "{62C8FE65-4EBB-45e7-B440-6E39B2CDBF29}"
$clsidRoot = "HKLM:\Software\Classes\CLSID"
if (Test-Path $clsidRoot) {
    Get-ChildItem $clsidRoot | Where-Object {
        Test-Path "$($_.PSPath)\Implemented Categories\$netCatGuid"
    } | ForEach-Object {
        Write-Host "  CLSID: $($_.PSChildName)"
        $ip = "$($_.PSPath)\InprocServer32"
        if (Test-Path $ip) {
            Get-ItemProperty $ip | Select-Object "(default)", Class, CodeBase | Format-List
        }
    }
}
