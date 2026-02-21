# watch_prn_files.ps1
# Purpose: Monitor D:\Obsidian\Main for .prn file arrivals and convert them to .md
# This script runs continuously and triggers conversion when .prn files appear

# Target directory to monitor for .prn files
$targetDir = "D:\Obsidian\Main"

# Log file path for tracking conversions
$logFile = "C:\Users\awt\prn_watcher.log"

# Function to write timestamped log entries
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    Write-Host $logEntry
}

# Function to convert a .prn file to .md
function Convert-PrnToMd {
    param([string]$FilePath)

    # Small delay to ensure file is fully written
    Start-Sleep -Milliseconds 500

    # Check if file still exists (might have been moved/deleted)
    if (-not (Test-Path $FilePath)) {
        Write-Log "File no longer exists: $FilePath"
        return
    }

    # Get the base name without extension
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    # Get the directory containing the file
    $directory = [System.IO.Path]::GetDirectoryName($FilePath)

    # Construct new .md file path
    $newPath = Join-Path $directory "$baseName.md"

    # Handle name collisions by adding numeric suffix
    $suffix = 1
    while (Test-Path $newPath) {
        $newPath = Join-Path $directory "${baseName}_$suffix.md"
        $suffix++
    }

    # Get just the new filename for logging
    $newFileName = [System.IO.Path]::GetFileName($newPath)
    $oldFileName = [System.IO.Path]::GetFileName($FilePath)

    try {
        # Rename .prn to .md
        Rename-Item -Path $FilePath -NewName $newFileName -ErrorAction Stop
        Write-Log "Converted: $oldFileName -> $newFileName"
    }
    catch {
        Write-Log "ERROR converting $oldFileName : $_"
    }
}

# Initialize log
Write-Log "=========================================="
Write-Log "PRN File Watcher started"
Write-Log "Monitoring: $targetDir"
Write-Log "=========================================="

# Create FileSystemWatcher to monitor the directory
$watcher = New-Object System.IO.FileSystemWatcher
# Set the path to watch
$watcher.Path = $targetDir
# Filter for .prn files only
$watcher.Filter = "*.prn"
# Watch for new files being created
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName
# Enable events
$watcher.EnableRaisingEvents = $true

# Register event handler for new file creation
$action = {
    # Get the full path of the new file from the event
    $path = $Event.SourceEventArgs.FullPath
    # Get the change type (Created, Changed, etc.)
    $changeType = $Event.SourceEventArgs.ChangeType

    # Only process Created events
    if ($changeType -eq "Created") {
        # Call the conversion function
        Convert-PrnToMd -FilePath $path
    }
}

# Register the Created event
$createdEvent = Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action

Write-Log "Watcher active. Press Ctrl+C to stop."

# Also process any existing .prn files on startup
$existingFiles = Get-ChildItem -Path $targetDir -Filter "*.prn" -File -ErrorAction SilentlyContinue
if ($existingFiles) {
    Write-Log "Found $($existingFiles.Count) existing .prn file(s) - converting..."
    foreach ($file in $existingFiles) {
        Convert-PrnToMd -FilePath $file.FullName
    }
}

# Keep script running indefinitely
try {
    while ($true) {
        # Wait loop - the watcher handles events asynchronously
        Wait-Event -Timeout 60
    }
}
finally {
    # Cleanup when script is stopped
    Unregister-Event -SourceIdentifier $createdEvent.Name
    $watcher.Dispose()
    Write-Log "Watcher stopped"
}
