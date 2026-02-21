# Load orphan list
$orphansJson = Get-Content "C:\Users\awt\orphan_list.json" -Encoding UTF8 -Raw
$orphans = $orphansJson | ConvertFrom-Json

# Search for Bahai content in orphans
$matchedOrphans = [System.Collections.ArrayList]@()
foreach ($orphan in $orphans) {
    $fullPath = $orphan.FullPath
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
        if ($content -match "Bahá'í|Baha'i|Bahá'u'lláh|Bahaullah|Abdu'l-Bahá|Abdul-Baha|Shoghi Effendi|Universal House of Justice|UHJ|Nine Year Plan|Ridván") {
            [void]$matchedOrphans.Add([PSCustomObject]@{
                FullPath = $orphan.FullPath
                Name = $orphan.Name
                Folder = $orphan.Folder
            })
        }
    }
}

Write-Host "Found $($matchedOrphans.Count) Bahai-related orphans:"
$matchedOrphans | ForEach-Object { Write-Host "  - $($_.Name)" }
$matchedOrphans | ConvertTo-Json | Out-File "C:\Users\awt\bahai_orphans.json" -Encoding UTF8
