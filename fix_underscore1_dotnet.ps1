# Fix remaining _1 files using .NET directly
$Path = "D:\Obsidian\Main\20 - Permanent Notes"

# Get all _1 files
$files = Get-ChildItem -Path $Path -Filter "*_1.md" -ErrorAction SilentlyContinue

$renamed = 0
$deleted = 0

foreach ($file in $files) {
    # Skip files without proper DirectoryName
    if (-not $file.DirectoryName) { continue }

    # Handle special cases where _1 is part of the name but not a suffix pattern
    if ($file.BaseName -match '_1$') {
        $baseName = $file.BaseName -replace '_1$', ''
    } else {
        Write-Host "Skipping (no _1 suffix): $($file.Name)" -ForegroundColor Gray
        continue
    }

    $newName = "$baseName.md"
    $newPath = [System.IO.Path]::Combine($file.DirectoryName, $newName)

    Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan

    # Check if collision file exists
    if ([System.IO.File]::Exists($newPath)) {
        Write-Host "  Deleting collision: $newName" -ForegroundColor Yellow
        try {
            [System.IO.File]::Delete($newPath)
            $deleted++
            Start-Sleep -Milliseconds 100
        } catch {
            Write-Host "  ERROR deleting: $_" -ForegroundColor Red
            continue
        }
    }

    # Rename the _1 file
    Write-Host "  Renaming to: $newName" -ForegroundColor Green
    try {
        [System.IO.File]::Move($file.FullName, $newPath)
        $renamed++
    } catch {
        Write-Host "  ERROR renaming: $_" -ForegroundColor Red
    }
}

Write-Host "`n========== SUMMARY ==========" -ForegroundColor Green
Write-Host "Files deleted: $deleted"
Write-Host "Files renamed: $renamed"

# Check remaining
$remaining = Get-ChildItem -Path $Path -Filter "*_1.md" -ErrorAction SilentlyContinue
Write-Host "Remaining _1 files: $($remaining.Count)"
