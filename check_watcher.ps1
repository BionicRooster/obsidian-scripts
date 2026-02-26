# check_watcher.ps1 - Verify the PRN watcher is running hidden in the background
Write-Host "=== PowerShell processes ===" -ForegroundColor Cyan
Get-Process powershell -ErrorAction SilentlyContinue | ForEach-Object {
    $p = $_
    $window = if ($p.MainWindowHandle -eq 0) { 'HIDDEN' } else { 'VISIBLE' }
    Write-Host "  PID $($p.Id)  Window=$window  CPU=$([math]::Round($p.CPU,1))s  Mem=$([math]::Round($p.WorkingSet/1MB,1))MB  Started=$($p.StartTime.ToString('HH:mm:ss'))"
}

Write-Host "`n=== Scheduled Task state ===" -ForegroundColor Cyan
$t = Get-ScheduledTask -TaskName 'PRN File Watcher'
Write-Host "  State:    $($t.State)"
Write-Host "  Execute:  $($t.Actions.Execute)"
Write-Host "  Args:     $($t.Actions.Arguments)"

$info = Get-ScheduledTaskInfo -TaskName 'PRN File Watcher'
Write-Host "  Last Run: $($info.LastRunTime)"
Write-Host "  Last Res: $($info.LastTaskResult)"
Write-Host "  Next Run: $($info.NextRunTime)"
