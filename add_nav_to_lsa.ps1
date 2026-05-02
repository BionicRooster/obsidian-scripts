# Check and add nav property to BE* files in LSA/Year in Review

$yearDir = Get-ChildItem 'D:\Obsidian\Main\01' -Recurse -Directory |
           Where-Object { $_.Name -eq 'Year in Review' } | Select-Object -First 1

if (-not $yearDir) { Write-Error "Year in Review dir not found"; exit 1 }
Write-Output "Working in: $($yearDir.FullName)"

$navValue = "[[MOC - Bah$([char]0x00e1)'$([char]0x00ed) Faith]]"
$added = 0
$skipped = 0

Get-ChildItem $yearDir.FullName -Filter 'BE*.md' | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw
    if ($content -match '(?m)^nav:') {
        $skipped++
        return
    }
    # Insert nav after the opening ---
    # File starts: ---\r\n or ---\n
    $newContent = $content -replace '(?m)^(---\r?\n)', "`$1nav: `"$navValue`"`n"
    if ($newContent -eq $content) {
        Write-Output "  WARNING: pattern not matched in $($_.Name)"
        return
    }
    Set-Content -LiteralPath $_.FullName -Value $newContent -Encoding UTF8 -NoNewline
    $added++
}

Write-Output "Added nav to: $added files"
Write-Output "Skipped (already had nav): $skipped files"

# Verify one file
$sample = Get-ChildItem $yearDir.FullName -Filter 'BE*.md' | Select-Object -First 1
Write-Output "`nSample ($($sample.Name)) first 4 lines:"
(Get-Content -LiteralPath $sample.FullName -Encoding UTF8 -TotalCount 4) | ForEach-Object { Write-Output "  $_" }
