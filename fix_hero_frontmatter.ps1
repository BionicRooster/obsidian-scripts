# Fix Can You Say Hero frontmatter
$clippings = "D:\Obsidian\Main\10 - Clippings"
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Hero*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw

    # Build new frontmatter piece by piece (avoid special chars in string literals)
    $desc = "A profile of Mister Rogers by Tom Junod for Esquire, November 1998"
    $newFM = "---" + "`n"
    $newFM += "nav: " + '"[[00 - Home Dashboard/MOC - Reading & Literature]]"' + "`n"
    $newFM += "title: " + '"Can You Say Hero? | Esquire | November 1998"' + "`n"
    $newFM += "source: " + '"https://classic.esquire.com/article/1998/11/1/can-you-say-hero"' + "`n"
    $newFM += "author:" + "`n"
    $newFM += "  - " + '"[[Tom Junod]]"' + "`n"
    $newFM += "published: 1998-11-01" + "`n"
    $newFM += "created: 2026-02-26" + "`n"
    $newFM += "description: " + '"' + $desc + '"' + "`n"
    $newFM += "tags:" + "`n"
    $newFM += "  - TV" + "`n"
    $newFM += "  - MrRogers" + "`n"
    $newFM += "  - Children" + "`n"
    $newFM += "  - Kindness" + "`n"
    $newFM += "  - Esquire" + "`n"
    $newFM += "---" + "`n"

    # Replace the entire frontmatter block (from --- to closing ---)
    $c = [regex]::Replace($c, '(?s)^---.*?---\r?\n', $newFM)

    [System.IO.File]::WriteAllText($file.FullName, $c, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "Updated: $($file.Name)"
}
