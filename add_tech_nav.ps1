# Add nav to Technology files missing it
$dir = 'C:\Users\awt\Sync\Obsidian\01\Technology'
$nav = 'nav: "[[MOC - Technology & Computers]]"'
$updated = 0
$skipped = 0

Get-ChildItem $dir -Filter '*.md' | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match '^---' -and $content -notmatch 'nav:') {
        # Insert nav before closing --- of frontmatter
        $lines = $content -split "`n"
        $closingIdx = -1
        $inFM = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq '---') {
                if (-not $inFM) { $inFM = $true }
                else { $closingIdx = $i; break }
            }
        }
        if ($closingIdx -gt 0) {
            $newLines = $lines[0..($closingIdx-1)] + $nav + $lines[$closingIdx..($lines.Count-1)]
            $newContent = $newLines -join "`n"
            [System.IO.File]::WriteAllText($_.FullName, $newContent, [System.Text.Encoding]::UTF8)
            $updated++
        }
    } else {
        $skipped++
    }
}
Write-Output "Updated: $updated files | Skipped (already has nav or no frontmatter): $skipped files"
