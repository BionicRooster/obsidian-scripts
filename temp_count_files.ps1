# Count files per 01 subfolder
Get-ChildItem 'D:\Obsidian\Main\01' -Directory | ForEach-Object {
    $count = (Get-ChildItem $_.FullName -Filter '*.md' -Recurse).Count
    Write-Output "$($_.Name): $count"
}
