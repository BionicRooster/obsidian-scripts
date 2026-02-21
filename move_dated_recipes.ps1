# Move date prefix from filename to YAML and relocate files from 03 - Recipes to 01/Recipes
$vault = "D:\Obsidian\Main"
$source = "$vault\03 - Recipes"
$dest = "$vault\01\Recipes"

$processed = 0
$skipped = 0

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

        # Clean up the new name (remove leading " - " if present)
        $newName = $newName -replace "^-\s*", ""

        Write-Host "`nProcessing: $($file.Name)"
        Write-Host "  Date: $datePrefix"
        Write-Host "  New name: $newName"

        # Read content
        $content = Get-Content -Path $file.FullName -Raw

        # Check if file has YAML frontmatter
        if ($content -match "^---\r?\n") {
            # Check if already has recipe_date or email_date
            if ($content -match "(recipe_date|email_date):") {
                Write-Host "  SKIP: Already has date in YAML"
                $skipped++
                continue
            }

            # Add recipe_date to YAML before the closing ---
            # Find the closing --- and insert before it
            $content = $content -replace "(^---\r?\n[\s\S]*?)(---)(\r?\n)", "`$1recipe_date: $datePrefix`r`n`$2`$3"
        } else {
            # No YAML frontmatter - add one
            $content = "---`r`nrecipe_date: $datePrefix`r`n---`r`n`r`n$content"
        }

        # Write updated content back to file
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($false))

        # Check if target exists
        $targetPath = Join-Path $dest $newName
        if (Test-Path -LiteralPath $targetPath) {
            Write-Host "  WARNING: Target exists, adding suffix" -ForegroundColor Yellow
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($newName)
            $ext = [System.IO.Path]::GetExtension($newName)
            $counter = 1
            while (Test-Path -LiteralPath $targetPath) {
                $newName = "$baseName ($counter)$ext"
                $targetPath = Join-Path $dest $newName
                $counter++
            }
        }

        # Move and rename file
        Move-Item -LiteralPath $file.FullName -Destination $targetPath
        Write-Host "  MOVED: -> 01/Recipes/$newName" -ForegroundColor Green
        $processed++
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Files processed: $processed"
Write-Host "Files skipped: $skipped"
