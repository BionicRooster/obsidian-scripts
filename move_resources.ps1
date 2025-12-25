# Move Evernote _resources to 00 - Images
$source = "D:\Obsidian\Main\11 - Evernote\_resources"
$dest = "D:\Obsidian\Main\00 - Images\Evernote-Resources"

# Create destination if it doesn't exist
if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

# Use robocopy to move files (handles long paths better)
$robocopyArgs = @(
    "`"$source`"",
    "`"$dest`"",
    "/E",      # Copy subdirectories including empty ones
    "/MOVE",   # Move files and dirs (delete from source after copying)
    "/R:1",    # Retry once on failed copies
    "/W:1",    # Wait 1 second between retries
    "/NFL",    # No file list
    "/NDL",    # No directory list
    "/NP"      # No progress
)

Write-Host "Moving resources from:"
Write-Host "  Source: $source"
Write-Host "  Dest: $dest"
Write-Host ""

$process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
$exitCode = $process.ExitCode

# Robocopy exit codes: 0-7 are success, 8+ are errors
if ($exitCode -lt 8) {
    Write-Host "Move completed successfully!"

    # Try to remove the source directory if empty
    if (Test-Path $source) {
        try {
            Remove-Item $source -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Source directory removed."
        } catch {
            Write-Host "Note: Source directory may have some remaining items."
        }
    }
} else {
    Write-Host "Some errors occurred during move. Exit code: $exitCode"
}

# Count what was moved
$movedCount = (Get-ChildItem $dest -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host ""
Write-Host "Files now in destination: $movedCount"
