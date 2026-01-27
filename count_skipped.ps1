# Count files in folders skipped by link_largest_orphan.ps1
$vaultPath = 'D:\Obsidian\Main'
$skipFolders = @('00 - Journal', '05 - Templates', '00 - Images', 'attachments', '.trash', '.obsidian', '.smart-env')

$totalSkipped = 0
foreach ($folder in $skipFolders) {
    $path = Join-Path $vaultPath $folder
    if (Test-Path $path) {
        $count = (Get-ChildItem -Path $path -Filter '*.md' -Recurse -ErrorAction SilentlyContinue).Count
        Write-Host "$folder : $count files"
        $totalSkipped += $count
    } else {
        Write-Host "$folder : (folder not found)"
    }
}
Write-Host ""
Write-Host "Total files in skipped folders: $totalSkipped"

# Now count orphans in those folders from Orphan Files.md
Write-Host ""
Write-Host "--- Checking Orphan Files.md for breakdown ---"
$orphanContent = Get-Content "D:\Obsidian\Main\Orphan Files.md" -Raw
foreach ($folder in $skipFolders) {
    $pattern = "## $folder"
    if ($orphanContent -match "$pattern \((\d+)\)") {
        Write-Host "$folder orphans: $($Matches[1])"
    }
}
