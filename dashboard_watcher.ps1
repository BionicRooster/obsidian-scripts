# Watches C:\Users\awt\dashboard.html for changes and copies it to the IIS
# serving location automatically. Run once via the install script; after that
# it starts on every login via a scheduled task.

$src  = "C:\Users\awt\dashboard.html"          # file Claude edits
$dest = "C:\inetpub\dashboard\dashboard.html"  # file IIS serves

# FileSystemWatcher monitors the directory for changes to the specific file.
$watcher            = New-Object System.IO.FileSystemWatcher
$watcher.Path       = [System.IO.Path]::GetDirectoryName($src)   # C:\Users\awt
$watcher.Filter     = [System.IO.Path]::GetFileName($src)        # dashboard.html
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite      # fire on save

# Action block: copy the file when a change is detected.
# Brief sleep lets the editor finish writing before we read the file.
$action = {
    Start-Sleep -Milliseconds 600
    try {
        Copy-Item -Path $src -Destination $dest -Force
        $ts = Get-Date -Format "HH:mm:ss"
        "[${ts}] dashboard.html copied to IIS" | Out-File -Append "C:\Users\awt\dashboard_watcher.log"
    } catch {
        $ts = Get-Date -Format "HH:mm:ss"
        "[${ts}] Copy failed: $_" | Out-File -Append "C:\Users\awt\dashboard_watcher.log"
    }
}

# Register the Changed event and start watching.
$null = Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action
$watcher.EnableRaisingEvents = $true

"[$(Get-Date -Format 'HH:mm:ss')] Watcher started — monitoring $src" |
    Out-File -Append "C:\Users\awt\dashboard_watcher.log"

# Keep the script alive indefinitely.
while ($true) { Start-Sleep -Seconds 10 }
