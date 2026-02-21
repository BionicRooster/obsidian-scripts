# Extract the byte pattern for the checkmark mojibake
$content = Get-Content -Path 'D:\Obsidian\Main\Dynamic ToDo.md' -Raw -Encoding UTF8
$match = [regex]::Match($content, '#\s*(.{1,10})\s*Dynamic')
if ($match.Success) {
    $captured = $match.Groups[1].Value.Trim()
    Write-Host "Captured text: [$captured]"
    Write-Host "Length: $($captured.Length) characters"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($captured)
    Write-Host "Byte sequence:"
    $hexBytes = $bytes | ForEach-Object { '0x{0:X2}' -f $_ }
    Write-Host ($hexBytes -join ', ')
}
