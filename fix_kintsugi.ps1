# Read the file, fix content, and move to correct folder
$srcFile = Get-ChildItem 'D:\Obsidian\Main\01\NLP\' | Where-Object { $_.Name -match 'Kintsugi' }
$content = Get-Content -Path $srcFile.FullName -Encoding UTF8 -Raw

# Fix soft-hyphen word-breaks: "Japan-ese" -> "Japanese", "kintsu-gi" -> "kintsugi", etc.
# Pattern: word-char, hyphen, word-char where hyphen is a line-break artifact
# These appear mid-word as "xxx-yyy" where neither part is a real word
$content = $content -replace '(\w)-\n(\w)', '$1$2'         # line-break hyphens
$content = $content -replace '(\w)-(\w)', { param($m)
    # Rejoin hyphenated fragments (all lowercase mid-word splits)
    $full = $m.Groups[1].Value + $m.Groups[2].Value
    return $full
}

# Actually, simpler approach: just remove all mid-word hyphens in the body
# The hyphens in the text are ALL soft-hyphen word-break artifacts (e.g. "Japan-ese", "Dis-cussing")
# Real hyphens: "half-millennium", "pop-cultural", "long-form" - we want to keep these
# Strategy: remove hyphens that are surrounded by lowercase letters (word-break artifacts)
$content = $content -replace '(?<=[a-z])-(?=[a-z])', ''

# Fix YAML nav and tags
$content = $content -replace 'nav: "\[\[MOC - NLP & Psychology\]\]"', 'nav: "[[01/Japan]] | [[MOC - Japan & Japanese Culture]]"'
$content = $content -replace "tags:\r?\n  - kintsugi\r?\n  - Japan\r?\n  - clippings", "tags:`n  - Kintsugi`n  - Japan`n  - JapaneseCulture`n  - Clippings`n  - TrevorNoah"

# Fix nav breadcrumb in body (first line after YAML)
$content = $content -replace 'in \| January 9th, 2026 \[Leave a Comment\]\([^)]+\)\r?\n', ''

# Remove social sharing lines (Bluesky, Facebook, etc.)
$content = $content -replace '\[Bluesky\][^\n]+\[Share\][^\n]+\n?', ''
$content = $content -replace '\[Bluesky\][^\n]+\n?', ''

# Remove the "Support Open Culture" donation block
$content = $content -replace '\*\*Sup-port Open Cul-ture\*\*.*', ''

# Remove duplicate share button block at end
# Already handled above

# Add proper nav breadcrumb header after YAML
$content = $content -replace '(---\n)(in \|.*\n)?', "`$1`n[[01/Japan]] | [[MOC - Japan & Japanese Culture]]`n`n"

# Write cleaned content to new location
$dstPath = 'D:\Obsidian\Main\01\Japan\Trevor Noah Explains How Kintsugi Helped Him Overcome Life''s Tragedies.md'
[System.IO.File]::WriteAllText($dstPath, $content, [System.Text.Encoding]::UTF8)

# Remove original
Remove-Item $srcFile.FullName

Write-Host "Moved and cleaned: $($srcFile.Name)"
Write-Host "Destination: $dstPath"
