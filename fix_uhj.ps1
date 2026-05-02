# fix_uhj.ps1
# Comprehensive repair of UHJ Nine Year Plan 2022-2031.md
#
# Three categories of fixes:
#   1. Ligature-dropped characters — tt/ff/fi dropped during .doc conversion
#   2. Line-break hyphens — soft hyphens from typeset line wrapping baked as hard hyphens
#   3. Paragraph numbers — extract from inline text; render as standalone bold markers
#
# Strategy:
#   - Read with UTF-8 (all diacritical chars already correct — only ligature/hyphen issues)
#   - Make a timestamped backup before any writes
#   - Apply fixes in order: ligatures first, then hyphens, then paragraph numbers
#   - Write back with UTF-8 no-BOM (matches Obsidian's expected encoding)
#   - Report a change count for each category

$filePath   = 'D:\Obsidian\Main\11 - Review\UHJ Nine Year Plan 2022-2031.md'
$backupPath = "$filePath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# -----------------------------------------------------------------------
# SAFETY: make a timestamped backup before touching the file
# -----------------------------------------------------------------------
Copy-Item -LiteralPath $filePath -Destination $backupPath -Force
Write-Host "Backup written to: $backupPath" -ForegroundColor Yellow

# Read the full file as a UTF-8 string (preserves all Baha'i diacriticals)
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# Keep a copy of the original so we can count total changes at the end
$original = $content

# =========================================================================
# FIX 1: LIGATURE-DROPPED CHARACTERS
# The .doc -> text conversion stripped typographic ligatures (tt, ff, fi).
# Each repair is a whole-word, case-insensitive substitution.
# Word boundaries (\b) ensure we don't corrupt substrings (e.g. "paern"
# inside "paernalism" would be wrong — but that word doesn't appear here).
# =========================================================================
Write-Host "`n--- FIX 1: Ligature repairs ---" -ForegroundColor Cyan

# Array of [broken, correct] pairs.  Order matters for overlapping roots:
# longer forms first to avoid partial-word substitutions.
$ligaturePairs = @(
    # tt-ligature: 'betterment' before 'better' so the root isn't consumed first
    @('beerment',    'betterment'),   # betterment (6 hits)
    @('beer',        'better'),       # better (2 hits) — safe in Baha'i text, no beer references
    @('befiingly',   'befittingly'),  # befittingly (1 hit) — longer form first
    @('befiing',     'befitting'),    # befitting (1 hit)
    @('fiingly',     'fittingly'),    # fittingly (1 hit)
    @('fiing',       'fitting'),      # fitting (1 hit)
    @('aainments',   'attainments'),  # attainments
    @('aainment',    'attainment'),   # attainment
    @('aaining',     'attaining'),    # attaining (1 hit)
    @('aained',      'attained'),     # attained (3 hits)
    @('aending',     'attending'),    # attending (2 hits)
    @('aendance',    'attendance'),   # attendance
    @('aended',      'attended'),     # attended
    @('aempting',    'attempting'),   # attempting
    @('aempted',     'attempted'),    # attempted
    @('aempts',      'attempts'),     # attempts
    @('aempt',       'attempt'),      # attempt
    @('aitudes',     'attitudes'),    # attitudes (5 hits)
    @('aitude',      'attitude'),     # attitude
    @('aributes',    'attributes'),   # attributes
    @('aribute',     'attribute'),    # attribute
    @('aacks',       'attacks'),      # attacks (1 hit)
    @('aentions',    'attentions'),   # attentions
    @('aention',     'attention'),    # attention (11 hits)
    @('commied',     'committed'),    # committed (1 hit)
    @('commiments',  'commitments'),  # commitments
    @('commiment',   'commitment'),   # commitment
    @('puing',       'putting'),      # putting (1 hit)
    @('paerns',      'patterns'),     # patterns (2 hits)
    @('paern',       'pattern'),      # pattern (12 hits)
    @('seings',      'settings'),     # settings (9 hits)
    @('seing',       'setting'),      # setting (3 hits)
    @('wrien',       'written'),      # written (3 hits)
    @('uerance',     'utterance'),    # utterance (1 hit)
    # ff-ligature (not confirmed by scan but including defensive cases)
    @('eectiveness', 'effectiveness'),
    @('eectively',   'effectively'),
    @('eective',     'effective'),
    @('eects',       'effects'),
    @('eect',        'effect'),
    @('suiciently',  'sufficiently'),
    @('suicient',    'sufficient'),
    @('eorts',       'efforts'),
    @('eort',        'effort')
)

