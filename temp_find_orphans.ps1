$vault = 'D:\Obsidian\Main'
$mocDir = Join-Path $vault '00 - Home Dashboard'

# Get all wikilinks from MOC files
$mocLinks = @{}
Get-ChildItem $mocDir -Filter 'MOC*.md' | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -Encoding UTF8
    $linkMatches = [regex]::Matches($content, '\[\[([^\]|]+?)(?:\|[^\]]+?)?\]\]')
    foreach ($m in $linkMatches) {
        $linkName = $m.Groups[1].Value
        $mocLinks[$linkName] = $true
    }
}

Write-Host "Total links found in MOCs: $($mocLinks.Count)"

# Skip patterns
$skipPatterns = @('\\People\\', '\\Journals\\', '\\00 - Journal\\', '\\Templates\\', '\\.resources', '\\images\\', '\\Attachments\\', '\\00 - Images\\', '\\00 - Home Dashboard\\', '\\09 - Kindle Clippings\\')

# Get all markdown files excluding skip directories
$allFiles = Get-ChildItem $vault -Filter '*.md' -Recurse | Where-Object {
    $path = $_.FullName
    $skip = $false
    foreach ($p in $skipPatterns) {
        if ($path -like "*$p*") { $skip = $true; break }
    }
    -not $skip
}

Write-Host "Total files after exclusions: $($allFiles.Count)"

# Find orphans
$orphans = @()
foreach ($f in $allFiles) {
    $baseName = $f.BaseName
    if (-not $mocLinks.ContainsKey($baseName)) {
        # Check nav property
        $firstLines = Get-Content $f.FullName -TotalCount 20 -Encoding UTF8 -ErrorAction SilentlyContinue
        $hasNav = $false
        $inFrontmatter = $false
        if ($firstLines) {
            foreach ($line in $firstLines) {
                if ($line -match '^---' -and -not $inFrontmatter) { $inFrontmatter = $true; continue }
                if ($line -match '^---' -and $inFrontmatter) { break }
                if ($inFrontmatter -and $line -match '^nav:') { $hasNav = $true; break }
            }
        }
        if (-not $hasNav) {
            $orphans += [PSCustomObject]@{
                Name = $f.Name
                BaseName = $f.BaseName
                FullName = $f.FullName
                Directory = $f.DirectoryName.Replace("$vault\", '')
                Size = $f.Length
            }
        }
    }
}

Write-Host "Total orphans found: $($orphans.Count)"
Write-Host ""

# Group by directory
$grouped = $orphans | Group-Object Directory | Sort-Object Count -Descending
foreach ($g in $grouped) {
    Write-Host "  $($g.Name): $($g.Count) files"
}

Write-Host ""
Write-Host "=== ORPHAN LIST ==="
foreach ($o in $orphans) {
    Write-Host "$($o.Directory)|$($o.BaseName)|$($o.FullName)"
}
