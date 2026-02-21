# Remove HTML duplicate section from Dal.md
$file = 'D:\Obsidian\Main\01\Recipes\Dal.md'
$content = Get-Content $file -Encoding UTF8

# Find the first line containing "<head>" - that's where HTML starts
$htmlStart = -1
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match '^<head>') {
        $htmlStart = $i
        break
    }
}

if ($htmlStart -lt 0) {
    Write-Host "No <head> tag found"
    exit
}

Write-Host "HTML starts at line index: $htmlStart (line $($htmlStart+1))"
Write-Host "Total lines: $($content.Length)"

# Keep only the content before <head>, trimming trailing blank lines
$lastGoodLine = $htmlStart - 1
while ($lastGoodLine -ge 0 -and [string]::IsNullOrWhiteSpace($content[$lastGoodLine])) {
    $lastGoodLine--
}

Write-Host "Last content line index: $lastGoodLine (line $($lastGoodLine+1))"
Write-Host "Content: $($content[$lastGoodLine])"

# Keep only the clean content
$cleanContent = $content[0..$lastGoodLine] -join "`n"
$cleanContent += "`n"
[System.IO.File]::WriteAllText($file, $cleanContent, [System.Text.UTF8Encoding]::new($false))
Write-Host "File truncated to $($lastGoodLine+1) lines"
