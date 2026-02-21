# scan_recipe_yaml.ps1
# Scans all .md files in the Recipes folder for malformed YAML frontmatter
# Issues checked:
#   1. Mixed inline/block tags: tags: [recipe] followed by "  - recipe" (invalid YAML)
#   2. nav: appearing outside the YAML frontmatter (in note body)
#   3. Tags appearing in the note body instead of inside YAML frontmatter
#   4. Blank lines inside the YAML frontmatter

# Path to recipes folder
$recipesPath = "D:\Obsidian\Main\01\Recipes"

# Get all markdown files in the recipes folder
$files = Get-ChildItem -Path $recipesPath -Filter "*.md" -Recurse

# Counters for summary
$totalFiles = 0
$issueFiles = 0

# Arrays to store issues by category
$issue1_MixedTags = @()
$issue2_NavOutside = @()
$issue3_TagsInBody = @()
$issue4_BlankInFM = @()
$issue5_Other = @()

foreach ($file in $files) {
    $totalFiles++

    # Read the file content as UTF-8
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    # Skip empty files
    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    # Split into lines for analysis
    $lines = $content -split "`n"

    # Track issues for this file
    $fileIssues = @()

    # Find the YAML frontmatter boundaries
    # First line should be ---
    $fmStart = -1
    $fmEnd = -1

    # Find opening ---
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $trimmed = $lines[$i].Trim()
        if ($trimmed -eq "---") {
            $fmStart = $i
            break
        }
        # If first non-empty line is not ---, no frontmatter
        if ($trimmed -ne "") {
            break
        }
    }

    # Find closing ---
    if ($fmStart -ge 0) {
        for ($i = $fmStart + 1; $i -lt $lines.Count; $i++) {
            $trimmed = $lines[$i].Trim()
            if ($trimmed -eq "---") {
                $fmEnd = $i
                break
            }
        }
    }

    # Extract frontmatter lines (between --- markers, exclusive)
    $fmLines = @()
    if ($fmStart -ge 0 -and $fmEnd -gt $fmStart) {
        for ($i = $fmStart + 1; $i -lt $fmEnd; $i++) {
            $fmLines += $lines[$i]
        }
    }

    # Extract body lines (after closing ---)
    $bodyLines = @()
    if ($fmEnd -ge 0) {
        for ($i = $fmEnd + 1; $i -lt $lines.Count; $i++) {
            $bodyLines += $lines[$i]
        }
    }

    # ===== CHECK 1: Mixed inline/block tags =====
    # Look for tags: [recipe] (inline array) followed by "  - recipe" or similar block sequence items
    $hasInlineTags = $false
    $hasBlockTagItem = $false
    $inlineTagLine = -1

    for ($i = 0; $i -lt $fmLines.Count; $i++) {
        $line = $fmLines[$i]
        if ($line -match '^\s*tags:\s*\[') {
            $hasInlineTags = $true
            $inlineTagLine = $i
        }
        # Check for block sequence items after inline tags line
        if ($hasInlineTags -and $i -gt $inlineTagLine -and $line -match '^\s+-\s+') {
            $hasBlockTagItem = $true
        }
    }

    if ($hasInlineTags -and $hasBlockTagItem) {
        $fileIssues += "ISSUE 1: Mixed inline/block tags (tags: [...] followed by '- item')"
        $issue1_MixedTags += $file.Name
    }

    # ===== CHECK 2: nav: outside frontmatter =====
    # Check if nav: appears in the body
    $navInBody = $false
    $navInFM = $false

    foreach ($line in $fmLines) {
        if ($line -match '^\s*nav:\s') {
            $navInFM = $true
        }
    }

    foreach ($line in $bodyLines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^nav:\s') {
            $navInBody = $true
        }
    }

    if ($navInBody) {
        $detail = if ($navInFM) { "ISSUE 2: nav: appears BOTH in frontmatter AND in body" } else { "ISSUE 2: nav: appears OUTSIDE frontmatter (in body)" }
        $fileIssues += $detail
        $issue2_NavOutside += $file.Name
    }

    # ===== CHECK 3: Tags in body =====
    # Look for tag-like patterns in body: "tags:" or "  - recipe" at start of body
    $tagsInBody = $false
    $tagBodyDetail = ""

    foreach ($line in $bodyLines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^tags:\s') {
            $tagsInBody = $true
            $tagBodyDetail = "tags: property in body"
        }
        # Also check for orphaned block sequence tag items right after frontmatter
        if ($trimmed -match '^\s*-\s+(recipe|food|cooking|baking|dessert|vegetarian|vegan)') {
            $tagsInBody = $true
            $tagBodyDetail = "tag list item in body: $trimmed"
        }
    }

    # Check first few body lines specifically for tag items that fell out of frontmatter
    $bodyStart = [Math]::Min(5, $bodyLines.Count)
    for ($i = 0; $i -lt $bodyStart; $i++) {
        $trimmed = $bodyLines[$i].Trim()
        if ($trimmed -match '^\s*-\s+\w+$' -and $i -lt 3) {
            # Could be a tag that fell out - only flag if it looks like a common tag
            if ($trimmed -match '^\s*-\s+(recipe|food|cooking|baking|dessert|vegetarian|vegan|breakfast|dinner|lunch|snack|soup|salad|chicken|beef|pork|seafood|pasta|bread|cake|cookie|pie|drink|appetizer|side)$') {
                $tagsInBody = $true
                $tagBodyDetail = "tag list item in body (line $($fmEnd + 2 + $i)): $trimmed"
            }
        }
    }

    if ($tagsInBody) {
        $fileIssues += "ISSUE 3: $tagBodyDetail"
        $issue3_TagsInBody += $file.Name
    }

    # ===== CHECK 4: Blank lines inside frontmatter =====
    $blankInFM = $false
    $blankLineNumbers = @()

    for ($i = 0; $i -lt $fmLines.Count; $i++) {
        if ($fmLines[$i].Trim() -eq "") {
            $blankInFM = $true
            # Line number in original file (fmStart is 0-indexed, +1 for header ---, +1 for 1-based)
            $blankLineNumbers += ($fmStart + 1 + $i + 1)
        }
    }

    if ($blankInFM) {
        $lineNums = $blankLineNumbers -join ", "
        $fileIssues += "ISSUE 4: Blank line(s) inside frontmatter at line(s): $lineNums"
        $issue4_BlankInFM += $file.Name
    }

    # ===== CHECK 5: No frontmatter at all =====
    if ($fmStart -lt 0 -or $fmEnd -lt 0) {
        $fileIssues += "ISSUE 5: No valid YAML frontmatter found"
        $issue5_Other += $file.Name
    }

    # Report issues for this file
    if ($fileIssues.Count -gt 0) {
        $issueFiles++
        Write-Host "`n=== $($file.Name) ===" -ForegroundColor Yellow
        foreach ($issue in $fileIssues) {
            Write-Host "  $issue" -ForegroundColor Red
        }

        # Show first 20 lines for context if there are issues
        $showLines = [Math]::Min(20, $lines.Count)
        Write-Host "  --- First $showLines lines ---" -ForegroundColor Gray
        for ($i = 0; $i -lt $showLines; $i++) {
            $lineNum = $i + 1
            $displayLine = $lines[$i] -replace "`r", ""
            Write-Host "    ${lineNum}: $displayLine" -ForegroundColor DarkGray
        }
    }
}

