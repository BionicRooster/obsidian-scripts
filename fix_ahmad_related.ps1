# Fix Tablet of Ahmad - replace Related Notes section
$dir = Get-ChildItem 'D:\Obsidian\Main\01\Bah*' -Directory | Select-Object -First 1
$ahmadFile = Get-ChildItem $dir.FullName | Where-Object { $_.Name -like 'The Tablet of Ahmad.md' } | Select-Object -First 1

$content = Get-Content $ahmadFile.FullName -Encoding UTF8 -Raw

# Build the verified related notes
$b = [char]0x00E1  # á
$i = [char]0x00ED  # í
$apostrophe = "'"

$cleanRelated = @"

---
## Related Notes
- [[A Flame of Fire The Story of the Tablet of Ahmad]]
- [[Bah$($b)${apostrophe}u${apostrophe}ll$($b)h]]
- [[$($apostrophe)Abdu${apostrophe}l-Bah$($b)]]
- [[The Bab]]
"@

# Remove the existing ## Related Notes section through end of file
$content = $content -replace "(?s)\r?\n## Related Notes.*$", $cleanRelated

[System.IO.File]::WriteAllText($ahmadFile.FullName, $content, [System.Text.Encoding]::UTF8)
Write-Host "Fixed Ahmad Related Notes: $($ahmadFile.Name)"
