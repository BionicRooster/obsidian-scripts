# Cleanup script: removes false-positive entries from People Index and NLP file Related Notes
# These entries were created by broken early runs of Phase 26 (name extraction had bugs)

$enc = New-Object System.Text.UTF8Encoding($false)   # UTF-8 without BOM

function Remove-PeopleIndexEntries {
    param([string]$filePath, [string[]]$headingsToRemove)

    $bytes  = [System.IO.File]::ReadAllBytes($filePath)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $enc    = New-Object System.Text.UTF8Encoding($false)
    $text   = if ($hasBom) { $enc.GetString($bytes[3..($bytes.Length-1)]) } else { $enc.GetString($bytes) }
    $lines  = [System.Collections.Generic.List[string]]($text -split '\r?\n')
    $eol    = if ($text -match '\r\n') { "`r`n" } else { "`n" }
    $removed = 0

    foreach ($heading in $headingsToRemove) {
        # Find the ### line (with optional trailing ★ and whitespace)
        $headPattern = [regex]::Escape("### $heading")
        $idx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^$headPattern") { $idx = $i; break }
        }
        if ($idx -eq -1) { Write-Host "Not found: ### $heading"; continue }

        # Find end of this entry (next ### or ## or ---)
        $end = $idx + 1
        while ($end -lt $lines.Count -and $lines[$end] -notmatch '^### |^## |^---') {
            $end++
        }

        # Remove lines from idx to end-1
        $count = $end - $idx
        $lines.RemoveRange($idx, $count)
        $removed++
        Write-Host "Removed entry: ### $heading ($count lines)"
    }

    $newText = $lines -join $eol
    $outBytes = if ($hasBom) {
        (New-Object System.Text.UTF8Encoding($true)).GetPreamble() + $enc.GetBytes($newText)
    } else { $enc.GetBytes($newText) }
    [System.IO.File]::WriteAllBytes($filePath, $outBytes)
    Write-Host "Saved People Index. Entries removed: $removed"
}

function Remove-WikiLinksFromFile {
    param([string]$filePath, [string[]]$linksToRemove)

    $bytes  = [System.IO.File]::ReadAllBytes($filePath)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $enc    = New-Object System.Text.UTF8Encoding($false)
    $text   = if ($hasBom) { $enc.GetString($bytes[3..($bytes.Length-1)]) } else { $enc.GetString($bytes) }
    $lines  = [System.Collections.Generic.List[string]]($text -split '\r?\n')
    $eol    = if ($text -match '\r\n') { "`r`n" } else { "`n" }
    $removed = 0

    foreach ($link in $linksToRemove) {
        $linkLine = "- [[$link]]"
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            if ($lines[$i] -eq $linkLine) {
                $lines.RemoveAt($i)
                $removed++
                Write-Host "Removed from $([System.IO.Path]::GetFileName($filePath)): $linkLine"
                break   # Remove only first occurrence
            }
        }
    }

    $newText = $lines -join $eol
    $outBytes = if ($hasBom) {
        (New-Object System.Text.UTF8Encoding($true)).GetPreamble() + $enc.GetBytes($newText)
    } else { $enc.GetBytes($newText) }
    [System.IO.File]::WriteAllBytes($filePath, $outBytes)
    Write-Host "Saved $([System.IO.Path]::GetFileName($filePath)). Links removed: $removed"
}

# ---- 1. Clean up People Index false entries ----
$peopleIndex = 'D:\Obsidian\Main\People Index.md'
$falseHeadings = @(
    'belief, d. Elicit the',        # NLP procedure step, not a person
    'belief, d. Elicit the *',      # variant with star marker
    'belief, f. Reimprint the',     # NLP procedure step
    'belief., f. Reimprint the',    # punctuation variant
    'belief., the',                 # not a person
    'belief:, d. Elicit the',       # punctuation variant
    'If, me',                       # "If me" — not a name
    'If, me.',                      # punctuation variant
    'memory, g. Dissociate the',    # NLP procedure step
    'regression, c. Calibrate age', # NLP procedure step
    'regression., c. Calibrate age' # punctuation variant
)

# Also need to handle ★ suffix — the headings in file may end with " ★"
# The function uses -match so trailing ★ is already handled (partial match of heading)
Remove-PeopleIndexEntries -filePath $peopleIndex -headingsToRemove $falseHeadings

# ---- 2. Clean up contaminated Related Notes in NLP files ----
$falseLinks = @(
    'd. Elicit the belief',
    'd. Elicit the belief:',
    'f. Reimprint the belief',
    'f. Reimprint the belief.',
    'g. Dissociate the memory',
    'c. Calibrate age regression',
    'c. Calibrate age regression.'
)

$nlpFiles = @(
    'D:\Obsidian\Main\01\NLP\NLP Master Class\NLP Six-Step Reframe with Belief Reimprint.md',
    'D:\Obsidian\Main\01\NLP\NLP Master Class\NLP Six-Step Reframe with Belief Reimprint (Bc2) - Antidote Belief Variant.md'
)

foreach ($f in $nlpFiles) {
    Remove-WikiLinksFromFile -filePath $f -linksToRemove $falseLinks
}

# ---- 3. Clean [[me If]] from NLP files ----
$meIfFiles = @(
    'D:\Obsidian\Main\01\NLP\NLP Presuppositions.md',
    'D:\Obsidian\Main\01\NLP\NLP Forum — Contest World Rocked! (December 1994).md'
)
foreach ($f in $meIfFiles) {
    Remove-WikiLinksFromFile -filePath $f -linksToRemove @('me If')
}

# ---- 4. Also remove [[People Index]] back-link incorrectly added to People Index itself ----
# (The people index shouldn't link to itself in Related Notes)
Remove-WikiLinksFromFile -filePath $peopleIndex -linksToRemove @('People Index')

Write-Host "`nCleanup complete."
