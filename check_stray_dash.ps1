$path = "D:\Obsidian\Main\20 - Permanent Notes"
Get-ChildItem $path -Filter "*.md" | Where-Object { $_.Name -match '^[I-Zx]' -or $_.Name -match '^[i-z]' } | ForEach-Object {
    $c = Get-Content $_.FullName -Raw -Encoding UTF8
    if ($c -match '(?m)^-\s*$' -and $c -match '(?s)^---') {
        # Check if there's a stray "^-$" line inside frontmatter
        if ($c -match '(?s)^---\r?\n(.*?)\r?\n---') {
            $yaml = $Matches[1]
            if ($yaml -match '(?m)^-\s*$') {
                Write-Host "STRAY DASH: $($_.Name)"
            }
        }
    }
}
