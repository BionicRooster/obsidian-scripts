# Check which recently added notes could benefit from broader cross-topic links

# Check if the Badí Calendar notes link to each other already
$badiFiles = @(
    'Chart of Calendars',
    'Twin Holy Birthdays - Bringing Two Calendars Together',
    'Badí Calendar Class - Learning Self Assessment',
    'Badí Calendar Class - Personal Learning Plan'
)

Write-Host "=== Badi Calendar cross-links ==="
foreach ($name in $badiFiles) {
    $found = Get-ChildItem 'D:\Obsidian\Main\01\Bah*' -Recurse -Filter '*.md' |
        Where-Object { $_.BaseName -like "*$($name.Substring(0,6))*" } | Select-Object -First 1
    if ($found) {
        $content = Get-Content $found.FullName -Encoding UTF8 -Raw
        if ($content -match '## Related Notes') {
            Write-Host "HAS Related Notes: $name"
        } else {
            Write-Host "MISSING Related Notes: $name"
        }
    }
}

# Check 'Abdu'l-Baha related notes
Write-Host "`n=== Abdu'l-Baha ==="
$abdu = Get-ChildItem 'D:\Obsidian\Main\01\Bah*' -Filter "*Abdu*" | Select-Object -First 1
if ($abdu) {
    $content = Get-Content $abdu.FullName -Encoding UTF8 -Raw
    if ($content -match '(?s)## Related Notes(.{0,500})') {
        Write-Host $Matches[0].Trim()
    }
}
