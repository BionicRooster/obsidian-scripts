# Fix The Tablet of Ahmad - add breadcrumb, clean Related Notes
$dir = Get-ChildItem 'D:\Obsidian\Main\01\Bah*' -Directory | Select-Object -First 1
$ahmadFile = Get-ChildItem $dir.FullName | Where-Object { $_.Name -like 'The Tablet of Ahmad.md' } | Select-Object -First 1

if ($ahmadFile) {
    $content = Get-Content $ahmadFile.FullName -Encoding UTF8 -Raw

    # Add breadcrumb after closing frontmatter --- if not already present
    if ($content -notmatch "\[\[01/Bah") {
        $content = $content -replace "(nav: "".*?""\r?\n---\r?\n)", "`$1`n[[01/Bah$([char]0x00E1)'$([char]0x00ED)]] | [[MOC - Bah$([char]0x00E1)'$([char]0x00ED) Faith]]`n`n"
    }

    # Replace messy Related Notes section with clean verified links
    $cleanRelated = @"

---
## Related Notes
- [[A Flame of Fire The Story of the Tablet of Ahmad]]
- [[Bah$([char]0x00E1)'u'll$([char]0x00E1)h]]
- [['Abdu'l-Bah$([char]0x00E1)]]
- [[The Bab]]
"@
    # Remove everything from a blank-line + ## Related Notes to end of file
    $content = $content -replace "(?s)\r?\n---\r?\n## Related Notes.*$", $cleanRelated

    [System.IO.File]::WriteAllText($ahmadFile.FullName, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Fixed Ahmad: $($ahmadFile.Name)"
} else {
    Write-Host "Ahmad file not found"
}

# Fix Daily Reading - add frontmatter, nav, breadcrumb
$dailyFile = Get-ChildItem $dir.FullName | Where-Object { $_.Name -like '*Daily Reading*' } | Select-Object -First 1

if ($dailyFile) {
    $content = Get-Content $dailyFile.FullName -Encoding UTF8 -Raw

    # Only add frontmatter if missing
    if ($content -notmatch '^---') {
        # Remove inline tags from the content body
        $body = $content -replace '#Bahaullah #bahai\s*\r?\n', ''
        $body = $body.TrimStart()

        $nav = "[[MOC - Bah$([char]0x00E1)'$([char]0x00ED) Faith]]"
        $breadcrumb = "[[01/Bah$([char]0x00E1)'$([char]0x00ED)]] | [[MOC - Bah$([char]0x00E1)'$([char]0x00ED) Faith]]"
        $newContent = "---`ntags:`n  - bahai`n  - DailyReading`n  - Bahaullah`nnav: ""$nav""`n---`n`n$breadcrumb`n`n$body"

        [System.IO.File]::WriteAllText($dailyFile.FullName, $newContent, [System.Text.Encoding]::UTF8)
        Write-Host "Fixed Daily: $($dailyFile.Name)"
    } else {
        Write-Host "Daily reading already has frontmatter"
    }
} else {
    Write-Host "Daily reading file not found"
}
