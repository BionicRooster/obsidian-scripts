# Add Library.md to FOL MOC since it was moved there
$folPath = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Friends of the Georgetown Public Library.md'
$folContent = Get-Content -LiteralPath $folPath -Raw -Encoding UTF8

if ($folContent -notmatch '\[\[Library\]\]') {
    # Insert into Related section
    $folContent = $folContent -replace '(## Related\r?\n)', "`$1- [[Library]]`n"
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($folContent)
    [System.IO.File]::WriteAllBytes($folPath, $bytes)
    Write-Host "Added [[Library]] to FOL MOC > Related"
} else {
    Write-Host "[[Library]] already in FOL MOC"
}

# Verify
$check = Get-Content -LiteralPath $folPath -Raw -Encoding UTF8
Write-Host "Library in FOL: " ($check -match '\[\[Library\]\]')
