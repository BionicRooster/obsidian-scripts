$file = 'C:\Users\awt\obsidian_maintenance.ps1'
$text = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
$lines = $text -split '\r?\n'
for ($i=0; $i -lt $lines.Count; $i++) {
    $L = $lines[$i]
    # Only flag non-ASCII in non-comment, non-regex, non-single-quoted lines
    if ($L -match '[^\x00-\x7F]' -and
        $L -notmatch "^\s*#" -and
        $L -notmatch "^\s*'" -and
        $L -notmatch '^\s*\[regex\]') {
        Write-Host "Line $($i+1): $($L.Substring(0,[Math]::Min(140,$L.Length)))"
    }
}
