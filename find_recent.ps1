$cutoff = (Get-Date).AddDays(-2)
$excludes = @('People','Journals','00 - Journal','Templates','.resources','images','Attachments','00 - Images','00 - Home Dashboard')

Get-ChildItem -Path 'D:\Obsidian\Main' -Recurse -Filter '*.md' |
Where-Object {
    $f = $_.FullName
    $_.CreationTime -ge $cutoff -and
    $_.Name -ne 'Orphan Files.md' -and
    -not ($excludes | Where-Object { $f -like "*\$_\*" })
} |
Select-Object FullName, CreationTime |
Sort-Object CreationTime -Descending |
ForEach-Object { "$($_.CreationTime.ToString('yyyy-MM-dd HH:mm'))  $($_.FullName)" }
