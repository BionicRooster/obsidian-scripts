$path = 'C:\Users\awt\Sync\Obsidian\People Index.md'
$lines = [System.Collections.Generic.List[string]]([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) -split "`r?`n")
$i = 0
while ($i -lt $lines.Count) {
    if ($lines[$i].Trim() -eq '### OC') {
        $end = $i + 1
        while ($end -lt $lines.Count -and $lines[$end] -notmatch '^### |^## |^---') { $end++ }
        $lines.RemoveRange($i, $end - $i)
        Write-Host "REMOVED: OC"
        continue
    }
    $i++
}
Write-Host "Final: $(($lines | Where-Object { $_ -match '^### ' }).Count)"
[System.IO.File]::WriteAllText($path, ($lines -join "`n"), [System.Text.Encoding]::UTF8)
