# Delete .md files with long paths using \\?\ prefix
$vaultPath = "D:\Obsidian\Main"

Write-Host "Finding remaining .md files in .resources folders..."

# Get list of .md files in .resources folders
$mdFiles = cmd /c "dir /s /b `"$vaultPath\*.md`" 2>nul" | Where-Object { $_ -match '\.resources[\\\/]' }

$count = ($mdFiles | Measure-Object).Count
Write-Host "Found $count .md files in .resources folders"

$deleted = 0
$failed = 0
$failedFiles = @()

foreach ($file in $mdFiles) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }

    # Try with long path prefix
    $longPath = "\\?\$file"

    try {
        # Try .NET with long path
        [System.IO.File]::Delete($longPath)
        $deleted++
    } catch {
        try {
            # Try regular Remove-Item
            Remove-Item -LiteralPath $file -Force -ErrorAction Stop
            $deleted++
        } catch {
            $failed++
            $failedFiles += $file
        }
    }
}

Write-Host ""
Write-Host "================================"
Write-Host "Deletion complete!"
Write-Host "Files deleted: $deleted"
Write-Host "Failed: $failed"
Write-Host "================================"

if ($failed -gt 0 -and $failed -le 20) {
    Write-Host ""
    Write-Host "Failed files:"
    foreach ($f in $failedFiles) {
        Write-Host "  $f"
    }
}
