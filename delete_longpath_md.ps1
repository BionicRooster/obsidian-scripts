# Delete .md files with long paths using subst workaround
$vaultPath = "D:\Obsidian\Main"

Write-Host "Finding remaining .md files in .resources folders with long paths..."

# Map a drive letter to shorten the base path
$driveLetter = "Z:"
$substed = $false

# Remove existing subst if any
cmd /c "subst $driveLetter /d 2>nul"

# Create subst
cmd /c "subst $driveLetter `"$vaultPath`""
if ($LASTEXITCODE -eq 0) {
    $substed = $true
    Write-Host "Mapped $driveLetter to $vaultPath"
} else {
    Write-Host "Failed to create drive mapping, trying direct approach..."
}

$deleted = 0
$failed = 0
$failedFiles = @()

if ($substed) {
    # Find .md files in .resources folders using the shorter path
    $mdFiles = cmd /c "dir /s /b `"$driveLetter\*.md`" 2>nul" | Where-Object { $_ -match '\.resources[\\\/]' }

    $count = ($mdFiles | Measure-Object).Count
    Write-Host "Found $count .md files in .resources folders"

    foreach ($file in $mdFiles) {
        if ([string]::IsNullOrWhiteSpace($file)) { continue }

        try {
            Remove-Item -LiteralPath $file -Force -ErrorAction Stop
            $deleted++
        } catch {
            # Try cmd del as fallback
            $result = cmd /c "del /f `"$file`" 2>&1"
            if ($LASTEXITCODE -eq 0) {
                $deleted++
            } else {
                $failed++
                $failedFiles += $file
            }
        }
    }
}

# Clean up subst
if ($substed) {
    cmd /c "subst $driveLetter /d 2>nul"
    Write-Host "Removed drive mapping"
}

Write-Host ""
Write-Host "================================"
Write-Host "Deletion complete!"
Write-Host "Files deleted: $deleted"
Write-Host "Failed: $failed"
Write-Host "================================"

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Failed files:"
    foreach ($f in $failedFiles) {
        Write-Host "  $f"
    }
}
