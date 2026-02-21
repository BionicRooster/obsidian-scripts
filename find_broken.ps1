$base = 'D:\Obsidian\Main\10 - Clippings'
Get-ChildItem "$base\*.md" | ForEach-Object {
    $lines = [System.IO.File]::ReadAllLines($_.FullName, [System.Text.Encoding]::UTF8)
    for ($i = 0; $i -lt $lines.Count - 1; $i++) {
        if ($lines[$i] -eq '---' -and $lines[$i+1] -eq '--') {
            Write-Host "$($_.Name) : line $($i+2) is '--'"
            break
        }
    }
}
