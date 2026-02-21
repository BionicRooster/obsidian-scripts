$cutoff = (Get-Date).AddDays(-2)
$vaultPath = 'D:\Obsidian\Main'

$excludePatterns = @(
    '\\\.obsidian\\',
    '\\\.smart-env\\',
    '\\People\\',
    '\\Journals\\',
    '\\00 - Journal\\',
    '\\Templates\\',
    '\\\.resources',
    '\\images\\',
    '\\Attachments\\',
    '\\00 - Images\\',
    '\\00 - Home Dashboard\\'
)

$results = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse | Where-Object {
    $file = $_
    if ($file.CreationTime -le $cutoff) { return $false }
    if ($file.BaseName -eq 'Orphan Files') { return $false }

    foreach ($pattern in $excludePatterns) {
        if ($file.FullName -match $pattern) { return $false }
    }
    return $true
} | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    $hasNav = $content -match '(?m)^nav:'
    $relPath = $_.FullName.Replace($vaultPath + '\', '')

    "$($_.CreationTime.ToString('yyyy-MM-dd HH:mm'))|$hasNav|$relPath"
}

Write-Host "Found $($results.Count) files"
Write-Host "---"
foreach ($r in ($results | Sort-Object -Descending)) {
    Write-Host $r
}
