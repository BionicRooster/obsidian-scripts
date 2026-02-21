# Check all Office Resiliency keys that might be blocking our add-in
$roots = @(
    "HKCU:\Software\Microsoft\Office\16.0\OneNote\Resiliency",
    "HKCU:\Software\Microsoft\Office\OneNote\Resiliency",
    "HKCU:\Software\Microsoft\Office\16.0\Common\Add-In Manager",
    "HKCU:\Software\Microsoft\Office\16.0\WEF",
    "HKCU:\Software\Microsoft\Office\16.0\OneNote\AddInLoadTimes"
)

foreach ($r in $roots) {
    if (Test-Path $r) {
        Write-Host "=== $r ===" -ForegroundColor Yellow
        Get-ItemProperty $r -ErrorAction SilentlyContinue | Format-List
        Get-ChildItem $r -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  SubKey: $($_.PSChildName)"
            Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue | Format-List
        }
    } else {
        Write-Host "Not found: $r"
    }
}

# Also check event log more specifically around the time OneNote loaded
Write-Host "`n=== Recent Application errors ===" -ForegroundColor Cyan
Get-WinEvent -LogName Application -MaxEvents 20 -ErrorAction SilentlyContinue |
    Where-Object { $_.Level -le 3 } |
    Select-Object TimeCreated, LevelDisplayName, ProviderName, Message |
    Format-List
