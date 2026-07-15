# Search vault for any mention of Malinda or Lloyd
$results = Get-ChildItem 'C:\Users\awt\Sync\Obsidian' -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
    $content = Get-Content $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if ($content -match 'Malinda' -or ($content -match '\bLloyd\b' -and $_.BaseName -ne 'Malinda Lloyd')) {
        Write-Output $_.FullName
    }
}
Write-Host "Files mentioning Malinda or Lloyd:"
$results | ForEach-Object { Write-Host "  $_" }

# Check the HOW photo
$photo = 'D:\Downloads\_Photo\Malinda at HOW 2024.jpg'
if (Test-Path $photo) {
    $fi = Get-Item $photo
    Write-Host "`nHOW Photo found:"
    Write-Host "  File: $($fi.FullName)"
    Write-Host "  Size: $($fi.Length) bytes"
    Write-Host "  Modified: $($fi.LastWriteTime)"
}

# Check Wilmette-related files
Write-Host "`nWilmette/HOW related files:"
Get-ChildItem 'C:\Users\awt\Sync\Obsidian' -Recurse -Filter '*.md' -ErrorAction SilentlyContinue | Where-Object {
    $_.BaseName -like '*HOW*' -or $_.BaseName -like '*House of Worship*' -or $_.BaseName -like '*Wilmette*'
} | ForEach-Object { Write-Host "  $($_.FullName)" }
