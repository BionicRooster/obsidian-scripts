# Fix files that still have onenote-import tag - replace with meaningful tags
$clippings = "C:\Users\awt\Sync\Obsidian\10 - Clippings"

# Map of file patterns to proper tags
$tagFixes = @{
    "*Weed Killer*"   = "  - Home`n  - Gardening`n  - WeedKiller`n  - DIY`n  - NaturalCare"
    "*Microfiction*"  = "  - Fiction`n  - DresdenFiles`n  - JimButcher`n  - ShortStory"
}

foreach ($pattern in $tagFixes.Keys) {
    $file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like $pattern } | Select-Object -First 1
    if ($file) {
        $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
        if ($c -match '(?m)^  - onenote-import') {
            $c = $c -replace '(?m)^  - onenote-import\r?\n', ($tagFixes[$pattern] + "`n")
            [System.IO.File]::WriteAllText($file.FullName, $c, (New-Object System.Text.UTF8Encoding $false))
            Write-Host "Fixed tags in: $($file.Name)"
        } else {
            Write-Host "No onenote-import tag in: $($file.Name)"
        }
    }
}

Write-Host "Done"
