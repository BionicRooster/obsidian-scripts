$vault = 'D:\Obsidian\Main'
$mocDir = Join-Path $vault '00 - Home Dashboard'

# Get all wikilinks from MOC files
$mocLinks = @{}
Get-ChildItem $mocDir -Filter 'MOC*.md' | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -Encoding UTF8
    $matches = [regex]::Matches($content, '\[\[([^\]|]+?)(?:\|[^\]]+?)?\]\]')
    foreach ($m in $matches) {
        $linkName = $m.Groups[1].Value
        $mocLinks[$linkName] = $true
    }
}

# Also check for nav properties in files pointing to MOCs (these are already classified)
# Get all markdown files excluding skip directories
$skipPatterns = @('\People\', '\Journals\', '\00 - Journal\', '\Templates\', '\.resources', '\images\', '\Attachments\', '\00 - Images\', '\00 - Home Dashboard\', '\09 - Kindle Clippings\')

$allFiles = Get-ChildItem $vault -Filter '*.md' -Recurse | Where-Object {
    $path = $_.FullName
    $skip = $false
    foreach ($p in $skipPatterns) {
        if ($path -like ('*' + $p + '*')) { $skip = $true; break }
    }
    -not $skip
}

# Find orphans: files whose basename is not in any MOC link
$orphans = @()
foreach ($f in $allFiles) {
    $baseName = $f.BaseName
    if (-not $mocLinks.ContainsKey($baseName)) {
        # Also check if the file has a nav property pointing to a MOC
        $firstLines = Get-Content $f.FullName -TotalCount 20 -Encoding UTF8 -ErrorAction SilentlyContinue
        $hasNav = $false
        if ($firstLines) {
            foreach ($line in $firstLines) {
                if ($line -match '^nav:') { $hasNav = $true; break }
                if ($line -match '^---' -and $firstLines.IndexOf($line) -gt 0) { break }
            }
        }
        if (-not $hasNav) {
            $orphans += [PSCustomObject]@{
                Name = $f.Name
                BaseName = $f.BaseName
                FullName = $f.FullName
                Directory = $f.DirectoryName.Replace($vault + '\', '')
                Size = $f.Length
            }
        }
    }
}

Write-Host 'Total orphan count:' $orphans.Count
Write-Host ''
# Group by directory
$grouped = $orphans | Group-Object Directory | Sort-Object Count -Descending
foreach ($g in $grouped) {
    Write-Host ('  ' + $g.Name + ': ' + $g.Count + ' files')
}
Write-Host ''
# Output all orphan file paths
foreach ($o in $orphans) {
    Write-Host $o.FullName
}
