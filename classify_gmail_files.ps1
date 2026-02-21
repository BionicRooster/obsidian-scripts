# Classify and move Gmail files to appropriate 01 subdirectories
$vault = "D:\Obsidian\Main"
$gmail = "$vault\04 - GMail"

# Define classification rules (filename patterns -> destination folder)
$classifications = @{
    # Science topics
    "Woolly Mammoth" = "01\Science"
    "Reviving Extinct Species" = "01\Science"
    "Woolly Mamoth" = "01\Science"  # typo in filename

    # Technology/vintage computing
    "\[pidp8\]" = "01\Technology"
    "\[M100\]" = "01\Technology"

    # Health (only very specific health files, not recipe-related)
    "Diabetes 101" = "01\Health"
    "End-Stage Renal Disease" = "01\Health"
}

$moved = @()

foreach ($pattern in $classifications.Keys) {
    $dest = $classifications[$pattern]
    $destPath = Join-Path $vault $dest

    # Find matching files
    $files = Get-ChildItem -Path $gmail -Filter "*.md" | Where-Object {
        $_.Name -match $pattern
    }

    foreach ($file in $files) {
        $targetPath = Join-Path $destPath $file.Name

        # Check if target exists
        if (Test-Path -LiteralPath $targetPath) {
            Write-Host "SKIP (exists): $($file.Name)"
            continue
        }

        # Move file
        Move-Item -LiteralPath $file.FullName -Destination $destPath
        $moved += [PSCustomObject]@{
            File = $file.Name
            Destination = $dest
        }
        Write-Host "MOVED: $($file.Name) -> $dest"
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Total files moved: $($moved.Count)"
$moved | Format-Table -AutoSize
