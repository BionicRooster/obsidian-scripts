# Fix triple closing brackets in MOC files
$mocPath = "D:\Obsidian\Main\00 - Home Dashboard"

Get-ChildItem -Path $mocPath -Filter "*MOC*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -Encoding UTF8
    if ($content -match '\]\]\]') {
        $fixed = $content -replace '\]\]\]', ']]'
        [System.IO.File]::WriteAllText($_.FullName, $fixed, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Fixed triple brackets in: $($_.Name)" -ForegroundColor Green
    }
}
