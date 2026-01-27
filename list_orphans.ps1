# List orphans using same logic as link_largest_orphan.ps1
$vaultPath = 'D:\Obsidian\Main'
$skipFolders = @('00 - Journal', '05 - Templates', '00 - Images', 'attachments', '.trash', '.obsidian', '.smart-env')

# Get all .md files
$mdFiles = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse -ErrorAction SilentlyContinue

# Build file map (lowercase keys)
$fileMap = @{}
foreach ($file in $mdFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $fileMap[$baseName.ToLower()] = $file.FullName
}

# Find linked files by scanning all content for wiki links
$linkedFiles = @{}
foreach ($file in $mdFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $linkMatches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
    foreach ($match in $linkMatches) {
        $linkTarget = $match.Groups[1].Value

        # Remove heading anchors
        if ($linkTarget -match '^([^#]+)#') {
            $linkTarget = $matches[1]
        }

        # Extract filename from paths
        if ($linkTarget -match '[/\\]') {
            $linkTarget = Split-Path $linkTarget -Leaf
        }

        $linkTargetLower = $linkTarget.TrimStart().ToLower()
        if ($fileMap.ContainsKey($linkTargetLower)) {
            $linkedFiles[$linkTargetLower] = $true
        }
    }
}

# Find orphans (files with no incoming links)
$orphans = @()
foreach ($file in $mdFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $relativePath = $file.FullName.Replace($vaultPath + '\', '')

    # Check skip folders
    $skip = $false
    foreach ($folder in $skipFolders) {
        if ($relativePath -match ("^" + [regex]::Escape($folder))) {
            $skip = $true
            break
        }
    }
    if ($skip) { continue }

    # Check if orphan (no incoming links)
    if (-not $linkedFiles.ContainsKey($baseName.ToLower())) {
        $orphans += [PSCustomObject]@{
            Name = $baseName
            Path = $relativePath
            SizeKB = [math]::Round($file.Length / 1024, 2)
        }
    }
}

# Sort by size descending and output
Write-Host "=== ORPHANS DETECTED BY link_largest_orphan.ps1 LOGIC ===" -ForegroundColor Cyan
Write-Host ""
$orphans | Sort-Object SizeKB -Descending | Format-Table -AutoSize @{L='#';E={$script:i++;$script:i}}, Name, SizeKB, Path
Write-Host ""
Write-Host "Total orphans: $($orphans.Count)" -ForegroundColor Green
