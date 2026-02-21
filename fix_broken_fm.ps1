# Fix files where the tagging script broke frontmatter
# Pattern: ---\ntags block\n---\n--\noriginal frontmatter fields\ntags:\n  - clippings\n---
# Fix: merge into single frontmatter block with tags at end

$base = 'D:\Obsidian\Main\10 - Clippings'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Get-ChildItem "$base\*.md" | ForEach-Object {
    $filePath = $_.FullName
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

    # Remove BOM if present
    if ($content[0] -eq [char]0xFEFF) { $content = $content.Substring(1) }

    $lines = $content -split "`n"

    # Check for our broken pattern: line after closing --- is "--"
    # Find first --- (opening), then tags block, then --- (our closing), then -- (broken original opening)
    $foundIssue = $false
    $ourCloseIdx = -1

    if ($lines[0] -eq '---') {
        # Find our closing ---
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -eq '---') {
                $ourCloseIdx = $i
                break
            }
        }

        if ($ourCloseIdx -gt 0 -and ($ourCloseIdx + 1) -lt $lines.Count -and $lines[$ourCloseIdx + 1] -eq '--') {
            $foundIssue = $true
        }
    }

    if (-not $foundIssue) { return }

    # Extract our new tags (lines 1 to ourCloseIdx-1)
    $ourTagLines = @()
    for ($i = 1; $i -lt $ourCloseIdx; $i++) {
        $ourTagLines += $lines[$i]
    }

    # Find the original frontmatter close (next --- after the --)
    $origCloseIdx = -1
    for ($i = $ourCloseIdx + 2; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') {
            $origCloseIdx = $i
            break
        }
    }

    if ($origCloseIdx -lt 0) {
        Write-Host "SKIP (no orig close): $($_.Name)"
        return
    }

    # Collect original frontmatter fields (skip tags: and its entries)
    $origFields = @()
    $inOrigTags = $false
    for ($i = $ourCloseIdx + 2; $i -lt $origCloseIdx; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*tags:\s*$' -or $line -match '^\s*tags:\s*$') {
            $inOrigTags = $true
            continue
        }
        if ($inOrigTags) {
            if ($line -match '^\s+-\s') {
                continue
            } else {
                $inOrigTags = $false
            }
        }
        $origFields += $line
    }

    # Rebuild: --- \n original fields \n our tags \n --- \n rest of content
    $newLines = @('---')
    $newLines += $origFields
    $newLines += $ourTagLines
    $newLines += '---'

    # Add rest of content after original closing ---
    for ($i = $origCloseIdx + 1; $i -lt $lines.Count; $i++) {
        $newLines += $lines[$i]
    }

    $newContent = $newLines -join "`n"
    [System.IO.File]::WriteAllText($filePath, $newContent, $utf8NoBom)
    Write-Host "FIXED: $($_.Name)"
}

Write-Host "`nDone!"
