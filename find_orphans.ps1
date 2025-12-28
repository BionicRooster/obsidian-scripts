# Find orphan files in Obsidian vault
# Orphans = files with no incoming links from other files

$vaultPath = "D:\Obsidian\Main"

Write-Host "=== Finding Orphan Files ===" -ForegroundColor Cyan
Write-Host "Scanning vault: $vaultPath" -ForegroundColor Gray

# Get all markdown files
$mdFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
Write-Host "Found $($mdFiles.Count) markdown files" -ForegroundColor Gray

# Build a map of all file names (without extension) for link resolution
$fileMap = @{}
foreach ($file in $mdFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $fileMap[$baseName.ToLower()] = $file.FullName
}

# Track which files are linked to (have incoming links)
$linkedFiles = @{}

# Scan all files for outgoing links
Write-Host "Scanning for links..." -ForegroundColor Gray
foreach ($file in $mdFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Find all wiki-style links [[link]] or [[link|alias]]
    $linkMatches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

    foreach ($match in $linkMatches) {
        $linkTarget = $match.Groups[1].Value.Trim()
        # Remove any heading anchors
        if ($linkTarget -match '^([^#]+)#') {
            $linkTarget = $matches[1]
        }
        $linkTargetLower = $linkTarget.ToLower()

        # Mark this file as linked
        if ($fileMap.ContainsKey($linkTargetLower)) {
            $linkedFiles[$linkTargetLower] = $true
        }
    }
}

# Find orphans (files not linked by any other file)
$orphans = @()
foreach ($file in $mdFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    if (-not $linkedFiles.ContainsKey($baseName.ToLower())) {
        $orphans += $file
    }
}

Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "Total files: $($mdFiles.Count)" -ForegroundColor White
Write-Host "Linked files: $($linkedFiles.Count)" -ForegroundColor Green
Write-Host "Orphan files: $($orphans.Count)" -ForegroundColor Yellow

# Output orphans grouped by folder
Write-Host "`n=== Orphan Files by Folder ===" -ForegroundColor Cyan

$orphansByFolder = $orphans | Group-Object { Split-Path $_.DirectoryName -Leaf } | Sort-Object Count -Descending

foreach ($group in $orphansByFolder) {
    Write-Host "`n[$($group.Name)] - $($group.Count) orphans" -ForegroundColor Yellow
    foreach ($file in ($group.Group | Select-Object -First 10)) {
        $relativePath = $file.FullName.Replace($vaultPath + "\", "")
        Write-Host "  $relativePath" -ForegroundColor Gray
    }
    if ($group.Count -gt 10) {
        Write-Host "  ... and $($group.Count - 10) more" -ForegroundColor DarkGray
    }
}

# Save full list to file
$outputPath = "C:\Users\awt\orphan_files.txt"
$orphans | ForEach-Object { $_.FullName.Replace($vaultPath + "\", "") } | Set-Content -Path $outputPath
Write-Host "`nFull list saved to: $outputPath" -ForegroundColor Cyan
