# register_pdf_watcher_task.ps1
# Creates a Task Scheduler entry for the PDF watcher daemon.
# Mirrors the "PRN File Watcher" task configuration exactly.

# task_name: display name shown in Task Scheduler
$task_name = "PDF File Watcher"

# action: run wscript.exe with the VBS wrapper, working dir C:\Users\awt
$action = New-ScheduledTaskAction `
    -Execute  "wscript.exe" `
    -Argument '"C:\Users\awt\run_pdf_watcher.vbs"' `
    -WorkingDirectory "C:\Users\awt"

# trigger: at logon for the current user (same as PRN File Watcher)
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"

# settings: allow the task to run indefinitely; don't stop on battery
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit 0 `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

# principal: run as the current user (interactive, not elevated)
$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

# Register (or replace if it already exists)
Register-ScheduledTask `
    -TaskName  $task_name `
    -Action    $action `
    -Trigger   $trigger `
    -Settings  $settings `
    -Principal $principal `
    -Force | Out-Null

# Confirm registration
$t    = Get-ScheduledTask -TaskName $task_name
$info = Get-ScheduledTaskInfo -TaskName $task_name

Write-Host "Task registered: $($t.TaskName)"
Write-Host "  State   : $($t.State)"
Write-Host "  Execute : $($t.Actions.Execute)"
Write-Host "  Args    : $($t.Actions.Arguments)"
Write-Host "  Trigger : AtLogOn"
Write-Host "  Last Run: $($info.LastRunTime)"
