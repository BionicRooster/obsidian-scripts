#Requires -Version 5.0
# rebuild_people_index.ps1
# Rebuilds the People Index for the Obsidian vault.
# Scans all .md files for person names in frontmatter and wikilinks to 15 - People.
# Writes output to C:\Users\awt\Sync\Obsidian\People Index.md in UTF-8 (no BOM).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ─── Configuration ────────────────────────────────────────────────────────────

# Root of the Obsidian vault
$VaultRoot = 'C:\Users\awt\Sync\Obsidian'

# Output file path
$OutputFile = Join-Path $VaultRoot 'People Index.md'

# Folder containing dedicated person notes (relative to vault root)
$PeopleFolder = Join-Path $VaultRoot '15 - People'

# Folders to exclude from scanning (matched against relative path segment)
$ExcludedFolders = @(
    '00 - Home Dashboard',
    '.obsidian',
    '.trash',
    '00 - Images',
    'Templates'
)

# YAML frontmatter fields that may contain person names
$AuthorFields = @('author', 'authors', 'by', 'person', 'people')

# Maximum character length for a value to be considered a valid name
$MaxNameLength = 50

# ─── False-positive filter lists ──────────────────────────────────────────────

# Values that are clearly not person names (case-insensitive exact match after trim)
$IgnoredValues = [System.Collections.Generic.HashSet[string]] @(
    'n/a', 'unknown', 'anonymous', 'various', 'multiple', 'staff',
    'admin', 'administrator', 'editor', 'editors', 'the editors', 'from the editors',
    'guest', 'contributor', 'contributors', 'source', 'sources',
    'none', 'null', 'true', 'false', 'yes', 'no',
    'the', 'and', 'or', 'but', 'not', 'greynoise labs'
)

# Surname blocklist: words that look like surnames but are really concepts, brands, or labels.
# Checked against the first token before the comma in "Last, First" formatted names.
$SurnameBlocklist = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
'acuity','activity','alliance','anchor','anchors','behavior','belief','beliefs',
'calibrate','check','choices','client','collapse','committee','concept','concepts',
'conditions','cure','cures','desk','directory','dish','ecology','effect','effects',
'eliciting','factor','factors','faq','fee','flexibility','following','forum',
'framework','function','guide','herbivore','history','honor','index','insight',
'insights','instructables','keyword','layer','leaf','level','levels','lifewire',
'light','loop','man','maps','mechanism','meta','model','models','number',
'outcomes','park','patterns','planet','point','principle','principles',
'publishing','ranch','rapport','reclamation','reframe','reframing','repair',
'report','resource','resources','review','sam','scitech','sciencedaily','search',
'sensory','sketchplanations','skills','society','stove','state','states','subject',
'technology','techniques','therapy','thinking','training','university','user',
'valley','venice','voice','washing','way','ways','weblog','workshop','world' |
    ForEach-Object { [void]$SurnameBlocklist.Add($_) }

# Load validated surnames from the clean People Index (if file exists)
# These are known-good surnames; the file is updated each time the index is cleaned.
$KnownSurnames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$knownSurnamesPath = 'C:\Users\awt\known_surnames.txt'
if (Test-Path $knownSurnamesPath) {
    Get-Content $knownSurnamesPath -Encoding UTF8 | Where-Object { $_ -match '\S' } |
        ForEach-Object { [void]$KnownSurnames.Add($_.Trim()) }
}

# Load validated first names (supplements tblNameGender.csv)
$KnownFirstNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$knownFirstNamesPath = 'C:\Users\awt\known_firstnames.txt'
if (Test-Path $knownFirstNamesPath) {
    Get-Content $knownFirstNamesPath -Encoding UTF8 | Where-Object { $_ -match '\S' } |
        ForEach-Object { [void]$KnownFirstNames.Add($_.Trim()) }
}

