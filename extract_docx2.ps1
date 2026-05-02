param([string]$DocPath, [string]$OutPath)

# DOCX is a ZIP file - extract word/document.xml and strip tags
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::OpenRead($DocPath)
$entry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
$reader = New-Object System.IO.StreamReader($entry.Open())
$xml = $reader.ReadToEnd()
$reader.Close()
$zip.Dispose()

# Remove XML tags
$text = [System.Text.RegularExpressions.Regex]::Replace($xml, '<[^>]+>', ' ')
# Collapse whitespace
$text = [System.Text.RegularExpressions.Regex]::Replace($text, '\s+', ' ').Trim()

[System.IO.File]::WriteAllText($OutPath, $text, [System.Text.Encoding]::UTF8)
Write-Host "Done: $OutPath"
