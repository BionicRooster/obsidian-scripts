# Move date prefix from filename to YAML - Fixed version without -Raw
$vault = "D:\Obsidian\Main"
$source = "$vault\03 - Recipes"
$dest = "$vault\01\Recipes"

$processed = 0

# Find files with date prefix (YYYY-MM-DD)
$files = Get-ChildItem -Path $source -Filter "*.md" | Where-Object {
    $_.Name -match "^\d{4}-\d{2}-\d{2}"
}

Write-Host "Found $($files.Count) files with date prefix"

foreach ($file in $files) {
    # Extract date from filename
    if ($file.Name -match "^(\d{4}-\d{2}-\d{2})\s*-?\s*(.+)$") {
        $datePrefix = $matches[1]
        $newName = $matches[2].Trim()
        $newName = $newName -replace "^-\s*", ""

        Write-Host "Processing: $($file.Name)"

        # Read content as array and join
        $contentLines = Get-Content -Path $file.FullName
        $content = $contentLines -join "`r`n"

        # Check if file has YAML frontmatter
        if ($content -match "^---") {
            # Check if already has recipe_date or email_date
            if ($content -match "(recipe_date|email_date):") {
                Write-Host "  SKIP: Already has date"
                continue
            }

            # Add recipe_date after first ---
            $content = $content -replace "^(---\r?\n)", "`$1recipe_date: $datePrefix`r`n"
        } else {
            # No YAML - add one
            $content = "---`r`nrecipe_date: $datePrefix`r`n---`r`n`r`n$content"
        }

        # Write updated content
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($false))

        # Check if target exists
        $targetPath = Join-Path $dest $newName
        if (Test-Path -LiteralPath $targetPath) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($newName)
            $ext = [System.IO.Path]::GetExtension($newName)
            $counter = 1
            while (Test-Path -LiteralPath $targetPath) {
                $newName = "$baseName ($counter)$ext"
                $targetPath = Join-Path $dest $newName
                $counter++
            }
        }

        # Move file
        Move-Item -LiteralPath $file.FullName -Destination $targetPath
        Write-Host "  MOVED: -> $newName" -ForegroundColor Green
        $processed++
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Files processed: $processed"
