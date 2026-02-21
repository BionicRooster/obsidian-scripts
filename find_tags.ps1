# Find all tags in Obsidian vault and list files where they appear
$vaultPath = "D:\Obsidian\Main"
$tagData = @{}

# Get all markdown files
$files = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        # Match tags: # followed by letters/numbers/underscores/hyphens/slashes
        # But not markdown headings (##) or inside code blocks
        $matches = [regex]::Matches($content, '(?<!#)#([a-zA-Z][a-zA-Z0-9_/-]*)')
        foreach ($m in $matches) {
            $tag = $m.Groups[1].Value
            $relativePath = $file.FullName -replace [regex]::Escape($vaultPath + "\"), ""

            if (-not $tagData.ContainsKey($tag)) {
                $tagData[$tag] = @()
            }
            if ($relativePath -notin $tagData[$tag]) {
                $tagData[$tag] += $relativePath
            }
        }
    }
}

# Output as markdown table
Write-Output "| Tag | Files |"
Write-Output "|-----|-------|"

$tagData.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $tag = $_.Key
    $files = $_.Value -join "; "
    Write-Output "| #$tag | $files |"
}

Write-Output ""
Write-Output "Total unique tags: $($tagData.Count)"
