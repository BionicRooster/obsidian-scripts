$log = 'C:\Users\awt\onenote_tray.log'
$before = (Get-Content $log).Count
Write-Host "Watching log ($before lines)... click the tray icon now"
$elapsed = 0
while ($elapsed -lt 30) {
    Start-Sleep -Seconds 1
    $elapsed++
    $lines = Get-Content $log
    if ($lines.Count -gt $before) {
        Write-Host "New log entries after ${elapsed}s:"
        $lines | Select-Object -Last ($lines.Count - $before + 2)
        exit 0
    }
}
Write-Host "No new entries after 30s - click was not registered"
