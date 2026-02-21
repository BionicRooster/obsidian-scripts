# Remove [New post] prefix from filenames in 04 - GMail folder

$folder = "D:\Obsidian\Main\04 - GMail"

# Get files matching pattern
$files = Get-ChildItem -LiteralPath $folder -Filter "*.md" | Where-Object { $_.Name -match '^\[New post\]' }

Write-Host "Found $($files.Count) files with [New post] prefix"

$count = 0
foreach ($file in $files) {
    $newName = $file.Name -replace '^\[New post\] ', ''

    if ($newName -eq $file.Name) {
        Write-Host "No change needed: $($file.Name)"
        continue
    }

    # Check if target exists
    $newPath = Join-Path $folder $newName
    if (Test-Path -LiteralPath $newPath) {
        Write-Host "Skipping (target exists): $($file.Name)"
        continue
    }

    Rename-Item -LiteralPath $file.FullName -NewName $newName
    Write-Host "Renamed: $($file.Name) -> $newName"
    $count++
}

Write-Host "`nTotal renamed: $count files"