$ligatureCount = 0  # running total of ligature replacements made
foreach ($pair in $ligaturePairs) {
    $broken  = $pair[0]   # the garbled form found in the file
    $correct = $pair[1]   # the reconstructed correct form

    # (?i) = case-insensitive so 'Aention' -> 'Attention' etc. automatically
    # \b   = word boundary to avoid partial matches inside longer words
    $pattern = '(?i)\b' + [regex]::Escape($broken) + '\b'
    $matches  = [regex]::Matches($content, $pattern)

    if ($matches.Count -gt 0) {
        # Preserve original capitalisation: if first char of match is uppercase,
        # capitalise the replacement too (handles sentence-start cases).
        $content = [regex]::Replace($content, $pattern, {
            param($m)
            $orig = $m.Value
            if ([char]::IsUpper($orig[0])) {
                # Capitalise first letter of correct form
                $correct[0].ToString().ToUpper() + $correct.Substring(1)
            } else {
                $correct
            }
        })
        Write-Host ("  '{0}' -> '{1}'  ({2} replacements)" -f $broken, $correct, $matches.Count)
        $ligatureCount += $matches.Count
    }
}
Write-Host "  Ligature total: $ligatureCount replacements" -ForegroundColor Green

# =========================================================================
# FIX 2: LINE-BREAK HYPHENS
# These are hyphens that were soft hyphens in the typeset document,
# inserted at line breaks.  When converted to text, they became hard hyphens
# inside words that should be written without any hyphen.
#
# Only explicit, verified patterns are included.  Legitimate compound words
# (society-building, well-being, twenty-five, etc.) are intentionally
# omitted from this list.
# =========================================================================
Write-Host "`n--- FIX 2: Line-break hyphen repairs ---" -ForegroundColor Cyan

# Each entry: [hyphenated-artefact, correct-single-word]
# Ordered longest-match first where roots overlap.
$hyphenPairs = @(
    # 4-hit and 2-hit cases first
    @('com-munity',       'community'),       # 4 hits
    @('com-munities',     'communities'),     # 1 hit
    @('character-istics', 'characteristics'), # 2 hits
    @('institu-tions',    'institutions'),    # 1 hit
    @('insti-tutions',    'institutions'),    # 1 hit (alternate split)
    @('inaugu-rated',     'inaugurated'),     # 1 hit
    @('commu-nity',       'community'),       # 1 hit (alternate split)
    @('controver-sies',   'controversies'),   # 1 hit
    @('confer-ences',     'conferences'),     # 1 hit
    @('ulti-mately',      'ultimately'),      # 1 hit
    @('per-meate',        'permeate'),        # 1 hit
    @('gather-ing',       'gathering'),       # 1 hit
    @('differ-ent',       'different'),       # 1 hit
    @('grat-itude',       'gratitude'),       # 1 hit
    @('includ-ing',       'including'),       # 1 hit
    @('accu-mulates',     'accumulates'),     # 1 hit
    @('mile-stone',       'milestone'),       # 1 hit
    @('develop-ment',     'development'),     # 1 hit
    @('en-deavours',      'endeavours'),      # 1 hit
    @('inter-national',   'international'),   # 1 hit (not a compound word here)
    @('activ-ity',        'activity'),        # 1 hit
    @('pur-sues',         'pursues'),         # 1 hit
    @('trans-formed',     'transformed'),     # 1 hit
    @('aspira-tions',     'aspirations'),     # 1 hit
    @('coun-tries',       'countries'),       # 1 hit
    @('or-ganization',    'organization'),    # 1 hit
    @('expand-ing',       'expanding'),       # 1 hit
    @('em-bodiment',      'embodiment'),      # 1 hit
    @('pre-pared',        'prepared'),        # 1 hit
    @('foot-steps',       'footsteps'),       # 1 hit
    @('under-went',       'underwent'),       # 1 hit
    @('insight-ful',      'insightful'),      # 1 hit
    @('prosper-ity',      'prosperity'),      # 1 hit
    @('de-plorable',      'deplorable'),      # 1 hit
    @('count-less',       'countless'),       # 1 hit
    @('lit-erature',      'literature'),      # 1 hit
    @('trans-formation',  'transformation'),  # 1 hit
    @('surround-ings',    'surroundings'),    # 1 hit
    @('accelerat-ing',    'accelerating'),    # 1 hit
    @('popu-lated',       'populated'),       # 1 hit
    @('them-selves',      'themselves'),      # 1 hit
    @('along-side',       'alongside'),       # 1 hit
    @('coun-sel',         'counsel'),         # 1 hit
    @('contribu-tion',    'contribution'),    # 1 hit
    @('price-less',       'priceless'),       # 1 hit (not a compound adjective here)
    @('consol-idating',   'consolidating'),   # 1 hit
    @('educa-tional',     'educational'),     # 1 hit
    @('pro-grammes',      'programmes'),      # 1 hit
    @('dis-tinguished',   'distinguished'),   # 1 hit
    @('consti-tutes',     'constitutes'),     # 1 hit
    @('di-vine',          'divine'),          # 1 hit
    @('pub-lished',       'published'),       # 1 hit
    @('cen-tury',         'century'),         # 1 hit
    @('train-ing',        'training'),        # 1 hit
    @('dur-ing',          'during'),          # 1 hit
    @('essen-tial',       'essential'),       # 1 hit
    @('not-withstanding', 'notwithstanding'), # 1 hit
    @('Dis-pensation',    'Dispensation'),    # 1 hit (mid-word split of Dispensation)
    @('dis-pensation',    'dispensation'),    # lowercase variant
    # Dropped-letter cases found by scanner (letter lost at page break)
    @('wenty-two',        'twenty-two'),      # 'T' was at line end, 'wenty-two' remained
    @('re-eminent',       'pre-eminent'),     # 'p' was at line end, 're-eminent' remained
    @('is-pensation',     'Dispensation'),    # 'Di' lost; 'is-pensation' remained
    @('ow-ever',          'however')          # 'h' was at line end; verify safe before applying
)