# ─── Helper: Test if a string should be excluded as a non-name ────────────────
# NOTE: PowerShell regex is case-insensitive by default.
# Use (?-i) prefix inside pattern to force case-sensitive matching.
function Test-IsNotAName {
    param([string]$Value)

    # Strip outer quotes and whitespace (already done by caller, but be safe)
    $v = $Value.Trim()

    # Empty after stripping
    if ([string]::IsNullOrWhiteSpace($v)) { return $true }

    # Too long to be a personal name
    if ($v.Length -gt $MaxNameLength) { return $true }

    # Must contain at least one letter (Unicode letter)
    if ($v -notmatch '\p{L}') { return $true }

    # Must start with an uppercase letter (use (?-i) to force case-sensitive)
    # This filters out: lowercase-leading values like "true", "none", etc.
    # But allows: proper names like "David", "Sönke", accented capitals
    if ($v -notmatch '(?-i)^\p{Lu}') { return $true }

    # Exact match against known non-name values (case-insensitive)
    if ($IgnoredValues.Contains($v.ToLower())) { return $true }

    # URL patterns
    if ($v -match '^https?://') { return $true }

    # Domain-like strings
    if ($v -match '\.(com|org|net|edu|gov|io|md)(/|$)') { return $true }

    # Email address
    if ($v -match '@') { return $true }

    # Contains pipe (wikilink alias marker — should have been stripped already)
    if ($v -match '\|') { return $true }

    # Pure numbers
    if ($v -match '^\d+$') { return $true }

    # Contains " and " — likely a merged multi-author string (e.g. "John Smith and Jane Doe")
    if ($v -match '\band\b') { return $true }

    # Contains a forward slash — likely a merged or garbled value
    if ($v -match '/') { return $true }

    # Check surname blocklist for "Last, First" format
    if ($v -match '^([^,]+),') {
        $surname = $matches[1].Trim()
        if ($SurnameBlocklist.Contains($surname)) { return $true }
    }

    # Surname ends in -ing, -tion, -ness, -ment, -ology (concept word patterns)
    # Real surnames virtually never end this way
    if ($v -match '^([^,\s]+)') {
        $firstToken = $matches[1] -replace '[^\p{L}]', ''
        if ($firstToken -match '(?i)(ing|tion|ness|ment|ology|izing|ified|ifying|ated|ating)$') {
            return $true
        }
    }

    # Contains ASIN product codes (e.g. "asin: B0ABC123DE" or starts with B0 followed by digits)
    if ($v -match 'asin:|(?i)\bB[0-9A-Z]{9}\b') { return $true }

    # Credentials embedded in name (MS, RD, PhD, MD, LICSW, etc.)
    if ($v -match '\b(MS|RD|PhD|MD|LICSW|MSW|RN|DO|DDS|JD|Esq|Instructor|Prof)\b') { return $true }

    return $false
}

# ─── Helper: Convert "First Last" → "Last, First" ─────────────────────────────
# Handles:
#   "First Last"         -> "Last, First"
#   "First Middle Last"  -> "Last, First Middle"
#   "Last, First"        -> "Last, First"  (unchanged)
#   "SingleName"         -> "SingleName"   (unchanged)
#   "[[WikiLink]]"       -> extract name then convert
function ConvertTo-LastFirst {
    param([string]$Name)

    # Strip wikilink brackets: [[Name]] or [[Name|Alias]] → Name
    $n = $Name -replace '^\[\[(.+?)(\|.+?)?\]\]$', '$1'

    # Strip surrounding quotes
    $n = $n.Trim().Trim('"').Trim("'").Trim()

    # Already "Last, First" format (contains a comma)
    if ($n -match '^[^,]+,\s*.+$') { return $n }

    # Split on whitespace
    $parts = $n -split '\s+'

    # Single word — return as-is
    if ($parts.Count -le 1) { return $n }

    # "First [Middle...] Last" → "Last, First [Middle...]"
    $last  = $parts[-1]
    $first = ($parts[0..($parts.Count - 2)]) -join ' '
    return "$last, $first"
}

# ─── Helper: Parse YAML frontmatter block ─────────────────────────────────────
# Returns a hashtable: fieldname (lowercase) -> [string[]] of values
function Get-FrontmatterValues {
    param([string[]]$Lines)

    # Find the frontmatter block (between first pair of --- lines)
    $start = -1
    $end   = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $trimmed = $Lines[$i].Trim()
        if ($trimmed -eq '---') {
            if ($start -eq -1) { $start = $i; continue }
            else                { $end   = $i; break }
        }
        # If first non-empty, non-BOM line is not ---, there's no frontmatter
        if ($start -eq -1 -and $trimmed -ne '' -and $trimmed -ne [char]0xFEFF) { break }
    }

    # No valid frontmatter found
    if ($start -eq -1 -or $end -eq -1) { return @{} }

    # Parse key-value pairs within frontmatter
    $result     = @{}
    $currentKey = $null

    for ($i = ($start + 1); $i -lt $end; $i++) {
        $line = $Lines[$i]

        # YAML list item: "  - value"
        if ($null -ne $currentKey -and $line -match '^\s+-\s+(.*)$') {
            $val = $Matches[1].Trim().Trim('"').Trim("'")
            $result[$currentKey] += @($val)
            continue
        }

        # Key: value  or  Key:  (with optional inline list)
        if ($line -match '^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$') {
            $key  = $Matches[1].ToLower()
            $val  = $Matches[2].Trim().Trim('"').Trim("'")
            $currentKey = $key

            if (-not $result.ContainsKey($key)) {
                $result[$key] = @()
            }

            # Inline list: key: [val1, val2]
            if ($val -match '^\[(.+)\]$') {
                $items = $Matches[1] -split ',\s*'
                foreach ($item in $items) {
                    $result[$key] += @($item.Trim().Trim('"').Trim("'"))
                }
            }
            elseif ($val -ne '') {
                # Single scalar value on the same line
                $result[$key] += @($val)
            }
            # If empty, subsequent list items will be captured above
            continue
        }

        # Non-matching line resets context (e.g., nested YAML we don't handle)
        if ($line -notmatch '^\s') {
            $currentKey = $null
        }
    }

    return $result
}

