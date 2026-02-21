# Clean FW_ Kick Off 28-Day Challenge file
# Remove MIME headers, HTML duplicate, and base64 image attachment
$file = 'D:\Obsidian\Main\01\Recipes\FW_ Kick Off 28-Day Challenge Info with Whole Foods Market.md'
$content = Get-Content $file -Encoding UTF8

# Keep frontmatter (lines 1-18) = indices 0-17
# Skip MIME headers (lines 19-26) = indices 18-25
# Keep text content (lines 27-148) = indices 26-147
# Remove everything from line 149 onward (blank lines, HTML, base64)

# Find the line with "You can unsubscribe" as end of clean content
$lastGoodLine = -1
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match 'You can unsubscribe') {
        $lastGoodLine = $i
        break
    }
}

Write-Host "Last good content line: $($lastGoodLine + 1)"
Write-Host "Content: $($content[$lastGoodLine])"

# Build clean content: frontmatter + text content (skip MIME headers)
$frontmatter = $content[0..17]  # Lines 1-18

# Find where MIME text content starts (after Content-Transfer-Encoding line)
$textStart = -1
for ($i = 18; $i -lt 30; $i++) {
    if ([string]::IsNullOrWhiteSpace($content[$i]) -and $textStart -eq -1 -and $i -gt 25) {
        $textStart = $i + 1
        break
    }
}

# Actually, just skip lines 18-25 (MIME headers) and start from line 26 (index 25+1=26)
# But check - line 27 is blank, line 28 starts "You are receiving..."
$textContent = $content[26..$lastGoodLine]

Write-Host "Text content starts at line: 27 (index 26)"
Write-Host "First text line: $($content[26])"
Write-Host "Text content lines: $($textContent.Length)"

$cleanLines = $frontmatter + $textContent
$cleanContent = $cleanLines -join "`n"
$cleanContent += "`n"
[System.IO.File]::WriteAllText($file, $cleanContent, [System.Text.UTF8Encoding]::new($false))
Write-Host "File cleaned. Total lines: $($cleanLines.Length)"
