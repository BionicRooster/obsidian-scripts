# check_calendar_fm.ps1
# Check which Personal Calendar Summary files have frontmatter

$vaultRoot = 'C:\Users\awt\Sync\Obsidian'

2010..2025 | ForEach-Object {
    $year = $_
    $path = Join-Path $vaultRoot "$year Personal Calendar Summary.md"
    if (Test-Path $path) {
        $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        $hasFm = $text.TrimStart().StartsWith('---')
        Write-Output "$year : frontmatter=$hasFm"
    } else {
        Write-Output "$year : MISSING"
    }
}
