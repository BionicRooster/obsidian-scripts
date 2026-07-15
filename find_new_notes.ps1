$cutoff = (Get-Date).AddDays(-2)
$exclude = @('00 - Images','Templates','\.resources','\\People\\','\\Journals\\','00 - Journal','00 - Home Dashboard','\.trash','09 - Kindle Clippings')

Get-ChildItem -Path 'C:\Users\awt\Sync\Obsidian' -Recurse -Filter '*.md' | Where-Object {
    $f = $_.FullName
    $_.CreationTime -gt $cutoff -and
    -not ($exclude | Where-Object { $f -match $_ })
} | Select-Object FullName, CreationTime | Sort-Object CreationTime
