# fix_people_index.ps1
# Fixes the People Index by:
# 1. Removing duplicate alphabet sections (keeping only the first full A-Z)
# 2. Removing non-person entries (food, NLP concepts, places, etc.)
# 3. Deduplicating person entries within each section

$path = 'D:\Obsidian\Main\People Index.md'
$lines = Get-Content $path -Encoding UTF8

# --- Step 1: Find where duplicates begin ---
# Find the SECOND occurrence of ## A to truncate at
$foundFirstA = $false
$secondA = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -eq '## A') {
        if (-not $foundFirstA) {
            $foundFirstA = $true
        } else {
            $secondA = $i
            break
        }
    }
}

Write-Host "Second ## A at line: $secondA"

# Keep only the first full A-Z block
if ($secondA -gt 0) {
    $coreLines = [System.Collections.ArrayList]($lines[0..($secondA - 1)])
    # Remove trailing blank lines
    while ($coreLines.Count -gt 0 -and $coreLines[$coreLines.Count - 1].Trim() -eq '') {
        $coreLines.RemoveAt($coreLines.Count - 1)
    }
} else {
    $coreLines = [System.Collections.ArrayList]$lines
}

Write-Host "Core lines after removing duplicates: $($coreLines.Count)"

# --- Step 2: List of false-positive names to remove (exact match after ### ) ---
$removeExact = [System.Collections.Generic.HashSet[string]]([StringComparer]::OrdinalIgnoreCase)
@(
    # Sentence fragments
    'Anything, anyone.',
    'From, this lahar material.',
    'Secondly, lot.',
    # NLP concepts
    'Constancy, Object',
    'Deletion, Comparative',
    'Development, Edu-K',
    'Differentiation, Early Sexual',
    'Direction, Attention',
    'Effect, Cause and ?',
    'Effect, Cocktail Party',
    'Equivalence, Complex ?',
    'Exploration, Criteria',
    'Factors, Decision',
    'Facts, Quick ?',
    'FAQ, NLP',
    'ID, Internet',
    'Logical, Alignment of',
    'LIFE, THE METAPHOR OF',
    'Links, Related',
    'Necessity, Modal Operator of',
    'NLP, which we evaluate ?',
    'Noun, Unspecified',
    'Of, On Behalf',
    'Orientation, Time',
    'Outcome, Meta ?',
    'Party, Parts',
    'Point, Anchor',
    'Possibility, Modal Operator of',
    'Postings, NLP Section',
    'Presupposition, Major',
    'Programmer-1, NLP for',
    'Programmers, NLP for',
    'Programmes, Quality Improvement',
    'Programming, Neuro-Linguistic',
    'Quantifier, Universal',
    'Rapport, V',
    'Reading, Mind',
    'Response, Stress',
    "Reveals, Subject's",
    'SCORE, using the',
    'Search, NLP Transderivational ?',
    'Search, T-D',
    'Search, TransDerivational ?',
    'Self, Apply to',
    'Self, Rapport with',
    'Size, Chunk',
    'Socialization, Early',
    'Strategy, Convincer',
    'Structure, Rule',
    'Studies, Using Data Case',
    'Thread, NLP Presupposition',
    'Therapy, Time Line ?',
    'Types, Three',
    'Verb, Unspecified',
    'World, NLP ?',
    # Learning/taxonomy
    "Learning, Bloom's Taxonomy of",
    # Food items
    'Brownie, Sweet Potato',
    'Brownies, Sweet Potato',
    'Dip, Spinach Artichoke',
    'Giuseppes, Sloppy',
    'Masala, Black-eyed Pea',
    'Sandwiches, Pepper Ridge',
    'Soup, Javanese-Inspired Chicken',
    'Recipe, Rava Idli',
    "Ring, Jo's",
    # Geographic
    'Floodwaters, Missoula',
    'Horn, Cape',
    'Lobe, Okanogan',
    'Monocline, the Coule',
    'RANCH, DALLES MOUNTAIN',
    'River, the Flathead',
    'Rock., then Steamboat',
    'Temple, Bahai',
    # Book/product titles (inverted)
    'Forward, Lessig-One Way',
    'Jesus, Boteach-Kosher',
    'Networking, Kurose-Ross-Computer',
    'Ones, Orona-The Brave',
    'Pyramid, Wilson-Inverting The',
    'Turing, Boyle-Alan',
    'Spinner, Samsonite Freeform Carry-on',
    'Utility, PKUNZIP',
    'NT, Microsoft Windows',
    'Productivity, Newport-Slow',
    'Inspiration, Earthships',
    'Fabulous, Finding the',
    'Ollama, installing',
    # System/admin entries
    'GCCMA:, ABOUT THE',
    'Helen, Remove Member',
    'INFORMATION:, OFFICE AND GATE',
    'List, AcSpreadSheetType',
    'Move, Outlook Macro',
    'Records, LGL Unsaved',
    'Team, Communications',
    'Season, Giving',
    'Sense, Corona Common',
    'Skin, Ancient Lizard',
    'Hearth, Home and',
    'Herring, Red',
    'Indian, This American',
    'In, What''s Wired ?',
    'Images, Wayne Talbot Tarot Card ?',
    'Joel, the way ?',
    'Marketing, Stan in',
    'Peace, World',
    'Up, Edu-K VAK Tune',
    # Malformed / duplicates with bad formatting
    'Bandler., Dilts modeling',
    'Cialdini., Robert',
    'Feldenkrais., Moshe ?',
    'Feldenkrais., Moshe',
    'III, Martin W. Brossman',
    'Dilbert:, Dogbert''s advice to',
    'Lavelle, Stever and john',
    'Menakem, LICSW Resmaa',
    'Foerster, Von',
    'Course, Comments About PhotoReading',
    'Bab, The',
    'La Valle, John J. ?',
    'Horst, Brian Van der',
    'Damme, Peter Van ?',
    'Overview, Bah??''? Faith',
    "Val?ry, Peter as Paul",
    'Valéry, Peter as Paul',
    'Paul, Valéry Peter as',
    'Paul, Val?ry Peter as'
) | ForEach-Object { [void]$removeExact.Add($_) }

