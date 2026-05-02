# discover_uhj.ps1
# Full inventory pass: finds all three problem types before any edits are made.
# Outputs a categorized report so the fix script can be built from known data.

$filePath = 'D:\Obsidian\Main\11 - Review\UHJ Nine Year Plan 2022-2031.md'
$text  = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
$lines = $text -split "`n"

# -----------------------------------------------------------------------
# SECTION 1: HYPHENATED WORDS (line-break artefacts)
# Only flag hyphens between two lowercase letter sequences — those are the
# candidates for PDF line-break hyphens.  Legitimate compound words like
# 'well-being', 'Abdu'l-Bah' etc. contain uppercase or apostrophes and
# are easily filtered by eye from this list.
# -----------------------------------------------------------------------
Write-Host '=== HYPHENATED WORDS (candidate line-break hyphens) ===' -ForegroundColor Cyan
$hyphenPattern = [regex]'[a-z]{2,}-[a-z]{2,}'
$hyphenMatches = @{}
foreach ($line in $lines) {
    $found = $hyphenPattern.Matches($line)
    foreach ($m in $found) {
        $word = $m.Value
        if (-not $hyphenMatches.ContainsKey($word)) { $hyphenMatches[$word] = 0 }
        $hyphenMatches[$word]++
    }
}
# Sort by frequency descending for easy review
$hyphenMatches.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    Write-Host ("  {0,-30} count={1}" -f $_.Name, $_.Value)
}

# -----------------------------------------------------------------------
# SECTION 2: LIGATURE-DROPPED WORDS
# These are words where 'tt', 'ff', 'fi', 'fl' ligatures were stripped,
# leaving truncated forms.  We test a dictionary of known bad->good pairs.
# -----------------------------------------------------------------------
Write-Host ''
Write-Host '=== LIGATURE-DROPPED WORDS (found in file) ===' -ForegroundColor Cyan

# Each entry: [broken form] = [correct form]
# Use array of pairs so PowerShell case-insensitive key collision is avoided.
# Each pair: @(broken, correct)
$ligatureChecks = @(
    # tt-ligature drops (most common in this document)
    @('aention',     'attention'),
    @('paern',       'pattern'),
    @('paerns',      'patterns'),
    @('seing',       'setting'),
    @('seings',      'settings'),
    @('wrien',       'written'),
    @('uerance',     'utterance'),
    @('uerances',    'utterances'),
    @('commied',     'committed'),
    @('commiment',   'commitment'),
    @('commiments',  'commitments'),
    @('beer',        'better'),
    @('beerment',    'betterment'),
    @('aacks',       'attacks'),
    @('puing',       'putting'),
    @('befiing',     'befitting'),
    @('befiingly',   'befittingly'),
    @('fiing',       'fitting'),
    @('fiingly',     'fittingly'),
    @('aained',      'attained'),
    @('aaining',     'attaining'),
    @('aainment',    'attainment'),
    @('aainments',   'attainments'),
    @('aitude',      'attitude'),
    @('aitudes',     'attitudes'),
    @('aempt',       'attempt'),
    @('aempts',      'attempts'),
    @('aempted',     'attempted'),
    @('aempting',    'attempting'),
    @('aend',        'attend'),
    @('aending',     'attending'),
    @('aended',      'attended'),
    @('aendance',    'attendance'),
    @('aributes',    'attributes'),
    @('aribute',     'attribute'),
    @('baered',      'battered'),
    # ff-ligature drops
    @('eort',        'effort'),
    @('eorts',       'efforts'),
    @('suicient',    'sufficient'),
    @('suiciently',  'sufficiently'),
    @('eect',        'effect'),
    @('eects',       'effects'),
    @('eective',     'effective'),
    @('eectively',   'effectively'),
    @('eectiveness', 'effectiveness')
)

foreach ($pair in $ligatureChecks) {
    $broken  = $pair[0]
    $correct = $pair[1]
    # Case-insensitive match with word boundaries
    $pattern = '(?i)\b' + [regex]::Escape($broken) + '\b'
    $count = ([regex]::Matches($text, $pattern)).Count
    if ($count -gt 0) {
        Write-Host ("  {0,-20} -> {1,-22} found {2}x" -f $broken, $correct, $count)
    }
}

# -----------------------------------------------------------------------
# SECTION 3: PARAGRAPH NUMBER PATTERNS
# Two sub-types:
#   A) Lines that START with a plain integer: "1 It is against..."
#   B) Lines that contain an embedded "N.M" number mid-text
# -----------------------------------------------------------------------
Write-Host ''
Write-Host '=== PARAGRAPH NUMBERS: START-OF-LINE (^digit space text) ===' -ForegroundColor Cyan
$startNumPattern = [regex]'^(\d+) (.+)'
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $startNumPattern) {
        $num  = $Matches[1]
        $preview = if ($Matches[2].Length -gt 80) { $Matches[2].Substring(0,80) + '...' } else { $Matches[2] }
        Write-Host ("  Line {0,4}: [{1}] {2}" -f ($i+1), $num, $preview)
    }
}

Write-Host ''
Write-Host '=== PARAGRAPH NUMBERS: EMBEDDED MID-TEXT (N.M pattern) ===' -ForegroundColor Cyan
$embedNumPattern = [regex]'\b(\d+\.\d+)\b'
for ($i = 0; $i -lt $lines.Count; $i++) {
    $found = $embedNumPattern.Matches($lines[$i])
    foreach ($m in $found) {
        # Skip lines that look like dates (e.g. "2022-2031") or ISBN
        if ($lines[$i] -notmatch 'ISBN|isbn|year|Year|\d{4}-\d{4}') {
            $start   = [Math]::Max(0, $m.Index - 40)
            $len     = [Math]::Min(100, $lines[$i].Length - $start)
            $context = $lines[$i].Substring($start, $len)
            Write-Host ("  Line {0,4}: [{1}] ...{2}..." -f ($i+1), $m.Value, $context)
        }
    }
}

Write-Host ''
Write-Host '=== DISCOVERY COMPLETE ===' -ForegroundColor Green
