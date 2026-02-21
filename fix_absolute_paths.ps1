# Fix absolute paths in Related Notes sections
$vaultPath = 'D:\Obsidian\Main'
$count = 0

# Get all markdown files except in excluded folders
$files = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch '09 - Kindle Clippings|\.trash|05 - Templates|\.obsidian|\.smart-env'
}

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Check for absolute paths in wikilinks
    if ($content -match '\[\[D:/Obsidian/Main/') {
        # Replace absolute paths with relative paths
        $newContent = $content -replace '\[\[D:/Obsidian/Main/', '[['

        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        $count++
    }
}

Write-Host "Fixed absolute paths in $count files"
