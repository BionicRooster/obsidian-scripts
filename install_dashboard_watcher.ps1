#Requires -RunAsAdministrator
# Installs dashboard_watcher.ps1 as a scheduled task that runs elevated,
# hidden, at every login for the current user. Run this once.

$taskName   = "DashboardFileWatcher"
$scriptPath = "C:\Users\awt\dashboard_watcher.ps1"

# Remove any previous version of this task so re-running is safe.
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Action: launch pwsh hidden, bypassing execution policy, running the watcher.
$action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument "-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`""

# Trigger: fire when the current user logs on.
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Principal: run as the current user with highest available privileges (admin).
$principal = New-ScheduledTaskPrincipal `
    -UserId   $env:USERNAME `
    -RunLevel Highest `
    -LogonType Interactive

# Settings: allow the task to run on battery, don't stop it, no time limit.
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit      ([TimeSpan]::Zero) `
    -DisallowStartIfOnBatteries:$false `
    -StopIfGoingOnBatteries:$false

Register-ScheduledTask `
    -TaskName  $taskName `
    -Action    $action `
    -Trigger   $trigger `
    -Principal $principal `
    -Settings  $settings `
    -Force | Out-Null

# Start it right now so you don't have to log out and back in.
Start-ScheduledTask -TaskName $taskName

Write-Host "Watcher installed and started." -ForegroundColor Green
Write-Host "Log: C:\Users\awt\dashboard_watcher.log" -ForegroundColor Cyan
Write-Host "It will restart automatically on every login." -ForegroundColor Cyan
