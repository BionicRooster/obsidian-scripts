# find_unclassified.ps1
# Find recently created vault files that don't yet have a nav: property (unclassified)

$vaultPath = 'D:\Obsidian\Main'
$days      = 7
$cutoff    = (Get-Date).AddDays(-$days)

$results = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse |
    Where-Object { $_.CreationTime -ge $cutoff } |
    Where-Object {
        $rel = $_.FullName.Replace($vaultPath + '\', '')
        $rel -notmatch '\\People\\'              -and
        $rel -notmatch '\\Journals?\\'           -and
        $rel -notmatch '\\00 - Journal\\'        -and
        $rel -notmatch '\\05 - Templates\\'      -and
        $rel -notmatch '\\Attachments\\'         -and
        $rel -notmatch '\.resources\\'             -and
        $rel -notmatch '\\00 - Images\\'         -and
        $rel -notmatch '\\00 - Home Dashboard\\' -and
        $rel -notmatch '\\09 - Kindle Clippings\\' -and
        $_.Name -notlike 'MOC - *.md'               -and
        $_.Name -ne 'Orphan Files.md'               -and
        $_.Name -ne 'Master MOC Index.md'           -and
        $_.Name -ne 'To-Do List.md'
    } |
    Where-Object {
        $content = Get-Content $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        $content -notmatch '(?m)^nav:'
    } |
    ForEach-Object {
        $rel    = $_.FullName.Replace($vaultPath + '\', '')
        $inRoot = $rel -notmatch '\'
        [PSCustomObject]@{
            Name     = $_.BaseName
            RelPath  = $rel
            InRoot   = $inRoot
            Created  = $_.CreationTime
            FullPath = $_.FullName
        }
    } |
    Sort-Object Created -Descending

if ($results.Count -eq 0) {
    Write-Host "No unclassified files found in the last $days days." -ForegroundColor Green
} else {
    Write-Host "Found $($results.Count) unclassified file(s) created in the last $days days:" -ForegroundColor Cyan
    $results | ForEach-Object {
        $rootTag = if ($_.InRoot) { ' [ROOT - no move]' } else { '' }
        Write-Host "  $($_.Created.ToString('yyyy-MM-dd'))  $($_.RelPath)$rootTag"
    }
}
