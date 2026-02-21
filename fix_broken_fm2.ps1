# Fix files where tagging script broke frontmatter
# Pattern: ---\nour tags\n---\n--\ntags:\n  - "clippings"\n...original fields...\n---
# Also: ---\nour tags\n---\n--\noriginal fields...\ntags:\n  - "clippings"\n---
# Fix: merge into single frontmatter with all original fields + our tags (clippings last)

$base = 'D:\Obsidian\Main\10 - Clippings'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Get-ChildItem "$base\*.md" | ForEach-Object {
    $filePath = $_.FullName
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    if ($content[0] -eq [char]0xFEFF) { $content = $content.Substring(1) }

    $lines = $content -split "`n"

    # Find pattern: opening ---, then closing ---, then --
    if ($lines[0] -ne '---') { return }

    $ourCloseIdx = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') { $ourCloseIdx = $i; break }
    }

    if ($ourCloseIdx -lt 0) { return }
    if (($ourCloseIdx + 1) -ge $lines.Count) { return }
    if ($lines[$ourCloseIdx + 1] -ne '--') { return }

    # Extract our new tags (between opening --- and closing ---)
    $ourTagLines = @()
    for ($i = 1; $i -lt $ourCloseIdx; $i++) {
        $ourTagLines += $lines[$i]
    }

    # Find the original closing --- (after the --)
    $origCloseIdx = -1
    for ($i = $ourCloseIdx + 2; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') { $origCloseIdx = $i; break }
    }

    if ($origCloseIdx -lt 0) {
        Write-Host "SKIP (no orig close): $($_.Name)"
        return
    }

    # Collect original frontmatter fields (skip tags: and its entries, skip empty -- line)
    $origFields = @()
    $inOrigTags = $false
    for ($i = $ourCloseIdx + 2; $i -lt $origCloseIdx; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*tags:\s*$') {
            $inOrigTags = $true
            continue
        }
        if ($inOrigTags) {
            if ($line -match '^\s+-\s') { continue }
            else { $inOrigTags = $false }
        }
        $origFields += $line
    }

    # Rebuild
    $newLines = @('---')
    $newLines += $origFields
    $newLines += $ourTagLines
    $newLines += '---'
    for ($i = $origCloseIdx + 1; $i -lt $lines.Count; $i++) {
        $newLines += $lines[$i]
    }

    $newContent = $newLines -join "`n"
    [System.IO.File]::WriteAllText($filePath, $newContent, $utf8NoBom)
    Write-Host "FIXED: $($_.Name)"
}

Write-Host "`nDone!"
