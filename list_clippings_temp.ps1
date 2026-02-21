Get-ChildItem 'D:\Obsidian\Main\10 - Clippings\' |
    Where-Object { $_.Name -match 'flood|cataclysmic' } |
    Select-Object -ExpandProperty FullName
