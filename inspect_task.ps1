# inspect_task.ps1 - Show full configuration of PRN File Watcher task
$task = Get-ScheduledTask -TaskName 'PRN File Watcher'

Write-Host "=== Task Details ===" -ForegroundColor Cyan
Write-Host "Name:    $($task.TaskName)"
Write-Host "State:   $($task.State)"
Write-Host "Author:  $($task.Author)"

Write-Host "`n--- Actions ---"
$task.Actions | ForEach-Object {
    Write-Host "  Execute:   $($_.Execute)"
    Write-Host "  Arguments: $($_.Arguments)"
    Write-Host "  WorkDir:   $($_.WorkingDirectory)"
}

Write-Host "`n--- Triggers ---"
$task.Triggers | ForEach-Object {
    Write-Host "  $_"
}

Write-Host "`n--- Settings ---"
$task.Settings | Format-List

Write-Host "`n--- Principal (Run As) ---"
$task.Principal | Format-List

# Also export to XML to see everything
$xml = Export-ScheduledTask -TaskName 'PRN File Watcher'
Write-Host "`n--- Full XML ---"
Write-Host $xml