# ===== SUMMARY =====
Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total files scanned: $totalFiles"
Write-Host "Files with issues: $issueFiles"
Write-Host ""

if ($issue1_MixedTags.Count -gt 0) {
    Write-Host "ISSUE 1 - Mixed inline/block tags ($($issue1_MixedTags.Count) files):" -ForegroundColor Yellow
    foreach ($f in $issue1_MixedTags) { Write-Host "  - $f" }
    Write-Host ""
}

if ($issue2_NavOutside.Count -gt 0) {
    Write-Host "ISSUE 2 - nav: outside frontmatter ($($issue2_NavOutside.Count) files):" -ForegroundColor Yellow
    foreach ($f in $issue2_NavOutside) { Write-Host "  - $f" }
    Write-Host ""
}

if ($issue3_TagsInBody.Count -gt 0) {
    Write-Host "ISSUE 3 - Tags in body ($($issue3_TagsInBody.Count) files):" -ForegroundColor Yellow
    foreach ($f in $issue3_TagsInBody) { Write-Host "  - $f" }
    Write-Host ""
}

if ($issue4_BlankInFM.Count -gt 0) {
    Write-Host "ISSUE 4 - Blank lines in frontmatter ($($issue4_BlankInFM.Count) files):" -ForegroundColor Yellow
    foreach ($f in $issue4_BlankInFM) { Write-Host "  - $f" }
    Write-Host ""
}

if ($issue5_Other.Count -gt 0) {
    Write-Host "ISSUE 5 - No valid frontmatter ($($issue5_Other.Count) files):" -ForegroundColor Yellow
    foreach ($f in $issue5_Other) { Write-Host "  - $f" }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
