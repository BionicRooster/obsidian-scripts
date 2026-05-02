# Find notes created in the last 2 days, excluding system folders
$cutoff = (Get-Date).AddDays(-2)
$files = Get-ChildItem -Path 'D:\Obsidian\Main' -Recurse -Filter '*.md' | Where-Object {
    $_.CreationTime -gt $cutoff -and
    $_.Name -ne 'Orphan Files.md' -and
    $_.FullName -notlike '*\People\*' -and
    $_.FullName -notlike '*\Journals\*' -and
    $_.FullName -notlike '*\00 - Journal\*' -and
    $_.FullName -notlike '*\Templates\*' -and
    $_.FullName -notlike '*\.resources*' -and
    $_.FullName -notlike '*\images\*' -and
    $_.FullName -notlike '*\Attachments\*' -and
    $_.FullName -notlike '*\00 - Images\*' -and
    $_.FullName -notlike '*\00 - Home Dashboard\*'
}

$files | Sort-Object CreationTime -Descending | ForEach-Object {
    "$($_.CreationTime.ToString('yyyy-MM-dd HH:mm')) | $($_.FullName)"
}
