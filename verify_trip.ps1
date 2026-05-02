$dest = "D:\Obsidian\Main\02 - Working Projects\2024 Columbia River Trip"
$files = Get-ChildItem $dest -Filter "*.md"
Write-Host "Total files in destination: $($files.Count)"

# Spot-check 3 files
$checkFiles = @("Cape Horn.md", "Devil's Punchbowl.md", "Columbia Gorge Interpretive Center.md")
foreach ($name in $checkFiles) {
    $f = Join-Path $dest $name
    if (Test-Path $f) {
        Write-Host "`n=== $name ==="
        $content = Get-Content $f -Encoding UTF8 -TotalCount 30
        $inTags = $false
        foreach ($line in $content) {
            if ($line -match '^tags:') { $inTags = $true }
            if ($inTags) { Write-Host $line }
            if ($inTags -and $line -match '^---' -and $line -ne '---') { break }
            if ($inTags -and $line -match '^[a-z]' -and $line -notmatch '^tags:') { break }
        }
    }
}
