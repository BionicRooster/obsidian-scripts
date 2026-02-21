# Remove [New post] prefix from recipe filenames in 01/Recipes
$folder = "D:\Obsidian\Main\01\Recipes"

$files = Get-ChildItem -Path $folder -Filter "*.md" | Where-Object {
    $_.Name -match "^\[New post\]"
}

Write-Host "Found $($files.Count) files with [New post] prefix"

$count = 0
foreach ($file in $files) {
    $newName = $file.Name -replace "^\[New post\]\s*", ""

    if ($newName -eq $file.Name) {
        continue
    }

    $newPath = Join-Path $folder $newName
    if (Test-Path -LiteralPath $newPath) {
        Write-Host "SKIP (exists): $($file.Name)"
        continue
    }

    Rename-Item -LiteralPath $file.FullName -NewName $newName
    Write-Host "Renamed: $($file.Name) -> $newName"
    $count++
}

Write-Host "`nTotal renamed: $count"
