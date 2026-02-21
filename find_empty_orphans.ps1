# Script to find orphan files with no content beyond their title
# These are candidates for deletion

$vaultPath = "D:\Obsidian\Main"
$outputFile = "C:\Users\awt\PowerShell\empty_orphans.json"

Write-Host "Scanning vault..."
$allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse

# Build incoming links map
$incomingLinks = @{}
foreach ($file in $allFiles) {
    $incomingLinks[$file.BaseName] = 0
}

Write-Host "Analyzing link structure..."
foreach ($file in $allFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Find all wikilinks
    $matches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
    foreach ($match in $matches) {
        $linked = $match.Groups[1].Value
        if ($linked -match '/') { $linked = $linked.Split('/')[-1] }
        if ($incomingLinks.ContainsKey($linked)) {
            $incomingLinks[$linked]++
        }
    }
}

# Find orphans (no incoming links)
Write-Host "Finding orphans with no content..."
$emptyOrphans = @()

foreach ($file in $allFiles) {
    $title = $file.BaseName

    # Skip if has incoming links
    if ($incomingLinks[$title] -gt 0) { continue }

    # Skip system files
    if ($title -match '^\d+\s*-\s*') { continue }
    if ($file.FullName -match '\\05 - Templates\\') { continue }

    # Read content
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue

    # Check if file is empty or has only minimal content
    $isEmpty = $false

    if (-not $content -or $content.Trim().Length -eq 0) {
        # Completely empty
        $isEmpty = $true
    } else {
        # Remove YAML frontmatter
        $cleanContent = $content -replace '(?s)^---.*?---\s*', ''

        # Remove the title (# heading)
        $cleanContent = $cleanContent -replace '(?m)^#\s+.*$', ''

        # Remove empty lines and whitespace
        $cleanContent = $cleanContent.Trim()

        # Check if nothing meaningful remains
        if ($cleanContent.Length -lt 10) {
            $isEmpty = $true
        }
    }

    if ($isEmpty) {
        $emptyOrphans += [PSCustomObject]@{
            Title = $title
            Path = $file.FullName
            Size = $file.Length
            Content = if ($content) { $content.Substring(0, [Math]::Min(100, $content.Length)) } else { "(empty)" }
        }
    }
}

Write-Host "`nFound $($emptyOrphans.Count) empty orphan files"

# Save to JSON
$emptyOrphans | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputFile -Encoding UTF8

# Display results
foreach ($orphan in $emptyOrphans) {
    Write-Host "`n$($orphan.Title)"
    Write-Host "  Path: $($orphan.Path)"
    Write-Host "  Size: $($orphan.Size) bytes"
}

Write-Host "`n=== Total: $($emptyOrphans.Count) files ==="
