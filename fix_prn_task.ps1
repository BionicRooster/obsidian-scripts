# fix_prn_task.ps1
# Stops, deletes, and recreates the PRN File Watcher scheduled task so it runs
# completely hidden via a VBScript launcher (wscript.exe -> run_prn_watcher.vbs).
# This prevents any visible PowerShell terminal from appearing on logon.

$taskName   = 'PRN File Watcher'           # Existing task name to replace
$vbsLauncher = 'C:\Users\awt\run_prn_watcher.vbs'  # VBScript that hides the PS window
$wscript    = 'wscript.exe'                # Windows Script Host executable

# -- 1. Stop any currently running instance --
Write-Host "Stopping running instance (if any)..." -ForegroundColor Yellow
$running = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue |
           Where-Object { $_.State -eq 'Running' }
if ($running) {
    Stop-ScheduledTask -TaskName $taskName
    Write-Host "  Stopped." -ForegroundColor Green
} else {
    Write-Host "  Not running." -ForegroundColor DarkGray
}

# -- 2. Unregister the old task --
Write-Host "Removing old task..." -ForegroundColor Yellow
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
Write-Host "  Removed." -ForegroundColor Green

# -- 3. Build new task components --

# Action: run wscript.exe with the VBScript launcher (wscript itself is always hidden)
$action = New-ScheduledTaskAction `
    -Execute   $wscript `
    -Argument  "`"$vbsLauncher`"" `
    -WorkingDirectory 'C:\Users\awt'

# Trigger: on logon for the current user (same as before)
$trigger = New-ScheduledTaskTrigger -AtLogon -User $env:USERNAME

# Settings: allow on demand, no battery restrictions, no instance overlap
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Seconds 0)   # 0 = no time limit

# Principal: run as the current user with interactive token (logon session)
$principal = New-ScheduledTaskPrincipal `
    -UserId    $env:USERNAME `
    -LogonType Interactive `
    -RunLevel  Limited

# -- 4. Register the new task --
Write-Host "Registering new task..." -ForegroundColor Yellow
Register-ScheduledTask `
    -TaskName   $taskName `
    -Action     $action `
    -Trigger    $trigger `
    -Settings   $settings `
    -Principal  $principal `
    -Description 'Monitors for .prn files and converts them to .md' |
    Out-Null
Write-Host "  Registered." -ForegroundColor Green

# -- 5. Start the task now --
Write-Host "Starting task..." -ForegroundColor Yellow
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 2

# -- 6. Verify it is running --
$state = (Get-ScheduledTask -TaskName $taskName).State
Write-Host "  State: $state" -ForegroundColor Cyan

if ($state -eq 'Running') {
    Write-Host "`nSuccess: '$taskName' is running hidden via VBScript launcher." -ForegroundColor Green
} else {
    Write-Host "`nNote: State is '$state' - watcher script may have completed its startup phase." -ForegroundColor Yellow
    Write-Host 'Check that watch_prn_files.ps1 is running in the background.' -ForegroundColor Yellow
}
