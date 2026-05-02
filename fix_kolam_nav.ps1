# Fix Kolam file - add nav property to frontmatter
$clippings = "D:\Obsidian\Main\10 - Clippings"
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Kolam*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    Write-Host "Current first 300 chars:"
    Write-Host $c.Substring(0, [Math]::Min(300, $c.Length))
    Write-Host "---"

    # Check if nav already present
    if ($c -match '(?m)^nav:') {
        Write-Host "nav already present"
    } else {
        # Add nav after the opening ---
        # Find the first --- and insert nav after it
        $firstDash = $c.IndexOf("---")
        if ($firstDash -ge 0) {
            $insertPos = $firstDash + 3  # after "---"
            # Skip any \r\n after the opening ---
            if ($c[$insertPos] -eq "`r") { $insertPos++ }
            if ($c[$insertPos] -eq "`n") { $insertPos++ }
            $navLine = "nav: " + '"[[00 - Home Dashboard/MOC - Science & Nature]]"' + "`n"
            $c = $c.Substring(0, $firstDash + 3) + "`n" + $navLine + $c.Substring($insertPos)
            [System.IO.File]::WriteAllText($file.FullName, $c, (New-Object System.Text.UTF8Encoding $false))
            Write-Host "Added nav to: $($file.Name)"
        }
    }
}
