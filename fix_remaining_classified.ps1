# Fix remaining unclassified items

$ErrorActionPreference = 'Stop'
$techMOC = 'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Technology & Computers.md'
$recMOC  = 'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Recipes.md'
$nbspChar = [char]0x00A0  # non-breaking space
$nbspStr  = "$nbspChar"

# -------------------------------------------------------------------
# 1. Rename Brian K. White file: replace non-breaking space with regular space
# -------------------------------------------------------------------
Write-Output "=== Fix 1: Brian K. White filename ==="
$bkwDir  = 'C:\Users\awt\Sync\Obsidian\01\Technology'
$bkwFiles = Get-ChildItem $bkwDir | Where-Object { $_.Name -like 'Brian K*' -and $_.Name.Contains($nbspChar) }
foreach ($f in $bkwFiles) {
    $oldPath = $f.FullName
    $newName = $f.Name -replace $nbspStr, ' '
    $newPath = Join-Path $bkwDir $newName
    # Two-step rename to handle case sensitivity
    $tmpPath = Join-Path $bkwDir ($newName + '.tmp')
    Rename-Item -LiteralPath $oldPath -NewName ($newName + '.tmp')
    Rename-Item -LiteralPath $tmpPath -NewName $newName
    Write-Output "  Renamed: [$($f.Name)] -> [$newName]"
}
if (-not $bkwFiles) { Write-Output "  No non-breaking-space files found" }

# -------------------------------------------------------------------
# 2. Fix IFTTT MOC entry: curly apostrophe in We're -> straight apostrophe
# -------------------------------------------------------------------
Write-Output "`n=== Fix 2: IFTTT apostrophe in MOC ==="
$techContent = Get-Content -LiteralPath $techMOC -Encoding UTF8 -Raw
# The IFTTT line with curly apostrophe in We're (U+2019) before Thankful
$curlyApos = [char]0x2019
$iftttCurly  = "This November at IFTTT We$($curlyApos)re Thankful For"
$iftttStraight = "This November at IFTTT We're Thankful For"
if ($techContent -match [regex]::Escape($iftttCurly)) {
    $techContent = $techContent -replace [regex]::Escape($iftttCurly), $iftttStraight
    Set-Content -LiteralPath $techMOC -Value $techContent -Encoding UTF8 -NoNewline
    Write-Output "  Fixed curly apostrophe in IFTTT link"
} else {
    Write-Output "  IFTTT curly-apos pattern not found (may already be straight)"
}

# -------------------------------------------------------------------
# 3. Fix Technology MOC run-together ]]## issues
# -------------------------------------------------------------------
Write-Output "`n=== Fix 3: Technology MOC run-together lines ==="
$techContent = Get-Content -LiteralPath $techMOC -Encoding UTF8 -Raw
$before = ($techContent -split "`n").Count
# Fix all ]]## patterns (no newline before section heading)
$fixed = $techContent -replace '(\]\])(#{1,3} )', "`$1`n`$2"
$after = ($fixed -split "`n").Count
if ($fixed -ne $techContent) {
    Set-Content -LiteralPath $techMOC -Value $fixed -Encoding UTF8 -NoNewline
    Write-Output "  Fixed run-together lines: $($after - $before) extra newlines added"
} else {
    Write-Output "  No run-together lines found"
}

# -------------------------------------------------------------------
# 4. Fix Recipes MOC run-together ]]- patterns (items on same line)
# -------------------------------------------------------------------
Write-Output "`n=== Fix 4: Recipes MOC run-together ==="
$recContent = Get-Content -LiteralPath $recMOC -Encoding UTF8 -Raw
# Fix ]]- [[  (two list items on same line)
$fixedRec = $recContent -replace '(\]\])(\- \[\[)', "`$1`n`$2"
# Fix ]]## (section headings run-together)
$fixedRec = $fixedRec -replace '(\]\])(#{1,3} )', "`$1`n`$2"
if ($fixedRec -ne $recContent) {
    Set-Content -LiteralPath $recMOC -Value $fixedRec -Encoding UTF8 -NoNewline
    Write-Output "  Fixed Recipes MOC run-together lines"
} else {
    Write-Output "  No run-together issues in Recipes MOC"
}

# -------------------------------------------------------------------
# 5. Delete generated report file
# -------------------------------------------------------------------
Write-Output "`n=== Fix 5: Delete Link Recommendations generated file ==="
$lrPath = 'C:\Users\awt\Sync\Obsidian\01\NLP\Link Recommendations for 10 Additional Obsidian Notes Batch 2.md'
if (Test-Path -LiteralPath $lrPath) {
    Remove-Item -LiteralPath $lrPath
    Write-Output "  Deleted: Link Recommendations for 10 Additional Obsidian Notes Batch 2.md"
} else {
    Write-Output "  File not found"
}

# -------------------------------------------------------------------
# 6. Add 16 - Organizations.md to Bahá'í MOC (Community & Service section)
# -------------------------------------------------------------------
Write-Output "`n=== Fix 6: 16 - Organizations.md link in Baha'i MOC ==="
$bahai = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Bah$(([char]0x00e1))'$(([char]0x00ed)) Faith.md"
if (Test-Path -LiteralPath $bahai) {
    $bahaiContent = Get-Content -LiteralPath $bahai -Encoding UTF8 -Raw
    if ($bahaiContent -match '16 - Organizations') {
        Write-Output "  Already linked in Baha'i MOC"
    } else {
        # Find Community & Service section and add link
        $section = '## Community & Service'
        $idx = $bahaiContent.IndexOf($section)
        if ($idx -ge 0) {
            $afterSection = $idx + $section.Length
            $nextSect = [regex]::Match($bahaiContent.Substring($afterSection), '(?m)^#{1,3} ')
            if ($nextSect.Success) {
                $insertPos = $afterSection + $nextSect.Index
                # Back up past trailing newlines
                while ($insertPos -gt ($afterSection + 2) -and $bahaiContent[$insertPos - 1] -match '[\r\n]') { $insertPos-- }
                $insertPos++
                $newLink = "`n- [[16 - Organizations]]"
                $bahaiContent = $bahaiContent.Substring(0, $insertPos) + $newLink + $bahaiContent.Substring($insertPos)
            } else {
                $bahaiContent = $bahaiContent.TrimEnd() + "`n- [[16 - Organizations]]`n"
            }
            Set-Content -LiteralPath $bahai -Value $bahaiContent -Encoding UTF8 -NoNewline
            Write-Output "  Added [[16 - Organizations]] to Community & Service in Baha'i MOC"
        } else {
            Write-Output "  WARNING: Community & Service section not found"
        }
    }
} else {
    Write-Output "  WARNING: Baha'i MOC not found at expected path"
}

Write-Output "`n=== Done ==="
