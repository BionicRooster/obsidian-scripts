# Final cleanup pass: remove remaining false positives by exact name match

$path = 'C:\Users\awt\Sync\Obsidian\People Index.md'
$lines = [System.Collections.Generic.List[string]]([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) -split "`n")

$removeNames = [System.Collections.Generic.HashSet[string]]::new()
'Fox, Melinda Coplin','Green, Going','Honor','Instructables','Lifewire',
'Man, Lazy','MarkusPfundstein','Sam','SciTechDaily','Sketchplanations',
'Tolocka, Profe','User, Unknown','Venice.ai','Voice, Legal' | ForEach-Object {
    [void]$removeNames.Add($_)
}

$removed = 0
$i = 0
while ($i -lt $lines.Count) {
    if ($lines[$i] -match '^### (.+)$') {
        $name = $matches[1].Trim()
        if ($removeNames.Contains($name)) {
            $end = $i + 1
            while ($end -lt $lines.Count -and $lines[$end] -notmatch '^### |^## |^---') { $end++ }
            $lines.RemoveRange($i, $end - $i)
            Write-Host "REMOVED: $name"
            $removed++
            continue
        }
    }
    $i++
}

Write-Host "Removed: $removed  Remaining: $(($lines | Where-Object { $_ -match '^### ' }).Count)"
[System.IO.File]::WriteAllText($path, ($lines -join "`n"), [System.Text.Encoding]::UTF8)
