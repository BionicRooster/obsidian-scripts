$mocs = @{
    "MOC - NLP & Psychology.md" = "Cognitive Science"
    "MOC - Technology & Computers.md" = @("Maker Projects", "Networking & Systems", "AI & Machine Learning")
    "MOC - Home & Practical Life.md" = "Practical Tips & Life Hacks"
}

foreach ($moc in $mocs.Keys) {
    $path = "D:\Obsidian\Main\00 - Home Dashboard\$moc"
    Write-Host "=== $moc ==="
    $lines = Get-Content $path -Encoding UTF8
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^##\s+') {
            Write-Host "  Line $($i+1): $($lines[$i])"
        }
    }
    Write-Host ""
}