# ─── Step 1: Build set of people who have dedicated notes in 15 - People ──────
Write-Host 'Step 1: Scanning 15 - People folder for dedicated notes...'

# Map: note stem (filename without .md) -> $true, for quick lookup
$PeopleNoteNames = @{}

if (Test-Path $PeopleFolder) {
    $peopleFiles = Get-ChildItem $PeopleFolder -Filter '*.md' -File
    foreach ($pf in $peopleFiles) {
        # Skip the folder index note itself
        if ($pf.BaseName -eq '15 - People') { continue }
        $PeopleNoteNames[$pf.BaseName] = $true
    }
}

Write-Host "  Found $($PeopleNoteNames.Count) dedicated person notes."

# ─── Step 2: Collect all vault .md files, apply exclusions ────────────────────
Write-Host 'Step 2: Collecting vault files...'

$allFiles = Get-ChildItem $VaultRoot -Recurse -Filter '*.md' -File | Where-Object {
    $fullPath = $_.FullName

    # Exclude the output file itself
    if ($fullPath -eq $OutputFile) { return $false }

    # Compute path relative to vault root for folder matching
    $relative = $fullPath.Substring($VaultRoot.Length + 1)

    $excluded = $false
    foreach ($excl in $ExcludedFolders) {
        # Match folder name as a segment anywhere in the relative path
        if ($relative -like "$excl*" -or $relative -like "*\$excl\*" -or $relative -like "*\$excl") {
            $excluded = $true
            break
        }
    }
    return (-not $excluded)
}

Write-Host "  Found $($allFiles.Count) files to scan."

# ─── Step 3: Main scan loop ───────────────────────────────────────────────────
# Data structure:
#   $PersonIndex = @{
#       "Last, First" = @{
#           SourceFiles = [HashSet[string]]  - stems of files referencing this person
#           HasNote     = $true/$false
#           NoteName    = stem of the .md in 15 - People (for wikilink display)
#       }
#   }

Write-Host 'Step 3: Scanning files for person names...'

# Main registry: normalized "Last, First" key -> entry hashtable
$PersonIndex = @{}

# ─── Inner function: add one person to the index ──────────────────────────────
function Register-Person {
    param(
        [string]$RawName,    # The name as found (may be wikilink, "First Last", etc.)
        [string]$SourceFile  # Stem (filename without .md) of the referencing file
    )

    # Strip wikilink brackets: [[Name]] or [[Name|Alias]] -> Name
    $clean = $RawName -replace '^\[\[(.+?)(\|.+?)?\]\]$', '$1'
    $clean = $clean.Trim().Trim('"').Trim("'").Trim()

    # Run through exclusion filter
    if (Test-IsNotAName $clean) { return }

    # Normalize to "Last, First"
    $normalized = ConvertTo-LastFirst $clean

    # Final exclusion check after normalization
    if (Test-IsNotAName $normalized) { return }

    # Determine if this person has a dedicated note in 15 - People.
    $hasNote  = $false
    $noteName = $null

    # Check if the clean (unformatted) name matches a people note stem exactly
    if ($PeopleNoteNames.ContainsKey($clean)) {
        $hasNote  = $true
        $noteName = $clean
    }

    # Check if any people note stem, when normalized, matches our normalized name
    if (-not $hasNote) {
        foreach ($stem in $PeopleNoteNames.Keys) {
            if ((ConvertTo-LastFirst $stem) -eq $normalized) {
                $hasNote  = $true
                $noteName = $stem
                break
            }
        }
    }

    # Register or update the person entry
    if (-not $PersonIndex.ContainsKey($normalized)) {
        $PersonIndex[$normalized] = @{
            SourceFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            HasNote     = $hasNote
            NoteName    = $noteName
        }
    }

    # Merge note info if this call newly discovered the note link
    if ($hasNote -and (-not $PersonIndex[$normalized].HasNote)) {
        $PersonIndex[$normalized].HasNote  = $true
        $PersonIndex[$normalized].NoteName = $noteName
    }

    # Record the source file (deduplicated by HashSet)
    if (-not [string]::IsNullOrWhiteSpace($SourceFile)) {
        [void]$PersonIndex[$normalized].SourceFiles.Add($SourceFile)
    }
}

