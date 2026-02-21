$filePath = "D:\Obsidian\Main\20 - Permanent Notes\The Living Descendants of British Royal Blood Talbot, Field.md"
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
$size = $content.Length
$kb = [math]::Round($size / 1024, 1)
Write-Host "Final file size: $size characters (~$kb KB)"
Write-Host "Original was ~244 KB, reduced by ~88%"
Write-Host ""
Write-Host "--- FIRST 2000 CHARACTERS ---"
Write-Host $content.Substring(0, [Math]::Min(2000, $size))
