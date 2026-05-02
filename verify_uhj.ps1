# verify_uhj.ps1
# Spot-check the fixed file against known before/after expectations.
# Reports: residual broken forms, sample of paragraph markers, encoding integrity.

$filePath = 'D:\Obsidian\Main\11 - Review\UHJ Nine Year Plan 2022-2031.md'
$text  = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
$lines = $text -split "`n"

# -----------------------------------------------------------------------
# CHECK 1: Residual broken ligature forms (should all be zero)
# -----------------------------------------------------------------------
Write-Host '=== RESIDUAL LIGATURE FORMS (all should be 0) ===' -ForegroundColor Cyan
$residuals = @(
    'aention','paern','paerns','seing','seings','wrien','uerance',
    'commied','beer','beerment','aacks','puing','befiing','befiingly',
    'fiing','aained','aaining','aitudes','aending'
)
$allClear = $true
foreach ($r in $residuals) {
    $count = ([regex]::Matches($text, '(?i)\b' + [regex]::Escape($r) + '\b')).Count
    if ($count -gt 0) {
        Write-Host ("  STILL PRESENT: '{0}' found {1}x" -f $r, $count) -ForegroundColor Red
        $allClear = $false
    }
}
if ($allClear) { Write-Host "  All ligature forms cleared." -ForegroundColor Green }

# -----------------------------------------------------------------------
# CHECK 2: Residual line-break hyphens (spot-check top candidates)
# -----------------------------------------------------------------------
Write-Host ''
Write-Host '=== RESIDUAL LINE-BREAK HYPHENS (spot-check) ===' -ForegroundColor Cyan
$hyphenCheck = @(
    'com-munity','paern','confer-ences','ulti-mately','per-meate',
    'gather-ing','differ-ent','controver-sies','inaugu-rated','institu-tions'
)
$allClear2 = $true
foreach ($h in $hyphenCheck) {
    if ($text -match [regex]::Escape($h)) {
        Write-Host ("  STILL PRESENT: '{0}'" -f $h) -ForegroundColor Red
        $allClear2 = $false
    }
}
if ($allClear2) { Write-Host "  All spot-checked hyphens cleared." -ForegroundColor Green }

# -----------------------------------------------------------------------
# CHECK 3: Paragraph markers — show the first 25 for visual review
# -----------------------------------------------------------------------
Write-Host ''
Write-Host '=== FIRST 25 PARAGRAPH MARKERS IN FILE ===' -ForegroundColor Cyan
$markerCount = 0
for ($i = 0; $i -lt $lines.Count -and $markerCount -lt 25; $i++) {
    if ($lines[$i] -match '^\*\*¶') {
        # Show the marker line and the first 70 chars of the following text line
        $markerLine = $lines[$i]
        $textLine   = ''
        for ($j = $i+1; $j -lt [Math]::Min($i+4, $lines.Count); $j++) {
            if ($lines[$j].Trim().Length -gt 0) {
                $textLine = $lines[$j].Substring(0, [Math]::Min(70, $lines[$j].Length))
                break
            }
        }
        Write-Host ("  {0,-15}  -> {1}..." -f $markerLine, $textLine)
        $markerCount++
    }
}
Write-Host "  (Total paragraph markers: $(([regex]::Matches($text, '^\*\*¶', 'Multiline')).Count))" -ForegroundColor Green

# -----------------------------------------------------------------------
# CHECK 4: Encoding integrity — diacritical counts unchanged
# -----------------------------------------------------------------------
Write-Host ''
Write-Host '=== DIACRITICAL CHARACTER COUNTS (should match original) ===' -ForegroundColor Cyan
$charCounts = @{}
foreach ($c in $text.ToCharArray()) {
    $cp = [int]$c
    if ($cp -gt 127) {
        $key = 'U+{0:X4}' -f $cp
        if (-not $charCounts[$key]) { $charCounts[$key] = 0 }
        $charCounts[$key]++
    }
}
# Show the key Baha'i diacriticals
foreach ($key in @('U+00E1','U+00ED','U+1E0D','U+1E24','U+00FA')) {
    Write-Host ("  {0}: {1}" -f $key, $charCounts[$key])
}

# -----------------------------------------------------------------------
# CHECK 5: Sample a few corrected words in context
# -----------------------------------------------------------------------
Write-Host ''
Write-Host '=== SAMPLE CORRECTIONS IN CONTEXT ===' -ForegroundColor Cyan
$samples = @('attention','pattern','settings','written','betterment','community','notwithstanding')
foreach ($word in $samples) {
    $m = [regex]::Match($text, "(?i).{0,30}\b$word\b.{0,30}")
    if ($m.Success) {
        Write-Host ("  ...{0}..." -f $m.Value)
    }
}
