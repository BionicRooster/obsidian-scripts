# Count HTML tags per file to assess severity
$vault = 'D:\Obsidian\Main'
$skipPatterns = @('\\People\\', '\\Journals\\', '\\00 - Journal\\', '\\Templates\\', '\\.resources', '\\images\\', '\\Attachments\\', '\\00 - Images\\', '\\00 - Home Dashboard\\', '\\09 - Kindle Clippings\\', '\\.trash\\', '\\05 - Templates\\')

# HTML tag pattern
$htmlPattern = '<(?:div|span|table|tr|td|th|p|br|img|a\s|h[1-6]|ul|ol|li|strong|em|b\s|i\s|style|script|center|font|blockquote|/div|/span|/table|/tr|/td|/th|/p|/h[1-6]|/ul|/ol|/li|/strong|/em|/b|/i|/style|/script|/center|/font|/blockquote|/a|!--|meta|link|head|body|html|/head|/body|/html|section|/section|header|/header|footer|/footer|nav|/nav|article|/article|aside|/aside|figure|/figure|figcaption|/figcaption|picture|/picture|source)[>\s/]'

$results = @()

# Search in 01 and other content dirs
$searchDirs = @("$vault\01", "$vault\10 - Clippings", "$vault\20 - Permanent Notes", "$vault\02 - Working Projects")

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

        $content = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content) {
            $matches = [regex]::Matches($content, $htmlPattern)
            if ($matches.Count -gt 0) {
                $results += [PSCustomObject]@{
                    File = $f.FullName.Replace("$vault\", '')
                    Count = $matches.Count
                    Size = $f.Length
                }
            }
        }
    }
}

$results = $results | Sort-Object Count -Descending

Write-Host "Files with HTML tags (sorted by severity):"
Write-Host "============================================"
foreach ($r in $results) {
    Write-Host ("{0,4} tags | {1,7} bytes | {2}" -f $r.Count, $r.Size, $r.File)
}
Write-Host ""
Write-Host "Total files: $($results.Count)"
