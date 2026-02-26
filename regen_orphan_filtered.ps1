# regen_orphan_filtered.ps1 - Filter orphan_files.txt into orphan_filtered.txt
# Excludes journals, templates, images, MOC files, Kindle clippings, system files

$input  = 'C:\Users\awt\orphan_files.txt'   # Raw orphan list from find_orphans.ps1
$output = 'C:\Users\awt\orphan_filtered.txt' # Filtered list for link_orphans.ps1

$lines = Get-Content $input -Encoding UTF8

$filtered = $lines | Where-Object {
    $line = $_
    $line -like '*.md' -and
    $line -notmatch '\\0[0-9]? - Journal' -and
    $line -notmatch '\\05 - Templates' -and
    $line -notmatch '\\00 - Images' -and
    $line -notmatch '\\Attachments' -and
    $line -notmatch '\.resources' -and
    $line -notmatch '\\MOC - ' -and
    $line -notmatch '\\09 - Kindle Clippings' -and
    $line -notmatch 'Orphan Files\.md' -and
    $line -notmatch 'Empty Notes\.md'
}

$filtered | Set-Content -Path $output -Encoding UTF8
Write-Host "Filtered: $($filtered.Count) files written to $output"
