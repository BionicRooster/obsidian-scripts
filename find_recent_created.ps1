# Find markdown files created in the last 2 days that need classification
# Reports files missing nav property (already classified files are skipped)
$vault = "D:\Obsidian\Main"
$cutoff = (Get-Date).AddDays(-2)

# Directories to skip
$excludeDirs = @('People', '00 - Journal', 'Journals', '05 - Templates', 'Templates',
                  '.resources', 'images', 'Attachments', '00 - Images', '00 - Home Dashboard',
                  '.obsidian', '.trash', '.smart-env')

$files = Get-ChildItem -Path $vault -Filter "*.md" -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        $_.CreationTime -ge $cutoff -and
        $_.Name -ne "Orphan Files.md" -and
        $_.Name -ne "Empty Notes.md" -and
        $_.Name -ne "Truncated Filenames.md"
    } |
    Where-Object {
        $dominated = $false
        foreach ($ex in $excludeDirs) {
            if ($_.FullName -match [regex]::Escape("\$ex\")) { $dominated = $true; break }
        }
        -not $dominated
    }

$needsWork = 0
$alreadyDone = 0

foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    $hasNav = $false
    if ($content -match '(?m)^nav:') { $hasNav = $true }

    $relPath = $f.FullName.Replace($vault + '\', '')

    if ($hasNav) {
        $alreadyDone++
    } else {
        $needsWork++
        Write-Output "NEEDS_WORK|$($f.CreationTime.ToString('yyyy-MM-dd HH:mm'))|$relPath"
    }
}

Write-Host "`nSummary: $alreadyDone already classified, $needsWork need work" -ForegroundColor Cyan
