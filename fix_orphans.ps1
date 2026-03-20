# fix_orphans.ps1 - Fixes all identified orphan file problems

$vaultPath = 'D:\Obsidian\Main'
$mocDir    = Join-Path $vaultPath '00 - Home Dashboard'

# Read a file preserving UTF-8 BOM
function Read-Utf8 {
    param([string]$Path)
    $bytes  = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text   = if ($hasBom) {
        [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    } else {
        [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    return [PSCustomObject]@{ Text = $text; HasBom = $hasBom }
}

# Write a file preserving UTF-8 BOM if original had one
function Write-Utf8 {
    param([string]$Path, [string]$Text, [bool]$HasBom)
    $enc      = [System.Text.Encoding]::UTF8
    $outBytes = $enc.GetBytes($Text)
    if ($HasBom) {
        $bomBytes = [byte[]](0xEF, 0xBB, 0xBF)
        $outBytes = $bomBytes + $outBytes
    }
    [System.IO.File]::WriteAllBytes($Path, $outBytes)
}

# Insert a wikilink after an anchor line in a MOC file
function Insert-MocLink {
    param(
        [string]$MocPath,
        [string]$LinkText,
        [string]$Anchor,
        [bool]$AnchorIsLink
    )
    $f = Read-Utf8 $MocPath
    if ($f.Text -match [regex]::Escape($LinkText)) {
        Write-Host "  Already present: [[$LinkText]]" -ForegroundColor DarkGray
        return $false
    }
    $anchorFull = if ($AnchorIsLink) { "- [[$Anchor]]" } else { $Anchor }
    if ($f.Text -notmatch [regex]::Escape($anchorFull)) {
        Write-Host "  WARN: anchor not found '$anchorFull'" -ForegroundColor Yellow
        return $false
    }
    $newText = $f.Text -replace [regex]::Escape($anchorFull), "$anchorFull`n- [[$LinkText]]"
    Write-Utf8 $MocPath $newText $f.HasBom
    Write-Host "  Added [[$LinkText]]" -ForegroundColor Green
    return $true
}

# =============================================================================
# PHASE 1 - Rename double-space filenames to single-space
# =============================================================================
Write-Host ''
Write-Host '=== PHASE 1: Rename double-space filenames ===' -ForegroundColor Cyan

$renames = @(
    @{ Old = '01\Technology\AcSpreadSheetType  List.md';             New = '01\Technology\AcSpreadSheetType List.md' },
    @{ Old = '01\Technology\FarmVille Cheats  Top 10 Cash Crops.md'; New = '01\Technology\FarmVille Cheats Top 10 Cash Crops.md' },
    @{ Old = '01\Technology\Google Apps Standard  Edition.md';       New = '01\Technology\Google Apps Standard Edition.md' },
    @{ Old = '01\Technology\LiveCode  Create App.md';                New = '01\Technology\LiveCode Create App.md' },
    @{ Old = '01\Technology\Outlook Macro  Move.md';                 New = '01\Technology\Outlook Macro Move.md' },
    @{ Old = '01\Technology\VBA Express  Excel.md';                  New = '01\Technology\VBA Express Excel.md' },
    @{ Old = '01\Psychology\HP Retiree  Dave Pac.md';                New = '01\Psychology\HP Retiree Dave Packard.md' }
)

foreach ($r in $renames) {
    $oldPath = Join-Path $vaultPath $r.Old
    $newPath = Join-Path $vaultPath $r.New
    if (-not (Test-Path $oldPath)) {
        Write-Host "  SKIP (not found): $($r.Old)" -ForegroundColor DarkGray
        continue
    }
    if (Test-Path $newPath) {
        Write-Host "  SKIP (dest exists): $($r.New)" -ForegroundColor DarkGray
        continue
    }
    Rename-Item -LiteralPath $oldPath -NewName (Split-Path $newPath -Leaf)
    Write-Host "  Renamed: $(Split-Path $r.Old -Leaf) -> $(Split-Path $r.New -Leaf)" -ForegroundColor Green
}

# Fix any double-space wikilinks in MOC files
Write-Host '  Fixing double-space wikilinks in MOC files...' -ForegroundColor Cyan

$linkFixes = @{
    'AcSpreadSheetType  List'              = 'AcSpreadSheetType List'
    'FarmVille Cheats  Top 10 Cash Crops'  = 'FarmVille Cheats Top 10 Cash Crops'
    'Google Apps Standard  Edition'        = 'Google Apps Standard Edition'
    'LiveCode  Create App'                 = 'LiveCode Create App'
    'Outlook Macro  Move'                  = 'Outlook Macro Move'
    'VBA Express  Excel'                   = 'VBA Express Excel'
    'HP Retiree  Dave Pac'                 = 'HP Retiree Dave Packard'
}

Get-ChildItem $mocDir -Filter '*.md' | ForEach-Object {
    $mocFile = $_
    $f       = Read-Utf8 $mocFile.FullName
    $changed = $false
    $newText = $f.Text
    foreach ($oldLink in $linkFixes.Keys) {
        $newLink = $linkFixes[$oldLink]
        if ($newText -match [regex]::Escape($oldLink)) {
            $newText = $newText -replace [regex]::Escape($oldLink), $newLink
            $changed = $true
            Write-Host "  Fixed link in $($mocFile.Name): '$oldLink' -> '$newLink'" -ForegroundColor Green
        }
    }
    if ($changed) { Write-Utf8 $mocFile.FullName $newText $f.HasBom }
}

# =============================================================================
# PHASE 2 - Fix Reed Island filename (bullet chars -> plain ampersand)
# =============================================================================
Write-Host ''
Write-Host '=== PHASE 2: Fix Reed Island filename ===' -ForegroundColor Cyan

$reedDir     = Join-Path $vaultPath '03 - Completed Projects\2024 Columbia River Trip'
$bulletChar  = [char]0x2022
$reedOldName = 'Reed Island' + $bulletChar + ' ' + '&' + $bulletChar + 'Steigerwald Wildlife Refuge.md'
$reedNewName = 'Reed Island & Steigerwald Wildlife Refuge.md'
$reedOldPath = Join-Path $reedDir $reedOldName
$reedNewPath = Join-Path $reedDir $reedNewName

if (Test-Path -LiteralPath $reedOldPath) {
    if (Test-Path $reedNewPath) {
        Write-Host '  SKIP: destination already exists' -ForegroundColor DarkGray
    } else {
        Rename-Item -LiteralPath $reedOldPath -NewName $reedNewName
        Write-Host '  Renamed Reed Island file (removed bullet chars)' -ForegroundColor Green
    }
} else {
    Write-Host '  Reed Island old file not found -- may already be renamed' -ForegroundColor DarkGray
}

# Fix the Travel MOC link
$travelMocPath = Join-Path $mocDir 'MOC - Travel & Exploration.md'
$f       = Read-Utf8 $travelMocPath
$newText = $f.Text -replace '\[\[Reed Island[^\]]*Steigerwald[^\]]*\]\]', '[[Reed Island & Steigerwald Wildlife Refuge]]'
if ($newText -ne $f.Text) {
    Write-Utf8 $travelMocPath $newText $f.HasBom
    Write-Host '  Fixed Reed Island link in Travel MOC' -ForegroundColor Green
} else {
    Write-Host '  Reed Island link already correct or not found' -ForegroundColor DarkGray
}

# =============================================================================
# PHASE 3 - Fix Kahneman broken link in NLP MOC (comma mismatch)
# =============================================================================
Write-Host ''
Write-Host '=== PHASE 3: Fix Kahneman link in NLP MOC ===' -ForegroundColor Cyan

$nlpMocPath = Join-Path $mocDir 'MOC - NLP & Psychology.md'
$f       = Read-Utf8 $nlpMocPath
$broken  = '[[Kahneman-Thinking, Fast and Slow]]'
$correct = '[[Kahneman-Thinking Fast and Slow]]'

if ($f.Text -match [regex]::Escape($broken)) {
    $newText = $f.Text -replace [regex]::Escape($broken), $correct
    Write-Utf8 $nlpMocPath $newText $f.HasBom
    Write-Host '  Fixed: removed comma from Kahneman link' -ForegroundColor Green
} elseif ($f.Text -match [regex]::Escape($correct)) {
    Write-Host '  Already correct (no comma)' -ForegroundColor DarkGray
} else {
    Write-Host '  Kahneman link not found -- will add in Phase 6' -ForegroundColor Yellow
}

# =============================================================================
# PHASE 4 - Add The Tablet of Ahmad to Bahai MOC > Core Teachings
# =============================================================================
Write-Host ''
Write-Host '=== PHASE 4: Add Tablet of Ahmad to Bahai MOC ===' -ForegroundColor Cyan

$bahaiMocPath = Get-ChildItem $mocDir |
    Where-Object { $_.Name -match 'Bah' -and $_.Name -match 'Faith' } |
    Select-Object -First 1 -ExpandProperty FullName

# Alphabetically in Core Teachings: after "The Promulgation of Universal Peace"
Insert-MocLink -MocPath $bahaiMocPath `
    -LinkText 'The Tablet of Ahmad' `
    -Anchor   'The Promulgation of Universal Peace' `
    -AnchorIsLink $true

# =============================================================================
# PHASE 5 - Add GreyNoise to Tech MOC > Computer Sciences
# =============================================================================
Write-Host ''
Write-Host '=== PHASE 5: Add GreyNoise to Tech MOC ===' -ForegroundColor Cyan

$techMocPath = Join-Path $mocDir 'MOC - Technology & Computers.md'
# Alphabetically: after "Greenscreen backdrop", before "Guild of Dungeoneering"
Insert-MocLink -MocPath $techMocPath `
    -LinkText 'GreyNoise Ip Check' `
    -Anchor   'Greenscreen backdrop' `
    -AnchorIsLink $true

# =============================================================================
# PHASE 6 - Add Kindle Clippings and other notes to MOCs
# =============================================================================
Write-Host ''
Write-Host '=== PHASE 6: Add Kindle Clippings to MOCs ===' -ForegroundColor Cyan

$homeMocPath = Join-Path $mocDir 'MOC - Home & Practical Life.md'
$sciMocPath  = Join-Path $mocDir 'MOC - Science & Nature.md'

# 6a. Genetic Genealogy in Practice -> Home > Practical Tips (after IRS Wash Sale Rules)
Write-Host '  6a. Genetic Genealogy -> Home & Practical Life > Practical Tips' -ForegroundColor White
Insert-MocLink -MocPath $homeMocPath `
    -LinkText 'Bettinger-Wayne-Genetic Genealogy in Practice' `
    -Anchor   'IRS Wash Sale Rules' `
    -AnchorIsLink $true

# 6b. Retire to an RV -> Travel > RV & Alternative Living (after "Fixed Gear Gallery")
Write-Host '  6b. Retire to an RV -> Travel > RV & Alternative Living' -ForegroundColor White
Insert-MocLink -MocPath $travelMocPath `
    -LinkText 'Bruzenak_et_al-Retire to an RV' `
    -Anchor   'Fixed Gear Gallery' `
    -AnchorIsLink $true

# 6c. Cave of Bones -> Science > Archaeology (after "Blue Mammoth Ivory Tusk")
Write-Host '  6c. Cave of Bones -> Science > Archaeology' -ForegroundColor White
Insert-MocLink -MocPath $sciMocPath `
    -LinkText 'Hawks-Berger-Cave of Bones' `
    -Anchor   'Blue Mammoth Ivory Tusk' `
    -AnchorIsLink $true

# 6d. Temples of The African Gods -> Science > Archaeology (after "Ukraine's Mammoth Bone Shelters")
Write-Host '  6d. Temples of The African Gods -> Science > Archaeology' -ForegroundColor White
$ukraineAnchor = "Ukraine" + [char]0x2019 + "s Mammoth Bone Shelters Were Used 18,000 Years Ago"
Insert-MocLink -MocPath $sciMocPath `
    -LinkText 'Tellinger-Temples of The African Gods' `
    -Anchor   $ukraineAnchor `
    -AnchorIsLink $true

# 6e. Two Winters in a Tipi -> fix truncated link in Travel MOC
Write-Host '  6e. Fix truncated Two Winters in a Tipi link' -ForegroundColor White
$f = Read-Utf8 $travelMocPath
if ($f.Text -match '\[\[Two Winters in a Tip\]\]') {
    $newText = $f.Text -replace '\[\[Two Winters in a Tip\]\]', '[[Two Winters in a Tipi]]'
    Write-Utf8 $travelMocPath $newText $f.HasBom
    Write-Host '  Fixed truncated link -> [[Two Winters in a Tipi]]' -ForegroundColor Green
} elseif ($f.Text -match '\[\[Two Winters in a Tipi\]\]') {
    Write-Host '  Already correct: [[Two Winters in a Tipi]]' -ForegroundColor DarkGray
} else {
    Insert-MocLink -MocPath $travelMocPath `
        -LinkText 'Two Winters in a Tipi' `
        -Anchor   'Bruzenak_et_al-Retire to an RV' `
        -AnchorIsLink $true
}

# 6f. HP Retiree Dave Packard -> NLP > Psychology & Behavior
Write-Host '  6f. HP Retiree Dave Packard -> NLP > Psychology & Behavior' -ForegroundColor White
Insert-MocLink -MocPath $nlpMocPath `
    -LinkText 'HP Retiree Dave Packard' `
    -Anchor   'The Johnson Treatment' `
    -AnchorIsLink $true

Write-Host ''
Write-Host '=== ALL FIXES COMPLETE ===' -ForegroundColor Green
