# Clean light HTML tags from Obsidian vault files
# Handles simple conversions: <br>, <b>, <i>, <strong>, <em>, <p>, <div>, <span>, etc.
$vault = 'D:\Obsidian\Main'
$skipPatterns = @('\\People\\', '\\Journals\\', '\\00 - Journal\\', '\\Templates\\', '\\.resources', '\\images\\', '\\Attachments\\', '\\00 - Images\\', '\\00 - Home Dashboard\\', '\\09 - Kindle Clippings\\', '\\.trash\\', '\\05 - Templates\\')

# HTML tag pattern for detection
$htmlPattern = '<(?:div|span|table|tr|td|th|p|br|img|a\s|h[1-6]|ul|ol|li|strong|em|b\s|i\s|style|script|center|font|blockquote|/div|/span|/table|/tr|/td|/th|/p|/h[1-6]|/ul|/ol|/li|/strong|/em|/b|/i|/style|/script|/center|/font|/blockquote|/a|!--|meta|link|head|body|html|/head|/body|/html|section|/section|header|/header|footer|/footer|nav|/nav|article|/article|aside|/aside|figure|/figure|figcaption|/figcaption|picture|/picture|source)[>\s/]'

# Only process files with 1-9 HTML tags (light files)
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

        # Read file content as string
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)

        $matches = [regex]::Matches($content, $htmlPattern)
        # Only process files with 1-9 tags
        if ($matches.Count -lt 1 -or $matches.Count -gt 9) { continue }

        $original = $content

        # --- Perform HTML-to-Markdown conversions ---

        # <br> and <br/> and <br /> -> newline
        $content = [regex]::Replace($content, '<br\s*/?>', "`n")

        # <strong>text</strong> -> **text**
        $content = [regex]::Replace($content, '<strong>(.*?)</strong>', '**$1**')

        # <b>text</b> -> **text** (but not <blockquote>)
        $content = [regex]::Replace($content, '<b>(.*?)</b>', '**$1**')

        # <em>text</em> -> *text*
        $content = [regex]::Replace($content, '<em>(.*?)</em>', '*$1*')

        # <i>text</i> -> *text* (but not <img>)
        $content = [regex]::Replace($content, '<i>(.*?)</i>', '*$1*')

        # <a href="url">text</a> -> [text](url)
        $content = [regex]::Replace($content, '<a\s+href="([^"]*)"[^>]*>(.*?)</a>', '[$2]($1)')
        $content = [regex]::Replace($content, "<a\s+href='([^']*)'[^>]*>(.*?)</a>", '[$2]($1)')

        # <p>text</p> -> text with blank line
        $content = [regex]::Replace($content, '<p[^>]*>(.*?)</p>', "`$1`n")

        # <h1>text</h1> through <h6>text</h6>
        $content = [regex]::Replace($content, '<h1[^>]*>(.*?)</h1>', "# `$1")
        $content = [regex]::Replace($content, '<h2[^>]*>(.*?)</h2>', "## `$1")
        $content = [regex]::Replace($content, '<h3[^>]*>(.*?)</h3>', "### `$1")
        $content = [regex]::Replace($content, '<h4[^>]*>(.*?)</h4>', "#### `$1")
        $content = [regex]::Replace($content, '<h5[^>]*>(.*?)</h5>', "##### `$1")
        $content = [regex]::Replace($content, '<h6[^>]*>(.*?)</h6>', "###### `$1")

        # <ul>, </ul>, <ol>, </ol> -> remove (list structure handled by <li>)
        $content = [regex]::Replace($content, '</?[ou]l[^>]*>', '')

        # <li>text</li> -> - text
        $content = [regex]::Replace($content, '<li[^>]*>(.*?)</li>', "- `$1")

        # <blockquote>text</blockquote> -> > text
        $content = [regex]::Replace($content, '<blockquote[^>]*>(.*?)</blockquote>', "> `$1")

        # Remove remaining container tags: <div>, </div>, <span>, </span>, <center>, </center>, <font>, </font>
        $content = [regex]::Replace($content, '</?(?:div|span|center|font|section|article|aside|header|footer|nav|figure|figcaption)[^>]*>', '')

        # Remove <!-- comments -->
        $content = [regex]::Replace($content, '<!--.*?-->', '')

        # Remove <meta ...> and <link ...> tags
        $content = [regex]::Replace($content, '<(?:meta|link)[^>]*/?\s*>', '')

        # Clean up multiple blank lines (more than 2 consecutive)
        $content = [regex]::Replace($content, '(\r?\n){4,}', "`n`n`n")

        # Only write if content changed
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
