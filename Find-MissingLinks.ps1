# Find-MissingLinks.ps1
# Finds all markdown files in Obsidian vault without wikilinks [[]]

$vaultPath = "D:\Obsidian\Main"
$outputFile = Join-Path $vaultPath "Missing Links.md"

# Get all markdown files
$mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse

# Find files without wikilinks
$filesWithoutLinks = @()

foreach ($file in $mdFiles) {
    # Skip the output file itself
    if ($file.FullName -eq $outputFile) {
        continue
    }

    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue

    # Check if file contains wikilinks [[...]]
    if ($content -notmatch '\[\[.+?\]\]') {
        $filesWithoutLinks += $file
    }
}

# Build the output
$runDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$separator = "`n" + ("=" * 60) + "`n"

$output = @()
$output += $separator
$output += "## Scan: $runDateTime"
$output += ""
$output += "**Total files without wikilinks:** $($filesWithoutLinks.Count)"
$output += ""

if ($filesWithoutLinks.Count -gt 0) {
    $output += "| File | Location | Size | Modified |"
    $output += "|------|----------|------|----------|"

    foreach ($file in $filesWithoutLinks | Sort-Object FullName) {
        $relativePath = $file.DirectoryName.Replace($vaultPath, "").TrimStart("\")
        if ([string]::IsNullOrEmpty($relativePath)) {
            $relativePath = "(root)"
        }
        $sizeKB = [math]::Round($file.Length / 1KB, 2)
        $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")

        $output += "| $($file.Name) | $relativePath | $sizeKB KB | $modified |"
    }
}

$output += ""

# Append to file (create if doesn't exist)
if (-not (Test-Path $outputFile)) {
    "# Missing Links Report`n`nFiles in this vault that contain no wikilinks.`n" | Out-File -FilePath $outputFile -Encoding UTF8
}

$output -join "`n" | Out-File -FilePath $outputFile -Append -Encoding UTF8

Write-Host "Scan complete!" -ForegroundColor Green
Write-Host "Found $($filesWithoutLinks.Count) files without wikilinks"
Write-Host "Results appended to: $outputFile"
