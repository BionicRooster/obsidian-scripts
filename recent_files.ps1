$cutoff = (Get-Date).AddDays(-2)
$files = Get-ChildItem -Path 'D:\Obsidian\Main' -Recurse -Filter '*.md' |
    Where-Object {
        $_.CreationTime -gt $cutoff -and
        $_.FullName -notmatch '\\People\\' -and
        $_.FullName -notmatch '\\00 - Journal' -and
        $_.FullName -notmatch '\\Templates' -and
        $_.FullName -notmatch '\.resources' -and
        $_.FullName -notmatch '\\00 - Images' -and
        $_.FullName -notmatch '\\Attachments' -and
        $_.FullName -notmatch '00 - Home Dashboard' -and
        $_.FullName -notmatch 'Orphan Files\.md'
    }
foreach ($f in $files) {
    $rel = $f.FullName.Replace('D:\Obsidian\Main\', '')
    $dt  = $f.CreationTime.ToString('yyyy-MM-dd HH:mm')
    Write-Output "$dt | $rel"
}
Write-Output "Total: $($files.Count)"
