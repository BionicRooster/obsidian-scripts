# Test script to compare orphan detection methods
$vaultPath = "D:\Obsidian\Main"

# Get all .md files
$allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

# Build linked files hashtable (case-sensitive like get_orphans.ps1)
$linkedFilesCaseSensitive = @{}
# Build linked files hashtable (case-insensitive like link_largest_orphan.ps1)
$linkedFilesCaseInsensitive = @{}

foreach ($file in $allFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $matches = [regex]::Matches($content, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
        foreach ($match in $matches) {
            $linkTarget = $match.Groups[1].Value
            if ($linkTarget -match '/') { $linkTarget = $linkTarget.Split('/')[-1] }
            if ($linkTarget -match '#') { $linkTarget = $linkTarget.Split('#')[0] }
            $linkTarget = $linkTarget.Trim()
            if ($linkTarget) {
                $linkedFilesCaseSensitive[$linkTarget] = $true
                $linkedFilesCaseInsensitive[$linkTarget.ToLower()] = $true
            }
        }
    }
}

# Count orphans with case-sensitive matching
$orphansCaseSensitive = 0
$orphansCaseInsensitive = 0

foreach ($file in $allFiles) {
    if (-not $linkedFilesCaseSensitive.ContainsKey($file.BaseName)) {
        $orphansCaseSensitive++
    }
    if (-not $linkedFilesCaseInsensitive.ContainsKey($file.BaseName.ToLower())) {
        $orphansCaseInsensitive++
    }
}

Write-Host "=== ORPHAN DETECTION COMPARISON ==="
Write-Host "Total .md files: $($allFiles.Count)"
Write-Host "Unique link targets (case-sensitive): $($linkedFilesCaseSensitive.Count)"
Write-Host "Unique link targets (case-insensitive): $($linkedFilesCaseInsensitive.Count)"
Write-Host ""
Write-Host "Orphans (case-sensitive matching): $orphansCaseSensitive"
Write-Host "Orphans (case-insensitive matching): $orphansCaseInsensitive"
Write-Host ""
Write-Host "Difference: $($orphansCaseSensitive - $orphansCaseInsensitive) more orphans found with case-sensitive"
