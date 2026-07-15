# fix_bahaullah.ps1
# Fixes misspellings of Bahá'u'lláh across the Obsidian vault
#
# Two garbled patterns corrected:
#   Pattern 1: Bah'u'llh  (70 occurrences, 30 files) — missing both á and final a
#   Pattern 2: Baha'u'llah (50 occurrences, 8 files)  — missing diacritics
# Both straight apostrophe (U+0027) and curly right quote (U+2019) variants handled.
#
# Safe exclusions (not affected by these patterns):
#   - "Bahaullah" in tags: no apostrophes, won't match
#   - [[All Religions Are One Bahai - Bahaullah]] wikilinks: no apostrophes, won't match
#   - title: All Religions Are One Bahai - Bahaullah  frontmatter: same

$vaultPath   = "C:\Users\awt\Sync\Obsidian"
$correct     = "Bahá'u'lláh"          # target with full diacritics (á, á) and right-single curly apostrophes

# Apostrophe variants to match
$apos  = [string][char]0x0027   # straight apostrophe '
$curly = [string][char]0x2019   # curly right-single-quotation-mark '

# Pattern 1 variants: Bah?u?llh  (garbled — both á missing, no trailing 'a')
$p1 = @(
    "Bah${apos}u${apos}llh",     # straight/straight
    "Bah${curly}u${curly}llh",   # curly/curly
    "Bah${apos}u${curly}llh",    # straight/curly
    "Bah${curly}u${apos}llh"     # curly/straight
)

# Pattern 2 variants: Baha?u?llah  (no diacritics on either á)
$p2 = @(
    "Baha${apos}u${apos}llah",
    "Baha${curly}u${curly}llah",
    "Baha${apos}u${curly}llah",
    "Baha${curly}u${apos}llah"
)

# All patterns combined
$allPatterns = $p1 + $p2

# Tracking counters
$totalFiles        = 0
$totalReplacements = 0
$results           = @()

# Enumerate all markdown files recursively
$files = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $files) {
    # Read entire file as UTF-8 string
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    $newContent   = $content
    $replacements = 0

    foreach ($pattern in $allPatterns) {
        # Count occurrences of this pattern before replacement
        $escaped  = [regex]::Escape($pattern)
        $matches  = ([regex]::Matches($newContent, $escaped)).Count
        if ($matches -gt 0) {
            $newContent    = $newContent -replace $escaped, $correct
            $replacements += $matches
        }
    }

    if ($replacements -gt 0) {
        # Write back with UTF-8 encoding (no BOM — preserve existing behavior)
        [System.IO.File]::WriteAllText($file.FullName, $newContent, (New-Object System.Text.UTF8Encoding $false))
        $totalFiles++
        $totalReplacements += $replacements
        $results += [PSCustomObject]@{
            File         = $file.Name
            Replacements = $replacements
            Path         = $file.FullName
        }
        Write-Output "Fixed ($replacements): $($file.Name)"
    }
}

Write-Output ""
Write-Output "=== SUMMARY ==="
Write-Output "Files modified  : $totalFiles"
Write-Output "Total fixes     : $totalReplacements"
