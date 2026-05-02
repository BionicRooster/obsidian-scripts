# Add Jack Wallen to MOC - Technology & Computers
$techMoc = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Technology & Computers.md'
$content = Get-Content $techMoc -Encoding UTF8 -Raw
# Check if already there
if ($content -notmatch 'Jack Wallen') {
    # Add to a people/contributors section or Software & Tools
    # Find ## People section or add to a suitable place
    if ($content -match '## People') {
        $content = $content -replace '(## People\r?\n)', "`$1- [[Jack Wallen]]`n"
    } else {
        # Add near the end before --- or related topics
        $content = $content -replace '(---\s*$)', "## People`n- [[Jack Wallen]]`n`n`$1"
    }
    [System.IO.File]::WriteAllText($techMoc, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Added Wallen to Tech MOC"
} else {
    Write-Host "Wallen already in Tech MOC"
}

# Add Colin Marshall to MOC - Travel & Exploration
$travelMoc = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Travel & Exploration.md'
$content = Get-Content $travelMoc -Encoding UTF8 -Raw
if ($content -notmatch 'Colin Marshall') {
    if ($content -match '## People') {
        $content = $content -replace '(## People\r?\n)', "`$1- [[Colin Marshall]]`n"
    } else {
        $content = $content -replace '(---\s*$)', "## People`n- [[Colin Marshall]]`n`n`$1"
    }
    [System.IO.File]::WriteAllText($travelMoc, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Added Colin to Travel MOC"
} else {
    Write-Host "Colin already in Travel MOC"
}

# Show sections of Tech MOC to confirm
Write-Host "`n=== Tech MOC sections ==="
(Get-Content $techMoc -Encoding UTF8) | Select-String '## ' | ForEach-Object { Write-Host $_.Line }
