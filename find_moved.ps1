# Find files in flat NLP folder that have source: pointing to NLP Master Class
$flatDir = 'C:\Users\awt\Sync\Obsidian\01\NLP'
$destDir = 'C:\Users\awt\Sync\Obsidian\01\NLP\NLP Master Class'

$moved = @()
Get-ChildItem -Path $flatDir -File -Filter '*.md' | ForEach-Object {
    $lines = Get-Content $_.FullName -Encoding UTF8 -TotalCount 15
    $hasSource = $lines | Where-Object { $_ -match 'source:.*NLP.*Master.Class' }
    if ($hasSource) {
        $moved += $_.Name
    }
}

Write-Host "Files in flat NLP that originated from NLP Master Class:"
$moved | ForEach-Object { Write-Host "  $_" }
Write-Host ""
Write-Host "Total: $($moved.Count)"
