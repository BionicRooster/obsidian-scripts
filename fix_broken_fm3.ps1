# Fix files where tagging script broke frontmatter
$base = 'D:\Obsidian\Main\10 - Clippings'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Get-ChildItem "$base\*.md" | ForEach-Object {
    $filePath = $_.FullName
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    if ($content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) { $content = $content.Substring(1) }

    $lines = $content -split "`n"
    # Trim CR from all lines for comparison
    $trimLines = $lines | ForEach-Object { $_.TrimEnd("`r") }

    if ($trimLines[0] -ne '---') { return }

    # Find our closing ---
    $ourCloseIdx = -1
    for ($i = 1; $i -lt $trimLines.Count; $i++) {
        if ($trimLines[$i] -eq '---') { $ourCloseIdx = $i; break }
    }
    if ($ourCloseIdx -lt 0) { return }
    if (($ourCloseIdx + 1) -ge $trimLines.Count) { return }
    if ($trimLines[$ourCloseIdx + 1] -ne '--') { return }

    # Find original closing ---
    $origCloseIdx = -1
    for ($i = $ourCloseIdx + 2; $i -lt $trimLines.Count; $i++) {
        if ($trimLines[$i] -eq '---') { $origCloseIdx = $i; break }
    }
    if ($origCloseIdx -lt 0) {
        Write-Host "SKIP (no orig close): $($_.Name)"
        return
    }

    # Extract our tags (between line 1 and ourCloseIdx)
    $ourTagLines = @()
    for ($i = 1; $i -lt $ourCloseIdx; $i++) {
        $ourTagLines += $trimLines[$i]
    }

    # Collect original frontmatter fields, skip tags blocks
    $origFields = @()
    $inOrigTags = $false
    for ($i = $ourCloseIdx + 2; $i -lt $origCloseIdx; $i++) {
        $line = $trimLines[$i]
        if ($line -match '^tags:') {
            $inOrigTags = $true
            continue
        }
        if ($inOrigTags -and $line -match '^\s+-\s') {
            continue
        }
        $inOrigTags = $false
        $origFields += $line
    }

    # Rebuild: --- \n original fields \n our tags \n --- \n rest
    $newLines = @('---')
    $newLines += $origFields
    $newLines += $ourTagLines
    $newLines += '---'
    for ($i = $origCloseIdx + 1; $i -lt $trimLines.Count; $i++) {
        $newLines += $trimLines[$i]
    }

    $newContent = $newLines -join "`n"
    [System.IO.File]::WriteAllText($filePath, $newContent, $utf8NoBom)
    Write-Host "FIXED: $($_.Name)"
}

Write-Host "`nDone!"
