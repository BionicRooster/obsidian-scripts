# Clean moderate HTML tags from Obsidian vault files (10-49 tags)
# Same conversions as light script but targeting files with 10-49 tags
$vault = 'D:\Obsidian\Main'
$skipPatterns = @('\\People\\', '\\Journals\\', '\\00 - Journal\\', '\\Templates\\', '\\.resources', '\\images\\', '\\Attachments\\', '\\00 - Images\\', '\\00 - Home Dashboard\\', '\\09 - Kindle Clippings\\', '\\.trash\\', '\\05 - Templates\\')

# HTML tag pattern for detection
$htmlPattern = '<(?:div|span|table|tr|td|th|p|br|img|a\s|h[1-6]|ul|ol|li|strong|em|b\s|i\s|style|script|center|font|blockquote|/div|/span|/table|/tr|/td|/th|/p|/h[1-6]|/ul|/ol|/li|/strong|/em|/b|/i|/style|/script|/center|/font|/blockquote|/a|!--|meta|link|head|body|html|/head|/body|/html|section|/section|header|/header|footer|/footer|nav|/nav|article|/article|aside|/aside|figure|/figure|figcaption|/figcaption|picture|/picture|source)[>\s/]'

$searchDirs = @("$vault\01", "$vault\10 - Clippings", "$vault\20 - Permanent Notes", "$vault\02 - Working Projects")
$changed = 0
$skipped = 0

foreach ($dir in $searchDirs) {
    if (-not (Test-Path $dir)) { continue }
    $files = Get-ChildItem $dir -Filter '*.md' -Recurse
    foreach ($f in $files) {
        $path = $f.FullName
        $skip = $false
        foreach ($p in $skipPatterns) {
            if ($path -like "*$p*") { $skip = $true; break }
        }
        if ($skip) { continue }

        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)

        $matches = [regex]::Matches($content, $htmlPattern)
        # Only process files with 10-49 tags
        if ($matches.Count -lt 10 -or $matches.Count -gt 49) { continue }

        $original = $content

        # --- Perform HTML-to-Markdown conversions ---
        $content = [regex]::Replace($content, '<br\s*/?>', "`n")
        $content = [regex]::Replace($content, '<strong>(.*?)</strong>', '**$1**')
        $content = [regex]::Replace($content, '<b>(.*?)</b>', '**$1**')
        $content = [regex]::Replace($content, '<em>(.*?)</em>', '*$1*')
        $content = [regex]::Replace($content, '<i>(.*?)</i>', '*$1*')
        $content = [regex]::Replace($content, '<a\s+href="([^"]*)"[^>]*>(.*?)</a>', '[$2]($1)')
        $content = [regex]::Replace($content, "<a\s+href='([^']*)'[^>]*>(.*?)</a>", '[$2]($1)')
        $content = [regex]::Replace($content, '<p[^>]*>(.*?)</p>', "`$1`n")
        $content = [regex]::Replace($content, '<h1[^>]*>(.*?)</h1>', "# `$1")
        $content = [regex]::Replace($content, '<h2[^>]*>(.*?)</h2>', "## `$1")
        $content = [regex]::Replace($content, '<h3[^>]*>(.*?)</h3>', "### `$1")
        $content = [regex]::Replace($content, '<h4[^>]*>(.*?)</h4>', "#### `$1")
        $content = [regex]::Replace($content, '<h5[^>]*>(.*?)</h5>', "##### `$1")
        $content = [regex]::Replace($content, '<h6[^>]*>(.*?)</h6>', "###### `$1")
        $content = [regex]::Replace($content, '</?[ou]l[^>]*>', '')
        $content = [regex]::Replace($content, '<li[^>]*>(.*?)</li>', "- `$1")
        $content = [regex]::Replace($content, '<blockquote[^>]*>(.*?)</blockquote>', "> `$1")
        $content = [regex]::Replace($content, '</?(?:div|span|center|font|section|article|aside|header|footer|nav|figure|figcaption)[^>]*>', '')
        $content = [regex]::Replace($content, '<!--.*?-->', '')
        $content = [regex]::Replace($content, '<(?:meta|link)[^>]*/?\s*>', '')
        $content = [regex]::Replace($content, '(\r?\n){4,}', "`n`n`n")

        if ($content -ne $original) {
            if ($hasBom) {
                [System.IO.File]::WriteAllText($f.FullName, $content, [System.Text.UTF8Encoding]::new($true))
            } else {
                [System.IO.File]::WriteAllText($f.FullName, $content, [System.Text.UTF8Encoding]::new($false))
            }
            $remaining = [regex]::Matches($content, $htmlPattern).Count
            $relPath = $f.FullName.Replace("$vault\", '')
            Write-Host "CLEANED: $relPath ($($matches.Count) -> $remaining tags)"
            $changed++
        } else {
            $skipped++
        }
    }
}

Write-Host ""
Write-Host "Files cleaned: $changed"
Write-Host "Files skipped (no change): $skipped"
