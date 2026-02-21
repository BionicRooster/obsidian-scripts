# Script to move date prefix from filename to YAML and rename files
# For notes in 04 - GMail folder

$folder = "D:\Obsidian\Main\04 - GMail"

# Get all files with date prefix pattern (YYYY-MM-DD - )
$files = Get-ChildItem -Path $folder -Filter "*.md" | Where-Object { $_.Name -match "^\d{4}-\d{2}-\d{2} - " }

$processed = 0
$skipped = 0
$errors = @()

foreach ($file in $files) {
    try {
        # Extract date and new name from filename
        if ($file.Name -match "^(\d{4}-\d{2}-\d{2}) - (.+)$") {
            $datePrefix = $matches[1]
            $newName = $matches[2]

            # Read file content with UTF-8 encoding
            $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

            # Check if file has YAML frontmatter
            if ($content -match "^---\r?\n([\s\S]*?)\r?\n---") {
                $yamlContent = $matches[1]

                # Check if email_date or original_email_date already exists
                if ($yamlContent -notmatch "email_date:" -and $yamlContent -notmatch "original_email_date:") {
                    # Add email_date to YAML (after first ---)
                    $newYaml = $yamlContent + "`nemail_date: $datePrefix"
                    $content = $content -replace "^---\r?\n([\s\S]*?)\r?\n---", "---`n$newYaml`n---"
                }

                # Also update the markdown title if it has the date prefix
                $content = $content -replace "# \d{4}-\d{2}-\d{2} - ", "# "
            }
            else {
                # No YAML frontmatter - add one
                $newFrontmatter = "---`nemail_date: $datePrefix`n---`n`n"
                $content = $newFrontmatter + $content
            }

            # Write updated content back
            Set-Content -LiteralPath $file.FullName -Value $content -Encoding UTF8 -NoNewline

            # Calculate new file path
            $newPath = Join-Path $folder $newName

            # Check if target file already exists
            if (Test-Path -LiteralPath $newPath) {
                # Add a number suffix to avoid collision
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($newName)
                $extension = [System.IO.Path]::GetExtension($newName)
                $counter = 1
                do {
                    $newName = "$baseName ($counter)$extension"
                    $newPath = Join-Path $folder $newName
                    $counter++
                } while (Test-Path -LiteralPath $newPath)
            }

            # Rename file
            Rename-Item -LiteralPath $file.FullName -NewName $newName

            $processed++
            Write-Host "Processed: $($file.Name) -> $newName"
        }
    }
    catch {
        $errors += "Error processing $($file.Name): $_"
        $skipped++
    }
}

Write-Host "`n=== Summary ==="
Write-Host "Processed: $processed files"
Write-Host "Skipped: $skipped files"

if ($errors.Count -gt 0) {
    Write-Host "`nErrors:"
    $errors | ForEach-Object { Write-Host $_ }
}
