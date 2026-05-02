# Find notes created in the last 2 days, excluding system folders
$cutoff = (Get-Date).AddDays(-2)
$results = Get-ChildItem -Path 'D:\Obsidian\Main' -Recurse -Filter '*.md' | Where-Object {
    $_.CreationTime -ge $cutoff -and
    $_.FullName -notmatch 'People' -and
    $_.FullName -notmatch 'Journals' -and
    $_.FullName -notmatch 'Templates' -and
    $_.FullName -notmatch 'resources' -and
    $_.FullName -notmatch 'Attachments' -and
    $_.FullName -notmatch '00 - Images' -and
    $_.FullName -notmatch '00 - Home Dashboard' -and
    $_.Name -ne 'Orphan Files.md'
}
foreach ($f in $results | Sort-Object CreationTime) {
    Write-Output "$($f.CreationTime.ToString('yyyy-MM-dd HH:mm'))  $($f.FullName)"
}
