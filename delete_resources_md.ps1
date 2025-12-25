# Delete .md files inside .resources folders, keeping images/attachments
$vaultPath = "D:\Obsidian\Main"

Write-Host "Searching for .md files inside .resources folders..."

# Use cmd to find files (handles long paths better)
$mdFilesInResources = cmd /c "dir /s /b `"$vaultPath\*.md`" 2>nul" | Where-Object { $_ -match '\.resources[\\\/]' }

$count = ($mdFilesInResources | Measure-Object).Count
Write-Host "Found $count .md files inside .resources folders"
Write-Host ""

$deleted = 0
$failed = 0

foreach ($file in $mdFilesInResources) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }

    try {
        # Use cmd del to handle long paths
        $result = cmd /c "del `"$file`" 2>&1"
        if ($LASTEXITCODE -eq 0) {
            $deleted++
            if ($deleted % 100 -eq 0) {
                Write-Host "Deleted $deleted files..."
            }
        } else {
            $failed++
        }
    } catch {
        $failed++
    }
}

Write-Host ""
Write-Host "================================"
Write-Host "Deletion complete!"
Write-Host "Files deleted: $deleted"
Write-Host "Failed: $failed"
Write-Host "================================"
