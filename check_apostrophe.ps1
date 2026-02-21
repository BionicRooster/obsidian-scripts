# Check the apostrophe character encoding
$filePath = "D:\Obsidian\Main\11 - Evernote\BionicR\After 36 Years, Arch.md"
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$str = [System.Text.Encoding]::UTF8.GetString($bytes)

# Find the Wright_Brothers text
$idx = $str.IndexOf("Wright_Brothers")
if ($idx -gt 0) {
    $chunk = $str.Substring($idx, 50)
    Write-Host "Found at index: $idx"
    Write-Host "Chunk: $chunk"
    Write-Host ""
    Write-Host "Character analysis:"
    for ($i = 0; $i -lt $chunk.Length; $i++) {
        $c = $chunk[$i]
        $code = [int]$c
        Write-Host ("Position {0}: Char='{1}' Unicode=U+{2:X4} Decimal={3}" -f $i, $c, $code, $code)
    }
}
