$file = 'C:\Users\awt\cleanup_misplaced_links.ps1'
$bytes = [System.IO.File]::ReadAllBytes($file)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
$lines = $text -split '\n'
$l = $lines[76]   # Line 77 (0-indexed = 76)
Write-Host "Line 77 full hex dump:"
for ($i = 0; $i -lt $l.Length; $i++) {
    $code = [int]$l[$i]
    if ($code -ne 0x0D) {
        Write-Host "  pos=$i  hex=0x$($code.ToString('X4'))  char=[$($l[$i])]"
    }
}
