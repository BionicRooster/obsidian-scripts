$techContent = Get-Content 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Technology & Computers.md' -Encoding UTF8
$travelContent = Get-Content 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Travel & Exploration.md' -Encoding UTF8

$wallenInTech = ($techContent | Select-String 'Jack Wallen').Count
$colinInTravel = ($travelContent | Select-String 'Colin Marshall').Count

Write-Host "Jack Wallen in Tech MOC: $wallenInTech"
Write-Host "Colin Marshall in Travel MOC: $colinInTravel"

# Show where they appear
if ($wallenInTech -gt 0) {
    $techContent | Select-String 'Jack Wallen' | ForEach-Object { Write-Host "  Tech line $($_.LineNumber): $($_.Line)" }
}
if ($colinInTravel -gt 0) {
    $travelContent | Select-String 'Colin Marshall' | ForEach-Object { Write-Host "  Travel line $($_.LineNumber): $($_.Line)" }
}
