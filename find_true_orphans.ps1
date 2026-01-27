$vaultPath = "D:\Obsidian\Main"

# Get all markdown files excluding certain directories
$allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse | Where-Object {
    $_.FullName -notmatch "05 - Templates" -and
    $_.FullName -notmatch "attachments" -and
    $_.FullName -notmatch "00 - Journal" -and
    $_.FullName -notmatch "11 - Evernote" -and
    $_.FullName -notmatch "12 - OneNote" -and
    $_.FullName -notmatch "_resources" -and
    $_.BaseName -notmatch "^\d{4}-\d{2}-\d{2}$" -and
    $_.BaseName -ne "Untitled" -and
    $_.BaseName -notmatch "\.resources$"
}

# Find all wiki links in ALL files (including excluded dirs for link counting)
$allFilesForLinks = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse
$linkedFiles = @{}
foreach ($file in $allFilesForLinks) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $matches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
        foreach ($match in $matches) {
            $linkTarget = $match.Groups[1].Value
            if ($linkTarget -match '/') { $linkTarget = $linkTarget.Split('/')[-1] }
            if ($linkTarget -match '\') { $linkTarget = $linkTarget.Split('\')[-1] }
            if ($linkTarget -match '#') { $linkTarget = $linkTarget.Split('#')[0] }
            $linkTarget = $linkTarget.Trim()
            if ($linkTarget) { $linkedFiles[$linkTarget] = $true }
        }
    }
}

# Find orphan files
$orphans = @()
foreach ($file in $allFiles) {
    if (-not $linkedFiles.ContainsKey($file.BaseName)) {
        $orphans += $file
    }
}

# Group by directory for analysis
$grouped = $orphans | Group-Object { Split-Path $_.DirectoryName -Leaf } | Sort-Object Count -Descending

Write-Host "=== ORPHAN FILES BY DIRECTORY ===" -ForegroundColor Cyan
Write-Host "Total: $($orphans.Count) orphan files"
Write-Host ""

foreach ($group in $grouped) {
    Write-Host "$($group.Name): $($group.Count) files" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== PRIORITY ORPHANS (Permanent Notes, Indexes, People, Organizations) ===" -ForegroundColor Green
$priorityOrphans = $orphans | Where-Object {
    $_.FullName -match "Permanent Notes" -or
    $_.FullName -match "04 - Indexes" -or
    $_.FullName -match "15 - People" -or
    $_.FullName -match "16 - Organizations" -or
    $_.FullName -match "00 - Home Dashboard"
}

foreach ($orphan in $priorityOrphans | Sort-Object { $_.FullName }) {
    $relativePath = $orphan.FullName.Replace($vaultPath + "\", "")
    Write-Host $relativePath
}
