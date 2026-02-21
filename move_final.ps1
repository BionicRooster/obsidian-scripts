# Move final remaining files
$src = "D:\Obsidian\Main\20 - Permanent Notes"

# Move each specific file
$files = Get-ChildItem -Path $src -Filter "*.md" | Where-Object { $_.Name -ne "20 - Permanent Notes.md" }

foreach ($file in $files) {
    $dest = switch -regex ($file.Name) {
        "Judaism" { "D:\Obsidian\Main\01\Religion" }
        "Coronavirus" { "D:\Obsidian\Main\01\Health" }
        default { "D:\Obsidian\Main\01\Home" }
    }

    $destPath = Join-Path $dest $file.Name
    if (-not (Test-Path $destPath)) {
        Move-Item -Path $file.FullName -Destination $dest -Force
        Write-Host "Moved: $($file.Name) -> $dest"
    } else {
        Write-Host "Duplicate: $($file.Name)"
        # Delete the duplicate source file
        Remove-Item -Path $file.FullName -Force
        Write-Host "Deleted duplicate: $($file.Name)"
    }
}

Write-Host "`nRemaining:"
Get-ChildItem -Path $src -Filter "*.md" | ForEach-Object { Write-Host "  $($_.Name)" }
