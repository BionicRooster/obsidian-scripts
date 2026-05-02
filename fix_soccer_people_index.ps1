# fix_soccer_people_index.ps1
# Fixes the 3 missed insertions from the previous run

$path = "D:\Obsidian\Main\People Index.md"
$raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Normalize line endings to LF for consistent matching, then restore later
$crlf = $raw.Contains("`r`n")
$content = $raw -replace "`r`n", "`n"

$sje  = "[[2026-04-22 - San Jose Earthquakes vs Austin FC Box Score]]"
$tor  = "[[2026-04-18 - Toronto FC vs Austin FC Box Score]]"
$lag  = "[[2026-04-11 - Austin FC vs LA Galaxy Box Score]]"
$lou  = "[[2026-04-14 - Louisville City FC vs Austin FC Box Score]]"

# 1. Desler: after Desjardins block, before Devotionals
$desler = "### Desler, Mikkel`n- $lag`n- $lou`n- $tor`n- $sje"
$searchD = "- [[12 Ways to Get Smarter in One Infographic]]`n### Devotionals"
if ($content.IndexOf($searchD) -ge 0) {
    $content = $content.Replace($searchD, "- [[12 Ways to Get Smarter in One Infographic]]`n" + $desler + "`n### Devotionals")
    Write-Host "Inserted Desler"
} else { Write-Warning "Still could not find Desler insertion point" }

# 2. Farkarlun: after Fargo block (last link is Truncated Filenames), before FC, Austin
$farkarlun = "### Farkarlun, Jimmy`n- Austin FC 2026 roster (option not exercised)"
$searchF = "- [[Truncated Filenames]]`n### FC, Austin"
if ($content.IndexOf($searchF) -ge 0) {
    $content = $content.Replace($searchF, "- [[Truncated Filenames]]`n" + $farkarlun + "`n### FC, Austin")
    Write-Host "Inserted Farkarlun"
} else { Write-Warning "Still could not find Farkarlun insertion point" }

# 3. Wolff Owen: after Wolff Joseph block, before Wolfram
$wolff = "### Wolff, Owen`n- Austin FC 2026 roster (out injured - sports hernia)"
$searchW = "- [[19th Century Religious Movements]]`n### Wolfram"
if ($content.IndexOf($searchW) -ge 0) {
    $content = $content.Replace($searchW, "- [[19th Century Religious Movements]]`n" + $wolff + "`n### Wolfram")
    Write-Host "Inserted Wolff Owen"
} else { Write-Warning "Still could not find Wolff Owen insertion point" }

# Restore CRLF if needed
if ($crlf) { $content = $content -replace "`n", "`r`n" }

[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
Write-Host "Done."
