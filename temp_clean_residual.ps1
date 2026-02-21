# Clean residual HTML tags: <img> branding logos, stray tags
$vault = 'D:\Obsidian\Main'
$skipPatterns = @('\\People\\', '\\Journals\\', '\\00 - Journal\\', '\\Templates\\', '\\.resources', '\\images\\', '\\Attachments\\', '\\00 - Images\\', '\\00 - Home Dashboard\\', '\\09 - Kindle Clippings\\', '\\.trash\\', '\\05 - Templates\\')

$htmlPattern = '<(?:div|span|table|tr|td|th|p|br|img|a\s|h[1-6]|ul|ol|li|strong|em|b\s|i\s|style|script|center|font|blockquote|/div|/span|/table|/tr|/td|/th|/p|/h[1-6]|/ul|/ol|/li|/strong|/em|/b|/i|/style|/script|/center|/font|/blockquote|/a|!--|meta|link|head|body|html|/head|/body|/html|section|/section|header|/header|footer|/footer|nav|/nav|article|/article|aside|/aside|figure|/figure|figcaption|/figcaption|picture|/picture|source)[>\s/]'

$searchDirs = @("$vault\01", "$vault\10 - Clippings", "$vault\20 - Permanent Notes", "$vault\02 - Working Projects")
$changed = 0

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
        # Only process files with 1-5 remaining tags
        if ($matches.Count -lt 1 -or $matches.Count -gt 5) { continue }

        $original = $content

        # Remove Perplexity branding logo images
        $content = [regex]::Replace($content, '<img\s+src="https://r2cdn[^"]*perplexity[^"]*"[^/]*/>', '')

        # Convert remaining <img src="url"> to ![](url)
        $content = [regex]::Replace($content, '<img\s+src="([^"]*)"[^/]*/\s*>', '![]($1)')

        # Remove <source ...> tags
        $content = [regex]::Replace($content, '<source[^>]*/?\s*>', '')

        # Clean up blank lines from removals
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
        }
    }
}

Write-Host ""
Write-Host "Files cleaned: $changed"
