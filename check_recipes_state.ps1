# check_recipes_state.ps1
# Shows all [[D]] and broken-looking links in Recipes MOC

$file = "D:\Obsidian\Main\00 - Home Dashboard\MOC - Recipes.md"
$enc  = [System.Text.Encoding]::UTF8
$bytes  = [System.IO.File]::ReadAllBytes($file)
$hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
$text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

$lines = $text -split '\r?\n'
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '\[\[D\]\]' -or $line -match '\[\[[^\]]{1,20}\]\]') {
        Write-Host "Line $($i+1): $line"
    }
}
