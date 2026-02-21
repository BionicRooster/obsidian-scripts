$mocDir = 'D:\Obsidian\Main\00 - Home Dashboard'
$mocFiles = Get-ChildItem $mocDir -Filter 'MOC*.md' | Sort-Object Name
foreach ($moc in $mocFiles) {
    Write-Host "===== $($moc.Name) ====="
    $content = Get-Content $moc.FullName -Encoding UTF8
    foreach ($line in $content) {
        if ($line -match '^#{2,3}\s') {
            Write-Host $line
        }
    }
    Write-Host ''
}
