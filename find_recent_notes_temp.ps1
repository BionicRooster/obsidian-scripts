Get-ChildItem -Path 'D:\Obsidian\Main' -Recurse -Filter '*.md' |
Where-Object {
    $_.CreationTime -ge (Get-Date).AddDays(-2) -and
    $_.FullName -notmatch '\\People\\' -and
    $_.FullName -notmatch '\\Journals\\' -and
    $_.FullName -notmatch '\\00 - Journal\\' -and
    $_.FullName -notmatch '\\Templates\\' -and
    $_.FullName -notmatch '\\05 - Templates\\' -and
    $_.FullName -notmatch '\.resources' -and
    $_.FullName -notmatch '\\images\\' -and
    $_.FullName -notmatch '\\Attachments\\' -and
    $_.FullName -notmatch '\\00 - Images\\' -and
    $_.FullName -notmatch '\\00 - Home Dashboard\\' -and
    $_.Name -ne 'Orphan Files.md'
} |
Select-Object FullName, CreationTime |
Sort-Object CreationTime -Descending |
Format-Table -AutoSize -Wrap
