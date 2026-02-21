# Find and delete directories with .md extension (should be files)
$Path = "D:\Obsidian\Main\20 - Permanent Notes"

# Find directories that have .md in name
$mdDirs = Get-ChildItem -Path $Path -Directory | Where-Object { $_.Name -like "*.md" }

Write-Host "Found $($mdDirs.Count) directories with .md extension:" -ForegroundColor Cyan

foreach ($dir in $mdDirs) {
    Write-Host "  - $($dir.Name)" -ForegroundColor Yellow

    # Check if directory is empty
    $contents = Get-ChildItem -Path $dir.FullName -ErrorAction SilentlyContinue
    if ($contents) {
        Write-Host "    WARNING: Directory not empty!" -ForegroundColor Red
    } else {
        Write-Host "    Deleting empty directory..." -ForegroundColor Green
        Remove-Item -LiteralPath $dir.FullName -Force
    }
}

# Count remaining
$remaining = Get-ChildItem -Path $Path -Directory | Where-Object { $_.Name -like "*.md" }
Write-Host "`nRemaining .md directories: $($remaining.Count)" -ForegroundColor Green