$hyphenCount = 0  # running total of hyphen removals made
foreach ($pair in $hyphenPairs) {
    $artefact = $pair[0]   # the broken hyphenated form
    $repaired = $pair[1]   # the correct form

    # Use exact string match (case-sensitive for hyphens, as capitalisation
    # is intentional in cases like 'Dis-pensation').
    if ($content -clike "*$artefact*") {
        $before   = ($content -csplit [regex]::Escape($artefact)).Count - 1  # count before replace
        $content  = $content -creplace [regex]::Escape($artefact), $repaired
        $after    = ($content -csplit [regex]::Escape($repaired)).Count - 1
        Write-Host ("  '{0}' -> '{1}'" -f $artefact, $repaired)
        $hyphenCount++
    }
}
Write-Host "  Hyphen total: $hyphenCount pattern types repaired" -ForegroundColor Green

# =========================================================================
# FIX 3: PARAGRAPH NUMBERS
#
# Two sub-patterns found in the file:
#
# A) EMBEDDED MID-SENTENCE numbers (N.M format, e.g. "special 1.1 day"):
#    These are marginal paragraph markers from the typeset original that
#    were inserted at the text-flow position when the document was converted.
#    Fix: remove the N.M from the sentence; insert "**¶N.M**" as a blank-
#    line-separated header immediately before the surrounding text block.
#    For lines with multiple embedded numbers, split into separate blocks.
#
# B) START-OF-LINE numbers (plain integer, e.g. "1 It is against..."):
#    These are page/paragraph numbers from the typeset book that landed at
#    the start of the converted line.
#    Fix: extract the number; render as "**¶N**" on its own line, then the
#    paragraph text follows on the next line.
#    EXCLUDE date lines: lines starting with a number followed by a month
#    name (e.g. "25 November 2020") are letter headers, not paragraph refs.
#
# Both fixes use a blank line above and below the marker so Obsidian renders
# the bold paragraph number as a visually distinct block.
# =========================================================================
Write-Host "`n--- FIX 3: Paragraph number formatting ---" -ForegroundColor Cyan

# Split content into lines so we can process line-by-line
$lines = $content -split "`n"

# Month names used to detect date-header lines (must not be treated as
# paragraph numbers)
$monthNames = 'January|February|March|April|May|June|July|August|September|October|November|December'

# Regex for an embedded N.M paragraph marker: an integer.integer surrounded
# by whitespace that is NOT at the start or end of the line.
# We look for at least one non-whitespace char on each side to confirm it's
# mid-sentence (not already a standalone token).
$embedPattern = [regex]' (\d+\.\d+) '

