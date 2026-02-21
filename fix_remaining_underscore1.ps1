# Fix remaining _1 files - direct rename approach
$Path = "D:\Obsidian\Main"

# Get all _1 files
$files = Get-ChildItem -Path $Path -Filter "*_1.md" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $files) {
    if (-not $file.DirectoryName) { continue }

    $baseName = $file.BaseName -replace '_1$', ''
    $newName = "$baseName$($file.Extension)"
    $newPath = Join-Path $file.DirectoryName $newName

    Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan

    if (Test-Path -LiteralPath $newPath) {
        # Delete the collision file first
        Write-Host "  Deleting collision: $newPath" -ForegroundColor Yellow
        Remove-Item -LiteralPath $newPath -Force
        Start-Sleep -Milliseconds 200
    }

    # Rename the _1 file
    Write-Host "  Renaming to: $newName" -ForegroundColor Green
    Rename-Item -LiteralPath $file.FullName -NewName $newName
}

Write-Host "`nDone!" -ForegroundColor Green

# Check remaining
$remaining = Get-ChildItem -Path $Path -Filter "*_1.md" -Recurse -ErrorAction SilentlyContinue
Write-Host "Remaining _1 files: $($remaining.Count)"
