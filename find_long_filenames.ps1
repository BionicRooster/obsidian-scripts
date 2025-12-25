# Script to find and rename .md files with names longer than 20 characters
# Target directory: D:\Obsidian\Main

$vaultPath = "D:\Obsidian\Main"
$maxLength = 20
$results = @()

# Find all .md files with basenames longer than 20 characters
$longFiles = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | Where-Object { $_.BaseName.Length -gt $maxLength }

Write-Host "Found $($longFiles.Count) files with names longer than $maxLength characters"
Write-Host ""
Write-Host "Files to be renamed:"
Write-Host "===================="

foreach ($file in $longFiles) {
    $originalName = $file.Name
    $originalBaseName = $file.BaseName
    $directory = $file.Directory.FullName

    # Truncate to 20 characters
    $newBaseName = $originalBaseName.Substring(0, $maxLength)
    $newName = "$newBaseName.md"
    $newPath = Join-Path $directory $newName

    # Check for naming conflicts and add suffix if needed
    $counter = 1
    while (Test-Path $newPath) {
        $newBaseName = $originalBaseName.Substring(0, [Math]::Min($maxLength - ($counter.ToString().Length + 1), $originalBaseName.Length))
        $newName = "$newBaseName-$counter.md"
        $newPath = Join-Path $directory $newName
        $counter++
    }

    # Store result for logging
    $result = [PSCustomObject]@{
        OriginalFilename = $originalName
        NewFilename = $newName
        FullPath = $directory
        OriginalFullPath = $file.FullName
        NewFullPath = $newPath
    }
    $results += $result

    Write-Host "Original: $originalName (Length: $($originalBaseName.Length))"
    Write-Host "New:      $newName"
    Write-Host "Path:     $directory"
    Write-Host ""
}

# Export results to JSON for processing
$results | ConvertTo-Json -Depth 10 | Out-File -FilePath "C:\Users\awt\rename_results.json" -Encoding UTF8

Write-Host "Total files to rename: $($results.Count)"
