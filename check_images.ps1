$dir = "D:\Obsidian\Main\02 - Working Projects\2024 Columbia River Trip"
$files = Get-ChildItem $dir -Filter "*.md"
$noImage = @()
$hasImage = @()
foreach ($f in $files) {
    $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($c -match '!\[\[|!\[.*\]\(http') {
        $hasImage += $f.Name
    } else {
        $noImage += $f.Name
    }
}
Write-Host "NO IMAGES ($($noImage.Count)):"
$noImage | Sort-Object
Write-Host ""
Write-Host "HAS IMAGES ($($hasImage.Count)):"
$hasImage | Sort-Object
