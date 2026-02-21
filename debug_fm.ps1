$filePath = 'D:\Obsidian\Main\10 - Clippings\21 Rules That Men Have. Number 7 Is So True.md'
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
if ($content[0] -eq [char]0xFEFF) { $content = $content.Substring(1) }
$lines = $content -split "`n"
for ($i = 0; $i -lt [Math]::Min(20, $lines.Count); $i++) {
    $line = $lines[$i]
    $trimmed = $line.TrimEnd("`r")
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($trimmed)
    $hex = ($bytes | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
    Write-Host "L$i [$trimmed] hex=[$hex]"
}
