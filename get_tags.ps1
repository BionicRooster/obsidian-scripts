$tags = @{}
Get-ChildItem 'D:\Obsidian\Main' -Recurse -Filter '*.md' | ForEach-Object {
    $c = Get-Content $_.FullName -Raw -Encoding UTF8
    if ($c -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $yaml = $Matches[1]
        foreach ($line in ($yaml -split '\r?\n')) {
            if ($line -match '^\s*-\s*(.+)$') {
                $tag = $Matches[1].Trim().Trim('"').Trim("'")
                if ($tag -and $tag.Length -gt 0) {
                    $tags[$tag] = $true
                }
            }
        }
    }
}
$tags.Keys | Sort-Object | ForEach-Object { Write-Output $_ }
