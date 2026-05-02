# Fix Kolam file nav - use "Discover" pattern to find file with macron in name
$clippings = "D:\Obsidian\Main\10 - Clippings"
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Discover*" } | Select-Object -First 1
if ($file) {
    Write-Host "Found: $($file.Name)"
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    Write-Host "Has nav: $($c -match '(?m)^nav:')"

    if (-not ($c -match '(?m)^nav:')) {
        # Insert nav after opening ---
        $navLine = "nav: " + '"[[00 - Home Dashboard/MOC - Science & Nature]]"' + "`n"
        # Find position right after the opening ---
        if ($c.StartsWith("---`n")) {
            $c = "---`n" + $navLine + $c.Substring(4)
        } elseif ($c.StartsWith("---`r`n")) {
            $c = "---`r`n" + $navLine + $c.Substring(5)
        }
        [System.IO.File]::WriteAllText($file.FullName, $c, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "Added nav to: $($file.Name)"
    }
} else {
    Write-Host "No Discover file found"
    Get-ChildItem -LiteralPath $clippings | ForEach-Object { Write-Host "  $($_.Name)" }
}
