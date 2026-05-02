# Append LSA move activity to today's journal

$journal = 'D:\Obsidian\Main\2026-04-28.md'
$content = Get-Content -LiteralPath $journal -Encoding UTF8 -Raw

$newEntries = @"

- Moved **LSA** folder: ``D:\Obsidian\Main\LSA`` -> ``01\Bah$([char]0x00e1)'$([char]0x00ed)\LSA``
- Renamed 21 files: ``Be161.md``–``Be181.md`` -> ``BE161.md``–``BE181.md`` (Bah$([char]0x00e1)'$([char]0x00ed) Era capitalization)
- Added ``nav: "[[MOC - Bah$([char]0x00e1)'$([char]0x00ed) Faith]]"`` to all 21 BE files
- Updated 111 wikilinks ``[[Be1xx]]`` -> ``[[BE1xx]]`` in People Index (88) and 12 People files (23)
"@

# Find ## My Notes and append before the next section
$notesHeading = '## My Notes'
$idx = $content.IndexOf($notesHeading)
if ($idx -ge 0) {
    $afterHeading = $idx + $notesHeading.Length
    $nextSection = [regex]::Match($content.Substring($afterHeading), '(?m)^---')
    if ($nextSection.Success) {
        $insertPos = $afterHeading + $nextSection.Index
        $content = $content.Substring(0, $insertPos) + $newEntries + "`n" + $content.Substring($insertPos)
    } else {
        $content = $content.TrimEnd() + $newEntries + "`n"
    }
    Set-Content -LiteralPath $journal -Value $content -Encoding UTF8 -NoNewline
    Write-Output "Activity log appended"
}
