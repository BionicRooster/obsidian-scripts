# Check for wikilinks pointing to LSA files and MOC references

$vault = 'D:\Obsidian\Main'

# 1. Any files at the LSA root (not in subdirs)?
Write-Output "=== LSA root-level files ==="
Get-ChildItem 'D:\Obsidian\Main\LSA' -File | ForEach-Object { Write-Output "  $($_.Name)" }

# 2. Check for wikilinks to Be161..Be181 anywhere in vault
Write-Output "`n=== Wikilinks to Be1xx files ==="
Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.FullName -notlike '*\LSA\*'
} | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if ($content -imatch '\[\[Be1[0-9]') {
        Write-Output "  $($_.FullName)"
        ($content -split "`r`n|`n") | Where-Object { $_ -imatch '\[\[Be1[0-9]' } | ForEach-Object {
            Write-Output "    $_"
        }
    }
}

# 3. MOC references to LSA or Year in Review
Write-Output "`n=== MOC references to LSA ==="
Get-ChildItem "$vault\00 - Home Dashboard" -Filter '*.md' | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw
    if ($content -imatch 'LSA|Year in Review|Be16|Be17|Be18') {
        Write-Output "  $($_.Name):"
        ($content -split "`r`n|`n") | Where-Object { $_ -imatch 'LSA|Year in Review|Be16|Be17|Be18' } | ForEach-Object {
            Write-Output "    $_"
        }
    }
}

# 4. Nav properties inside the Be* files themselves
Write-Output "`n=== Nav properties in Be* files ==="
Get-ChildItem 'D:\Obsidian\Main\LSA\Year in Review' -Filter '*.md' | Select-Object -First 3 | ForEach-Object {
    Write-Output "  --- $($_.Name) ---"
    $lines = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -TotalCount 10
    $lines | ForEach-Object { Write-Output "    $_" }
}