# ─── Scan each file ──────────────────────────────────────────────────────────
$scanned = 0

foreach ($file in $allFiles) {
    $scanned++
    if ($scanned % 200 -eq 0) {
        Write-Host "  Scanned $scanned / $($allFiles.Count) files..."
    }

    # Read file content using .NET StreamReader for reliable UTF-8 handling (including BOM)
    $content = $null
    try {
        $reader  = [System.IO.StreamReader]::new($file.FullName, [System.Text.Encoding]::UTF8)
        $content = $reader.ReadToEnd()
        $reader.Close()
        $reader.Dispose()
    }
    catch {
        Write-Warning ("Could not read: " + $file.FullName + " - " + $_.Exception.Message)
        continue
    }

    # Split content into lines for frontmatter parsing
    $lines    = $content -split "`r?`n"
    $fileStem = $file.BaseName   # Display name (filename without .md extension)

    # ── A. Extract names from YAML frontmatter author-type fields ──────────
    $fm = Get-FrontmatterValues -Lines $lines

    foreach ($field in $AuthorFields) {
        if ($fm.ContainsKey($field)) {
            foreach ($val in $fm[$field]) {
                if (-not [string]::IsNullOrWhiteSpace($val)) {
                    Register-Person -RawName $val -SourceFile $fileStem
                }
            }
        }
    }

    # ── B. Extract wikilinks in the body that point to 15 - People notes ──
    # Only wikilinks whose target matches a known people note stem are counted.

    # Locate where the frontmatter ends so we only scan the body
    $bodyStart = 0
    $dashCount = 0
    for ($li = 0; $li -lt $lines.Count; $li++) {
        if ($lines[$li].Trim() -eq '---') {
            $dashCount++
            if ($dashCount -ge 2) { $bodyStart = $li + 1; break }
        }
    }

    # Build body text; guard against empty file or all-frontmatter file
    if ($bodyStart -lt $lines.Count) {
        $bodyText = ($lines[$bodyStart..($lines.Count - 1)]) -join "`n"
    }
    else {
        $bodyText = ''
    }

    # Find all [[Target]] or [[Target|Alias]] wikilinks in body
    $wikilinkMatches = [regex]::Matches($bodyText, '\[\[([^\]|#]+)(\|[^\]]+)?\]\]')

    foreach ($m in $wikilinkMatches) {
        # Link target (not the alias, not heading anchors)
        $target = $m.Groups[1].Value.Trim()

        # Only register if the target is a known people note
        if ($PeopleNoteNames.ContainsKey($target)) {
            Register-Person -RawName $target -SourceFile $fileStem
        }
    }
}

Write-Host "  Scan complete. Found $($PersonIndex.Count) unique person entries."

# ─── Step 4: Ensure every dedicated people note appears in the index ──────────
# Even if no other file references them by name or wikilink.
Write-Host 'Step 4: Ensuring all 15 - People notes appear in index...'

foreach ($stem in $PeopleNoteNames.Keys) {
    # Normalize the stem name
    $normalized = ConvertTo-LastFirst $stem

    # Skip stems that fail the name filter (e.g., NLP concept files in 15 - People)
    if (Test-IsNotAName $stem) { continue }

    if (-not $PersonIndex.ContainsKey($normalized)) {
        # Add a new entry sourced from the person's own note
        $PersonIndex[$normalized] = @{
            SourceFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            HasNote     = $true
            NoteName    = $stem
        }
    }
    else {
        # Mark as having a dedicated note
        $PersonIndex[$normalized].HasNote  = $true
        $PersonIndex[$normalized].NoteName = $stem
    }

    # Include the person's own note file as a source reference
    [void]$PersonIndex[$normalized].SourceFiles.Add($stem)
}

Write-Host "  After step 4: $($PersonIndex.Count) total entries."

# ─── Step 5: Build the Markdown output ────────────────────────────────────────
Write-Host 'Step 5: Building Markdown output...'

# Sort all person names alphabetically (case-insensitive, by sort key)
$sortedNames = $PersonIndex.Keys | Sort-Object { $_.ToLower() }

# Group by first letter of the normalized name (first char = start of last name)
$letterGroups = [ordered]@{}

