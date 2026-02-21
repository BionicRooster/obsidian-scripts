$path = "D:\Obsidian\Main\20 - Permanent Notes"
Get-ChildItem $path -Filter "*.md" | ForEach-Object {
    $c = Get-Content $_.FullName -Raw -Encoding UTF8
    # Count occurrences of "---" followed by "tags:"
    $matches2 = [regex]::Matches($c, '(?m)^---\s*\r?\ntags:')
    if ($matches2.Count -gt 1) {
        Write-Host "DUPLICATE FRONTMATTER: $($_.Name)"
    }
}
