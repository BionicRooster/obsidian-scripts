$folder = "D:\Obsidian\Main\09 - Kindle Clippings"

function RemoveOutgoingLinks($path) {
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $original = $content

    # Remove ## Related Notes section (everything from ## Related Notes to next ## heading or end)
    $content = $content -replace '(?s)## Related Notes\s*\n(.*?)(?=\n## |\n# |\z)', ''

    # Remove **Navigation:** lines that contain wikilinks
    $content = $content -replace '(?m)^\*\*Navigation:\*\*.*\[\[.*\r?\n', ''

    # Remove standalone wikilink lines like:
    # - [[Some Note|Label]]
    # [[00 - Home Dashboard/MOC - ...]]
    $content = $content -replace '(?m)^- \[\[00 - Home Dashboard.*?\]\]\s*\r?\n', ''
    $content = $content -replace '(?m)^\[\[00 - Home Dashboard.*?\]\]\s*\r?\n', ''

    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Cleaned: $(Split-Path $path -Leaf)"
    }
}

# Process all .md files in the folder
$files = Get-ChildItem $folder -Filter "*.md"
foreach ($f in $files) {
    RemoveOutgoingLinks $f.FullName
}
Write-Host "Done."
