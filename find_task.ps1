# find_task.ps1 - Find scheduled tasks related to PRN/PDF reformatting
Get-ScheduledTask | Where-Object {
    $_.TaskName -match 'prn|pdf|reformat|print' -or
    ($_.Actions | Where-Object { $_.Execute -match 'prn|pdf|reformat' })
} | ForEach-Object {
    $task = $_
    Write-Host "=== Task: $($task.TaskName) ===" -ForegroundColor Cyan
    Write-Host "  Path:  $($task.TaskPath)"
    Write-Host "  State: $($task.State)"
    $task.Actions | ForEach-Object {
        Write-Host "  Execute: $($_.Execute)"
        Write-Host "  Args:    $($_.Arguments)"
    }
    $task.Settings | Select-Object Hidden, ExecutionTimeLimit | Format-List
}
