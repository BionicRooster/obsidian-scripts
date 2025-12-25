$vaultPath = "D:\Obsidian\Main"

# Get all markdown files
$allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse | Where-Object {
    $_.FullName -notmatch "05 - Templates" -and
    $_.FullName -notmatch "attachments"
}

# Create a set of all file basenames (without extension)
$allFileNames = @{}
foreach ($file in $allFiles) {
    $baseName = $file.BaseName
    if (-not $allFileNames.ContainsKey($baseName)) {
        $allFileNames[$baseName] = $file.FullName
    }
}

# Find all wiki links in all files
$linkedFiles = @{}
foreach ($file in $allFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        # Match [[link]] or [[link|alias]] patterns
        $matches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
        foreach ($match in $matches) {
            $linkTarget = $match.Groups[1].Value
            # Handle paths - just get the filename part
            if ($linkTarget -match '/') {
                $linkTarget = $linkTarget.Split('/')[-1]
            }
            if ($linkTarget -match '\') {
                $linkTarget = $linkTarget.Split('\')[-1]
            }
            # Remove any heading references
            if ($linkTarget -match '#') {
                $linkTarget = $linkTarget.Split('#')[0]
            }
            $linkTarget = $linkTarget.Trim()
            if ($linkTarget) {
                $linkedFiles[$linkTarget] = $true
            }
        }
    }
}

# Find orphan files (files that are never linked to)
$orphans = @()
foreach ($file in $allFiles) {
    $baseName = $file.BaseName
    if (-not $linkedFiles.ContainsKey($baseName)) {
        $orphans += $file
    }
}

# Output orphans with their paths
Write-Host "Found $($orphans.Count) orphan files:"
Write-Host ""
foreach ($orphan in $orphans | Sort-Object { $_.FullName }) {
    $relativePath = $orphan.FullName.Replace($vaultPath + "\", "")
    Write-Host $relativePath
}
