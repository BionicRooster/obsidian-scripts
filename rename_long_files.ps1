# Script to find and rename files with names longer than 40 characters
# Uses robocopy to list files (handles long paths better)
$vaultPath = "D:\Obsidian\Main"
$maxLength = 40
$reportPath = "D:\Obsidian\Main\TooLongFilenames.md"

# Initialize arrays for tracking
$renamed = @()
$errors = @()

# Get all .md files using dir command which handles some long paths better
$tempFile = "$env:TEMP\mdfiles.txt"
cmd /c "dir /s /b `"$vaultPath\*.md`" 2>nul" | Out-File $tempFile -Encoding UTF8

$allFiles = Get-Content $tempFile -ErrorAction SilentlyContinue

foreach ($filePath in $allFiles) {
    if ([string]::IsNullOrWhiteSpace($filePath)) { continue }

    # Extract filename without extension
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    $directory = [System.IO.Path]::GetDirectoryName($filePath)

    if ($fileName.Length -gt $maxLength) {
        $originalName = [System.IO.Path]::GetFileName($filePath)

        # Truncate to maxLength characters
        $newBaseName = $fileName.Substring(0, $maxLength)
        $newName = "$newBaseName.md"
        $newPath = Join-Path $directory $newName

        # Handle conflicts by adding a number
        $counter = 1
        while (Test-Path -LiteralPath $newPath -ErrorAction SilentlyContinue) {
            $suffix = "_$counter"
            $truncLen = $maxLength - $suffix.Length
            if ($truncLen -lt 1) { $truncLen = 1 }
            $newBaseName = $fileName.Substring(0, $truncLen) + $suffix
            $newName = "$newBaseName.md"
            $newPath = Join-Path $directory $newName
            $counter++
        }

        # Try to rename the file
        try {
            # Use cmd to rename (handles long paths better)
            $renameResult = cmd /c "ren `"$filePath`" `"$newName`" 2>&1"
            if ($LASTEXITCODE -eq 0) {
                $relDir = $directory.Replace($vaultPath, "").TrimStart("\")
                if ($relDir -eq "") { $relDir = "(root)" }
                $renamed += [PSCustomObject]@{
                    Original = $originalName
                    New = $newName
                    Directory = $relDir
                }
                Write-Host "Renamed: $originalName -> $newName"
            } else {
                $errors += "Failed: $originalName - $renameResult"
                Write-Host "FAILED: $originalName"
            }
        } catch {
            $errors += "Error: $originalName - $_"
            Write-Host "ERROR: $originalName - $_"
        }
    }
}

# Build report
$reportContent = @"
# Too Long Filenames Report

> Files renamed because their names exceeded $maxLength characters

**Date processed:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

---

## Renamed Files ($($renamed.Count) total)

| Original Filename | New Filename | Directory |
|------------------|--------------|-----------|
"@

foreach ($item in $renamed) {
    $reportContent += "`n| $($item.Original) | $($item.New) | $($item.Directory) |"
}

if ($errors.Count -gt 0) {
    $reportContent += @"

---

## Errors ($($errors.Count) total)

"@
    foreach ($err in $errors) {
        $reportContent += "`n- $err"
    }
}

$reportContent += @"

---

## Summary
- **Total files renamed:** $($renamed.Count)
- **Errors encountered:** $($errors.Count)
- **Maximum filename length:** $maxLength characters (plus .md extension)
"@

# Write report
$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`nReport saved to: $reportPath"
Write-Host "Total files renamed: $($renamed.Count)"
Write-Host "Errors: $($errors.Count)"

# Cleanup
Remove-Item $tempFile -ErrorAction SilentlyContinue
