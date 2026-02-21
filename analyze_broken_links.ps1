# analyze_broken_links.ps1
# Script to categorize broken wikilinks in an Obsidian vault

param(
    [string]$VaultPath = "D:\Obsidian\Main"
)

$startTime = Get-Date

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Obsidian Broken Link Analyzer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Vault Path: $VaultPath" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $VaultPath)) {
    Write-Host "ERROR: Vault path does not exist: $VaultPath" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Building index of all existing notes..." -ForegroundColor Green

$allMarkdownFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File

$existingNotes = @{}
foreach ($file in $allMarkdownFiles) {
    $noteName = $file.BaseName
    $existingNotes[$noteName.ToLower()] = $file.FullName
}

$totalNotes = $existingNotes.Count
Write-Host "  Found $totalNotes existing notes in the vault" -ForegroundColor White

Write-Host ""
Write-Host "Step 2: Scanning ALL files for broken links..." -ForegroundColor Green

$wikiLinkPattern = '(?<!!)\[\[([^\]|#]+)(?:[#|][^\]]+)?\]\]'

# Categorize broken links
$brokenByCategory = @{
    'full_path' = @()
    'future_date' = @()
    'trailing_slash' = @()
    'trailing_space' = @()
    'simple_missing' = @()
}

$uniqueBrokenLinks = @{}

$filesProcessed = 0
$totalFiles = @($allMarkdownFiles).Count

foreach ($file in $allMarkdownFiles) {
    $filesProcessed++

    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    $matches = [regex]::Matches($content, $wikiLinkPattern)

    foreach ($match in $matches) {
        $linkedNoteName = $match.Groups[1].Value
        $noteExists = $existingNotes.ContainsKey($linkedNoteName.Trim().ToLower())

        if (-not $noteExists) {
            $category = 'simple_missing'

            # Check for full path (contains /)
            if ($linkedNoteName -match '/') {
                $category = 'full_path'
            }
            # Check for date pattern
            elseif ($linkedNoteName -match '^\d{4}-\d{2}-\d{2}$') {
                $category = 'future_date'
            }
            # Check for trailing slash
            elseif ($linkedNoteName.EndsWith('/')) {
                $category = 'trailing_slash'
            }
            # Check for trailing space
            elseif ($linkedNoteName -ne $linkedNoteName.Trim()) {
                $category = 'trailing_space'
            }

            $brokenByCategory[$category] += @{
                'File' = $file.FullName.Replace($VaultPath, "").TrimStart("\")
                'LinkName' = $linkedNoteName
                'FullMatch' = $match.Value
            }

            if (-not $uniqueBrokenLinks.ContainsKey($linkedNoteName)) {
                $uniqueBrokenLinks[$linkedNoteName] = 0
            }
            $uniqueBrokenLinks[$linkedNoteName]++
        }
    }

    if ($filesProcessed % 200 -eq 0) {
        Write-Host "    Processed $filesProcessed / $totalFiles files..." -ForegroundColor Gray
    }
}

Write-Host "  Scan complete!" -ForegroundColor White

$totalBroken = 0
foreach ($category in $brokenByCategory.Keys) {
    $totalBroken += $brokenByCategory[$category].Count
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  CATEGORIZED RESULTS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "TOTAL BROKEN LINKS: $totalBroken" -ForegroundColor Red
Write-Host "UNIQUE BROKEN TARGETS: $($uniqueBrokenLinks.Count)" -ForegroundColor Red
Write-Host ""

$categoryDescriptions = @{
    'full_path' = 'Links with folder paths (e.g., [[00 - Home/Note]])'
    'future_date' = 'Date links that do not have notes yet'
    'trailing_slash' = 'Links ending with / (e.g., [[Templates/]])'
    'trailing_space' = 'Links with trailing/leading whitespace'
    'simple_missing' = 'Simple links to non-existent notes'
}

foreach ($category in @('full_path', 'future_date', 'trailing_slash', 'trailing_space', 'simple_missing')) {
    $items = $brokenByCategory[$category]
    $count = $items.Count

    if ($count -gt 0) {
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Write-Host "CATEGORY: $category" -ForegroundColor Yellow
        Write-Host "Description: $($categoryDescriptions[$category])" -ForegroundColor Gray
        Write-Host "Count: $count broken links" -ForegroundColor White
        Write-Host ""

        Write-Host "Examples (up to 10):" -ForegroundColor Cyan
        $examples = $items | Select-Object -First 10
        foreach ($ex in $examples) {
            Write-Host "  File: $($ex.File)" -ForegroundColor DarkGray
            Write-Host "  Link: $($ex.FullMatch)" -ForegroundColor Red
            Write-Host ""
        }
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  TOP 20 MOST COMMON BROKEN LINK TARGETS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$topBroken = $uniqueBrokenLinks.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20

foreach ($item in $topBroken) {
    Write-Host "  $($item.Value) occurrences: [[$($item.Key)]]" -ForegroundColor White
}

$endTime = Get-Date
$elapsed = $endTime - $startTime

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SUMMARY FOR ACTION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "By category breakdown:" -ForegroundColor Yellow
Write-Host "  full_path:      $($brokenByCategory['full_path'].Count) links" -ForegroundColor White
Write-Host "  future_date:    $($brokenByCategory['future_date'].Count) links" -ForegroundColor White
Write-Host "  trailing_slash: $($brokenByCategory['trailing_slash'].Count) links" -ForegroundColor White
Write-Host "  trailing_space: $($brokenByCategory['trailing_space'].Count) links" -ForegroundColor White
Write-Host "  simple_missing: $($brokenByCategory['simple_missing'].Count) links" -ForegroundColor White
Write-Host ""
Write-Host "Elapsed time: $($elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Gray