# --- Step 3: Parse entries from the core lines ---
# Entries are: ### Name line + following non-### lines

# Collect entries per letter section
$sectionOrder = [System.Collections.Generic.List[string]]::new()  # preserve letter order
$sections = @{}  # letter -> list of @{Name; Lines[]}

$currentLetter = $null
$currentEntry = $null

foreach ($line in $coreLines) {
    if ($line -match '^## ([A-Z])$') {
        $currentLetter = $matches[1]
        if (-not $sections.ContainsKey($currentLetter)) {
            $sections[$currentLetter] = [System.Collections.Generic.List[hashtable]]::new()
            $sectionOrder.Add($currentLetter)
        }
    } elseif ($line -match '^### (.+)$') {
        # Save previous entry
        if ($null -ne $currentEntry -and $null -ne $currentLetter) {
            $sections[$currentLetter].Add($currentEntry)
        }
        $currentEntry = @{ Name = $matches[1]; Lines = [System.Collections.Generic.List[string]]::new() }
        $currentEntry.Lines.Add($line)
    } elseif ($null -ne $currentEntry) {
        $currentEntry.Lines.Add($line)
    }
}
# Save last entry
if ($null -ne $currentEntry -and $null -ne $currentLetter) {
    $sections[$currentLetter].Add($currentEntry)
}

Write-Host "Parsed sections: $($sections.Keys -join ', ')"

# --- Step 4: Remove false positives and deduplicate ---
$removedCount = 0
$dedupedCount = 0

foreach ($letter in @($sections.Keys)) {
    $entries = $sections[$letter]
    $cleaned = [System.Collections.Generic.List[hashtable]]::new()
    $seenNorm = @{}  # normalized name -> index in $cleaned

    foreach ($entry in $entries) {
        $name = $entry.Name

        # Check exact removal list
        if ($removeExact.Contains($name)) {
            Write-Host "  REMOVE: $name"
            $removedCount++
            continue
        }

        # Normalize for dedup: strip trailing ? ★ spaces and trailing dot
        $norm = $name -replace '\s*[★\?]\s*$', '' -replace '\.$', '' -replace '\s+', ' '
        $norm = $norm.Trim().ToLower()

        if ($seenNorm.ContainsKey($norm)) {
            $existingIdx = $seenNorm[$norm]
            $existing = $cleaned[$existingIdx]
            # Keep the entry with more content lines; prefer the one with ★
            $keepNew = $entry.Lines.Count -gt $existing.Lines.Count
            if ($keepNew) {
                Write-Host "  DEDUP replace: '$($existing.Name)' -> '$name'"
                $cleaned[$existingIdx] = $entry
                $seenNorm[$norm] = $existingIdx
            } else {
                Write-Host "  DEDUP skip: '$name' (keeping '$($existing.Name)')"
            }
            $dedupedCount++
        } else {
            $seenNorm[$norm] = $cleaned.Count
            $cleaned.Add($entry)
        }
    }

    $sections[$letter] = $cleaned
}

Write-Host ""
Write-Host "Removed $removedCount false positives"
Write-Host "Deduplicated $dedupedCount duplicate entries"

# --- Step 5: Find header block (before first ## A) ---
$headerLines = [System.Collections.Generic.List[string]]::new()
$inHeader = $true
foreach ($line in $coreLines) {
    if ($line -eq '## A') { $inHeader = $false; break }
    if ($inHeader) { $headerLines.Add($line) }
}

# --- Step 6: Rebuild file ---
$output = [System.Collections.Generic.List[string]]::new()
foreach ($line in $headerLines) { $output.Add($line) }

foreach ($letter in ($sectionOrder | Sort-Object)) {
    $entries = $sections[$letter]
    if ($entries.Count -eq 0) { continue }

    $output.Add('')
    $output.Add("## $letter")
    foreach ($entry in $entries) {
        # Trim trailing blank lines from each entry's lines
        $entryLines = [System.Collections.Generic.List[string]]($entry.Lines)
        while ($entryLines.Count -gt 0 -and $entryLines[$entryLines.Count - 1].Trim() -eq '') {
            $entryLines.RemoveAt($entryLines.Count - 1)
        }
        foreach ($l in $entryLines) { $output.Add($l) }
    }
}

# Write file
$outputText = $output -join "`n"
[System.IO.File]::WriteAllText($path, $outputText, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Done. Wrote $($output.Count) lines to People Index."
