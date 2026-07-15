Get-ChildItem 'C:\Users\awt\Sync\Obsidian\10 - Clippings\' |
    Where-Object { $_.Name -match 'flood|cataclysmic' } |
    Select-Object -ExpandProperty FullName
