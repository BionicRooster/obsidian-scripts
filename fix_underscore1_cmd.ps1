# Fix remaining _1 files using cmd.exe for deletion
$Path = "D:\Obsidian\Main\20 - Permanent Notes"

# Get all _1 files
$files = Get-ChildItem -Path $Path -Filter "*_1.md" -ErrorAction SilentlyContinue

foreach ($file in $files) {
    $baseName = $file.BaseName -replace '_1$', ''
    $newName = "$baseName.md"
    $newPath = Join-Path $file.DirectoryName $newName

    Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan

    if (Test-Path -LiteralPath $newPath) {
        # Use cmd.exe to force delete
        Write-Host "  Force deleting: $newName" -ForegroundColor Yellow
        $null = cmd /c "del /f /q `"$newPath`"" 2>&1
        Start-Sleep -Milliseconds 300
    }

    # Use cmd.exe to rename
    Write-Host "  Renaming to: $newName" -ForegroundColor Green
    $null = cmd /c "ren `"$($file.FullName)`" `"$newName`"" 2>&1
}

Write-Host "`nDone!" -ForegroundColor Green

# Check remaining
$remaining = Get-ChildItem -Path $Path -Filter "*_1.md" -ErrorAction SilentlyContinue
Write-Host "Remaining _1 files in 20 - Permanent Notes: $($remaining.Count)"
if ($remaining) {
    $remaining | ForEach-Object { Write-Host "  - $($_.Name)" }
}
