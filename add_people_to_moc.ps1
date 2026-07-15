# Add people entries to MOCs by appending to end of file

# Jack Wallen -> Tech MOC
$techPath = 'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Technology & Computers.md'
$techContent = Get-Content $techPath -Encoding UTF8 -Raw
if ($techContent -notmatch 'Jack Wallen') {
    $techContent = $techContent.TrimEnd() + "`n`n## People`n- [[Jack Wallen]]`n"
    [System.IO.File]::WriteAllText($techPath, $techContent, [System.Text.Encoding]::UTF8)
    Write-Host "Added Wallen to Tech MOC"
}

# Colin Marshall -> Travel MOC (Japan section)
$travelPath = 'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Travel & Exploration.md'
$travelContent = Get-Content $travelPath -Encoding UTF8 -Raw
if ($travelContent -notmatch 'Colin Marshall') {
    # Add to Japan section if it exists, else append
    if ($travelContent -match '## Japan') {
        $travelContent = $travelContent -replace '(## Japan\r?\n)', "`$1- [[Colin Marshall]]`n"
    } else {
        $travelContent = $travelContent.TrimEnd() + "`n`n## People`n- [[Colin Marshall]]`n"
    }
    [System.IO.File]::WriteAllText($travelPath, $travelContent, [System.Text.Encoding]::UTF8)
    Write-Host "Added Colin to Travel MOC"
}

# Verify
$t = Get-Content $techPath -Encoding UTF8 | Select-String 'Jack Wallen'
$tr = Get-Content $travelPath -Encoding UTF8 | Select-String 'Colin Marshall'
Write-Host "Wallen confirmed: $(if($t){'YES'}else{'NO'})"
Write-Host "Colin confirmed: $(if($tr){'YES'}else{'NO'})"
