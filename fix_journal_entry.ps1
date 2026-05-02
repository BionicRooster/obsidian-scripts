# Fix the malformed journal entry and replace with correct activity log

$journal = 'D:\Obsidian\Main\2026-04-28.md'
$content = Get-Content -LiteralPath $journal -Encoding UTF8 -Raw

# Remove the bad inserted line (the one with literal \n and backtick)
$badLine = "- Added **Donath** and **Davidson** to surname blocklist in obsidian_maintenance.ps1``n- **Classify All Unclassified Notes** complete: 186 notes linked across 14 MOCs; 0 content notes unclassified"
$content = $content -replace [regex]::Escape($badLine), ''

# Clean up any resulting double blank lines
$content = $content -replace '(\r?\n){3,}', "`n`n"

# Now find ## My Notes and insert after the heading
$notesHeading = '## My Notes'
$idx = $content.IndexOf($notesHeading)
if ($idx -ge 0) {
    $afterHeading = $idx + $notesHeading.Length
    $activityLog = @"

- Added **Donath** and **Davidson** to surname false-positive blocklist in ``obsidian_maintenance.ps1``
- **Classify All Unclassified Notes** complete: linked ~186 notes across 14 MOC files; fixed run-together lines in Technology and Recipes MOCs; renamed 2 garbled recipe files; 0 content notes unclassified
"@
    $content = $content.Substring(0, $afterHeading) + $activityLog + $content.Substring($afterHeading)
    Set-Content -LiteralPath $journal -Value $content -Encoding UTF8 -NoNewline
    Write-Output "Journal entry fixed"
} else {
    Write-Output "WARNING: ## My Notes section not found"
}