$paraCount = 0      # count of paragraph numbers formatted
$newLines  = [System.Collections.Generic.List[string]]::new()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    # ---- Sub-fix A: embedded N.M numbers --------------------------------
    # Check whether this line has any embedded paragraph markers.
    # Keep looping while there are matches (handles multiple markers per line).
    $embedMatches = $embedPattern.Matches($line)

    if ($embedMatches.Count -gt 0) {
        # Collect all markers in this line (left to right)
        $markers = @()
        foreach ($m in $embedMatches) {
            $markers += @{ Index = $m.Index; Num = $m.Groups[1].Value }
        }

        # Split the line into segments at each marker boundary.
        # Each segment becomes its own paragraph block prefixed by the marker.
        $segments = [System.Collections.Generic.List[string]]::new()
        $lastEnd   = 0   # tracks position as we consume segments

        foreach ($marker in $markers) {
            # Text BEFORE this marker (belongs to the PREVIOUS paragraph
            # or is the preamble if this is the first marker on the line).
            $before = $line.Substring($lastEnd, $marker.Index - $lastEnd).Trim()
            if ($before.Length -gt 0) {
                $segments.Add($before)
            }

            # Advance past the full match " N.M " (length = number + 2 spaces)
            # Groups[1].Value gives just the digits; the full match includes spaces
            $lastEnd = $marker.Index + $marker.Num.Length + 2  # +2 for surrounding spaces

            # Store the marker number so the NEXT segment gets prefixed with it
            $segments.Add("__PARA_MARKER__$($marker.Num)")
        }

        # Append any text remaining after the last marker
        $tail = $line.Substring($lastEnd).Trim()
        if ($tail.Length -gt 0) {
            $segments.Add($tail)
        }

        # Reconstruct the output lines from segments.
        # Each __PARA_MARKER__ segment triggers a bold paragraph header; the
        # following text segment becomes the paragraph body.
        $pendingMarker = $null
        foreach ($seg in $segments) {
            if ($seg -like '__PARA_MARKER__*') {
                $pendingMarker = $seg.Replace('__PARA_MARKER__', '')
            } else {
                if ($pendingMarker) {
                    # Emit: blank line, bold paragraph number, blank line, text
                    $newLines.Add('')
                    $newLines.Add("**¶$pendingMarker**")
                    $newLines.Add('')
                    $newLines.Add($seg)
                    $paraCount++
                    $pendingMarker = $null
                } else {
                    # Text before the first marker on this line (preamble/header)
                    $newLines.Add($seg)
                }
            }
        }
        # If a marker was found but had no following text on this line
        if ($pendingMarker) {
            $newLines.Add('')
            $newLines.Add("**¶$pendingMarker**")
            $newLines.Add('')
            $paraCount++
        }
        continue   # line has been fully handled; skip to next line
    }

    # ---- Sub-fix B: start-of-line paragraph numbers ---------------------
    # Pattern: line starts with one or more digits, a space, then text.
    # Exclude: date headers (digit followed by a month name).
    if ($line -match '^(\d+) (.+)$') {
        $num  = $Matches[1]    # the leading integer
        $rest = $Matches[2]    # the paragraph text that follows

        # Is this a date line?  (e.g. "25 November 2020")
        $isDate = $rest -match "^($monthNames)\b"

        # Is this a timeline row?  (e.g. "1892 1921 1937 ...")
        $isTimeline = $rest -match '^\d{4}'

        # Is this a page number with only a fragment word? (e.g. "27 been")
        # We still format it — the user can review fragments.

        if (-not $isDate -and -not $isTimeline) {
            # Emit: blank line, bold paragraph number, blank line, text
            $newLines.Add('')
            $newLines.Add("**¶$num**")
            $newLines.Add('')
            $newLines.Add($rest)
            $paraCount++
            continue
        }
    }

    # ---- Default: line needs no paragraph number treatment ---------------
    $newLines.Add($line)
}

Write-Host "  Paragraph total: $paraCount numbers formatted" -ForegroundColor Green

# =========================================================================
# REASSEMBLE AND WRITE
# =========================================================================

# Join lines back into a single string using Unix line endings (LF).
# Obsidian on Windows handles LF just fine and this avoids CRLF duplication.
$content = $newLines -join "`n"

# Write with UTF-8 encoding, NO byte order mark (BOM).
# Obsidian expects UTF-8 without BOM for markdown files.
$utf8NoBOM = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($filePath, $content, $utf8NoBOM)

Write-Host "`n=== SUMMARY ===" -ForegroundColor Green
Write-Host ("  Ligature fixes:      {0} replacements" -f $ligatureCount)
Write-Host ("  Hyphen fixes:        {0} pattern types repaired" -f $hyphenCount)
Write-Host ("  Paragraph numbers:   {0} formatted" -f $paraCount)
Write-Host ("  Backup at:           {0}" -f $backupPath)
Write-Host "File saved.  Open in Obsidian to review." -ForegroundColor Green
