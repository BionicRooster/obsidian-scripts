# Script to delete empty orphan files

$inputFile = "C:\Users\awt\PowerShell\empty_orphans.json"
$logFile = "C:\Users\awt\PowerShell\logs\deleted_orphans.log"

# Load the list of empty orphans
$orphans = Get-Content $inputFile | ConvertFrom-Json

Write-Host "Deleting $($orphans.Count) empty orphan files..."

$deleted = 0
$failed = 0

foreach ($orphan in $orphans) {
    $path = $orphan.Path

    if (Test-Path $path) {
        try {
            Remove-Item -Path $path -Force -ErrorAction Stop
            $deleted++

            # Log deletion
            $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | DELETED | $path"
            Add-Content -Path $logFile -Value $logEntry

            Write-Host "Deleted: $($orphan.Title)"
        } catch {
            $failed++
            Write-Host "FAILED: $($orphan.Title) - $($_.Exception.Message)"
        }
    } else {
        Write-Host "SKIP (not found): $($orphan.Title)"
    }
}

Write-Host "`n=========================================="
Write-Host "SUMMARY"
Write-Host "=========================================="
Write-Host "Deleted: $deleted"
Write-Host "Failed: $failed"
Write-Host "Log: $logFile"
