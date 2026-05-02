# fix_calendar_summaries.ps1
# Adds YAML frontmatter to all Personal Calendar Summary files (2010-2025)
# Files are in vault root; they are left in place (not moved) per classification rules

$vaultRoot = 'D:\Obsidian\Main'   # Obsidian vault path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)   # UTF-8 without BOM
$count = 0   # Counter for files fixed

# Year range to process
2010..2025 | ForEach-Object {
    $year = $_   # Current year being processed
    $filePath = Join-Path $vaultRoot "$year Personal Calendar Summary.md"

    # Skip if file doesn't exist
    if (-not (Test-Path $filePath)) {
        Write-Output "MISSING: $year Personal Calendar Summary.md"
        return
    }

    # Read existing content as UTF-8 bytes
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

    # Skip if frontmatter already present (starts with ---)
    if ($content.TrimStart().StartsWith('---')) {
        Write-Output "SKIP (has frontmatter): $year"
        return
    }

    # Build description string — generic for all years
    $desc = "Annual summary of personal email and calendar activity for $year, covering family life, Bah$([char]0x00E1)$([char]0x2019)$([char]0x00ED) community, work, home, and finances."

    # Build title string
    $title = "$year Personal Calendar Summary"

    # Build nav pointing to PKM MOC
    $nav = "[[MOC - Personal Knowledge Management]]"

    # Build YAML frontmatter block as array of lines for clean UTF-8 handling
    $fm = @(
        "---",
        "title: `"$title`"",
        "created: 2026-04-15",
        "description: `"$desc`"",
        "tags:",
        "  - PersonalHistory",
        "  - PersonalCalendar",
        "  - EmailAnalysis",
        "  - `"$year`"",
        "nav: `"$nav`"",
        "---",
        ""
    )

    # Prepend frontmatter to existing content
    $newContent = ($fm -join "`n") + $content

    # Write back with UTF-8 no BOM
    [System.IO.File]::WriteAllText($filePath, $newContent, $utf8NoBom)
    Write-Output "FIXED: $year Personal Calendar Summary.md"
    $count++
}

Write-Output ""
Write-Output "Total fixed: $count files"