foreach ($name in $sortedNames) {
    # Get the first character as an uppercase letter
    $firstChar = $name.Substring(0, 1).ToUpper()

    # Normalize accented first letter to base ASCII for grouping
    # e.g., "Ö" -> "O", "Á" -> "A" so they go in the right letter section
    $normalized = $firstChar.Normalize([System.Text.NormalizationForm]::FormD)
    $asciiChar  = ($normalized.ToCharArray() | Where-Object {
        [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne
        [System.Globalization.UnicodeCategory]::NonSpacingMark
    }) -join ''
    # Use ASCII base letter if it's a single A-Z letter; otherwise keep original
    if ($asciiChar -match '^(?-i)[A-Z]$') { $firstChar = $asciiChar }

    if (-not $letterGroups.Contains($firstChar)) {
        $letterGroups[$firstChar] = [System.Collections.Generic.List[string]]::new()
    }
    $letterGroups[$firstChar].Add($name)
}

# ─── Assemble output lines ────────────────────────────────────────────────────
$outputLines = [System.Collections.Generic.List[string]]::new()

# Frontmatter block
$outputLines.Add('---')
$outputLines.Add('tags:')
$outputLines.Add('  - Index')
$outputLines.Add('  - People')
$outputLines.Add('title: People Index')
$outputLines.Add('created: 2026-02-24')
$outputLines.Add('updated: 2026-03-19')
$outputLines.Add('---')

# Title and intro
$outputLines.Add('# People Index')
$outputLines.Add('')

# Unicode star U+2605 and em-dash U+2014 as explicit char codes to avoid encoding issues
$star    = [char]0x2605
$emdash  = [char]0x2014
$introLine = "All named individuals found in the vault $emdash personal contacts ($star, with a dedicated note in [[15 - People]]) and authors found in frontmatter across notes and Kindle Clippings. Sorted alphabetically by last name."
$outputLines.Add($introLine)
$outputLines.Add('')
$outputLines.Add('---')
$outputLines.Add('')

# One section per letter, sorted A-Z
foreach ($letter in ($letterGroups.Keys | Sort-Object)) {
    $outputLines.Add("## $letter")

    # Names within this letter group (already sorted via $sortedNames)
    $names = $letterGroups[$letter]

    foreach ($name in $names) {
        $entry = $PersonIndex[$name]

        # Section heading: ### Last, First  or  ### Last, First ★
        if ($entry.HasNote) {
            $outputLines.Add("### $name $star")
        }
        else {
            $outputLines.Add("### $name")
        }

        # If has dedicated note, add the person note wikilink
        if ($entry.HasNote -and (-not [string]::IsNullOrWhiteSpace($entry.NoteName))) {
            $outputLines.Add("**Person note:** [[$($entry.NoteName)]]")
        }

        # Source file references — sorted alphabetically, deduplicated (by HashSet)
        $sources = $entry.SourceFiles | Sort-Object

        foreach ($src in $sources) {
            $outputLines.Add("- [[$src]]")
        }
        # NOTE: No blank line between ### entries (spec requirement)
    }

    # Blank line after last entry in this letter section, before next ## heading
    $outputLines.Add('')
}

# Footer
$outputLines.Add('---')
$outputLines.Add('')
$footerStar    = "$star = Has dedicated note in [[15 - People]]"
$footerSources = "Sources: 15 - People folder (wikilink references), frontmatter author fields across vault, 09 - Kindle Clippings authors"
$outputLines.Add("*$footerStar*")
$outputLines.Add("*$footerSources*")

# ─── Step 6: Write output file (UTF-8, no BOM) ────────────────────────────────
Write-Host 'Step 6: Writing People Index...'

# Join lines with Windows-style CRLF (consistent with other vault files)
$fullText = $outputLines -join "`r`n"

# StreamWriter with UTF-8 no-BOM encoding
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)  # $false = suppress BOM
$writer    = [System.IO.StreamWriter]::new($OutputFile, $false, $utf8NoBom)
$writer.Write($fullText)
$writer.Close()
$writer.Dispose()

# ─── Summary ──────────────────────────────────────────────────────────────────
$entriesWithNotes = ($PersonIndex.Values | Where-Object { $_.HasNote }).Count

Write-Host ''
Write-Host '==========================================='
Write-Host 'People Index rebuilt successfully.'
Write-Host ("  Total unique person entries : " + $PersonIndex.Count)
Write-Host ("  Entries with dedicated notes: " + $entriesWithNotes)
Write-Host ("  Letter sections             : " + $letterGroups.Count)
Write-Host ("  Output file                 : " + $OutputFile)
Write-Host '==========================================='
