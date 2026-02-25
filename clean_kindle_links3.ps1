$folder = "D:\Obsidian\Main\09 - Kindle Clippings"

function CleanAllLinks($path) {
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $original = $content

    # Remove standalone bullet wikilink lines: "- [[...]]" with optional alias
    $content = $content -replace '(?m)^- \[\[[^\]]+\]\]\s*\r?\n', ''

    # Convert inline wikilinks in headings/titles to plain text (keep alias if present)
    # [[link|alias]] -> alias
    # [[link]] -> link
    $content = $content -replace '\[\[([^\]|]+)\|([^\]]+)\]\]', '$2'
    $content = $content -replace '\[\[([^\]]+)\]\]', '$1'

    # Clean up blank lines left by removed bullet lists (multiple blanks -> single blank)
    $content = $content -replace '(\r?\n){3,}', "`n`n"

    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Cleaned: $(Split-Path $path -Leaf)"
    }
}

$files = Get-ChildItem $folder -Filter "*.md"
foreach ($f in $files) {
    CleanAllLinks $f.FullName
}
Write-Host "Done."
