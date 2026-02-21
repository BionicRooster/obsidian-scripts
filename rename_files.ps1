# Script to rename .md files with names longer than 20 characters
# and create a summary report

$vaultPath = "D:\Obsidian\Main"
$maxLength = 20
$reportPath = "D:\Obsidian\Main\TooLongFilenames.md"
$results = @()

# Find all .md files with basenames longer than 20 characters
$longFiles = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | Where-Object { $_.BaseName.Length -gt $maxLength }

Write-Host "Found $($longFiles.Count) files with names longer than $maxLength characters"
Write-Host "Starting rename process..."
Write-Host ""

$processedCount = 0
$errorCount = 0

foreach ($file in $longFiles) {
    try {
        $originalName = $file.Name
        $originalBaseName = $file.BaseName
        $directory = $file.Directory.FullName
        $originalFullPath = $file.FullName

        # Truncate to 20 characters
        $newBaseName = $originalBaseName.Substring(0, $maxLength)
        $newName = "$newBaseName.md"
        $newPath = Join-Path $directory $newName

        # Check for naming conflicts and add suffix if needed
        $counter = 1
        while (Test-Path $newPath) {
            # Calculate how much space we need for the counter suffix
            $suffixLength = $counter.ToString().Length + 1  # +1 for the dash
            $availableLength = $maxLength - $suffixLength

            # Make sure we don't try to substring beyond the original length
            if ($availableLength -gt $originalBaseName.Length) {
                $availableLength = $originalBaseName.Length
            }

            $newBaseName = $originalBaseName.Substring(0, $availableLength) + "-$counter"
            $newName = "$newBaseName.md"
            $newPath = Join-Path $directory $newName
            $counter++
        }

        # Perform the rename
        Rename-Item -Path $originalFullPath -NewName $newName -ErrorAction Stop

        # Store result for reporting
        $result = [PSCustomObject]@{
            OriginalFilename = $originalName
            NewFilename = $newName
            FullPath = $directory
        }
        $results += $result

        $processedCount++

        if ($processedCount % 100 -eq 0) {
            Write-Host "Processed $processedCount files..."
        }

    } catch {
        Write-Host "ERROR renaming file: $($file.FullName)"
        Write-Host "Error message: $($_.Exception.Message)"
        $errorCount++
    }
}

Write-Host ""
Write-Host "Rename process complete!"
Write-Host "Successfully renamed: $processedCount files"
Write-Host "Errors encountered: $errorCount"
Write-Host ""
Write-Host "Creating report at: $reportPath"

# Create the markdown report
$reportContent = @"
# Files with Long Filenames - Rename Report

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Total Files Renamed:** $processedCount
**Errors:** $errorCount

## Summary Table

| Original Filename | New Filename | Full Path |
|-------------------|--------------|-----------|
"@

foreach ($result in $results) {
    # Escape pipe characters in filenames for markdown table
    $origName = $result.OriginalFilename -replace '\|', '\|'
    $newName = $result.NewFilename -replace '\|', '\|'
    $path = $result.FullPath -replace '\|', '\|'

    $reportContent += "`n| $origName | $newName | $path |"
}

# Add footer
$reportContent += @"


---

## Notes

- All filenames were truncated to maximum 20 characters (not including .md extension)
- If a conflict occurred, a number suffix was added (e.g., -1, -2, etc.)
- Total files processed: $processedCount
- This report was generated automatically by PowerShell script
"@

# Write the report
$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Report created successfully!"
Write-Host ""
