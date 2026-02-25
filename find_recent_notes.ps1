Get-ChildItem -Path 'D:\Obsidian\Main' -Recurse -File -Filter '*.md' | Where-Object {
    $_.CreationTime -ge (Get-Date).AddDays(-2) -and
    $_.FullName -notlike '*\01\*' -and
    $_.FullName -notlike '*\People\*' -and
    $_.FullName -notlike '*\Journals\*' -and
    $_.FullName -notlike '*\00 - Journal\*' -and
    $_.FullName -notlike '*.resources*' -and
    $_.FullName -notlike '*\Attachments\*' -and
    $_.FullName -notlike '*\00 - Images\*' -and
    $_.FullName -notlike '*\00 - Home Dashboard\*' -and
    $_.Name -ne 'Orphan Files.md'
} | Select-Object FullName, CreationTime | Sort-Object CreationTime -Descending | Format-Table -AutoSize -Wrap
