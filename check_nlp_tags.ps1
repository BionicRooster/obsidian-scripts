# List files and collect tags from NLP_Psy folder
$folder = "D:\Obsidian\Main\01\NLP_Psy"
$enc    = [System.Text.Encoding]::UTF8

Write-Host "=== Files in NLP_Psy ==="
Get-ChildItem $folder -Filter "*.md" | Select-Object -ExpandProperty Name | Sort-Object

Write-Host "`n=== Tags used in NLP_Psy notes ==="
$tags = @{}
Get-ChildItem $folder -Filter "*.md" | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }
    $matches = [regex]::Matches($text, '(?m)^\s+- (\S+)')
    foreach ($m in $matches) {
        $tag = $m.Groups[1].Value
        if ($tag -notmatch '^\[\[') { $tags[$tag] = $tags[$tag] + 1 }
    }
}
$tags.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 30 | Format-Table Name,Value -AutoSize
