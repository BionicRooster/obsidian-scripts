# Fix misspellings of Bahá'u'lláh across the Obsidian vault
# Handles multiple variant spellings, preserves UTF-8 encoding

$vaultPath = 'D:\Obsidian\Main'
$correct = "Bahá'u'lláh"

# All misspelling patterns to fix (ordered most-specific first to avoid partial replacements)
$misspellings = @(
    "Baha'u'llah",   # most common - missing diacriticals
    "Baha'u`'llah",  # escaped apostrophe variant
    "Bahaullah",      # no punctuation at all
    "Baha u llah",   # spaces, no diacriticals
    "Bah u llah",    # spaces, no diacriticals (fewer letters)
    "Bah'u'llah",    # missing first a and diacriticals
    "Bahau'llah"     # missing apostrophe after u
)

$totalFiles  = 0   # count of files modified
$totalFixes  = 0   # count of replacements made
$results     = @() # log of each fix for reporting

# Get all markdown files in the vault
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter '*.md'

foreach ($file in $files) {
    # Read file content with UTF-8 encoding (no BOM stripping)
    $original = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    if (-not $original) { continue }

    $modified = $original
    $fileFixed = 0

    foreach ($bad in $misspellings) {
        # Count occurrences before replacement
        $count = ([regex]::Matches($modified, [regex]::Escape($bad))).Count
        if ($count -gt 0) {
            $modified = $modified.Replace($bad, $correct)
            $fileFixed += $count
            $results += [PSCustomObject]@{
                File    = $file.FullName.Replace($vaultPath + '\', '')
                Bad     = $bad
                Fixed   = $count
            }
        }
    }

    # Write back only if changes were made
    if ($fileFixed -gt 0) {
        Set-Content -LiteralPath $file.FullName -Value $modified -Encoding UTF8 -NoNewline
        $totalFiles++
        $totalFixes += $fileFixed
    }
}

# Report results
Write-Host "`nBahá'u'lláh spelling fix complete"
Write-Host "Files modified : $totalFiles"
Write-Host "Replacements   : $totalFixes"
Write-Host ""
Write-Host "Details:"
$results | Format-Table -AutoSize
