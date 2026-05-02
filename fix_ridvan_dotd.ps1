# Fix Ridvan / Ridvan -> Ridvan (with dotted d U+1E0D)
# Handles all variants: Ridvan, Ridvan (missing accent too), ridvan, ridvan
# Also checks filenames for renaming

$ErrorActionPreference = 'Stop'
$vault = 'D:\Obsidian\Main'

# Character references
$dotD     = [char]0x1E0D   # d with dot below
$aAcute   = [char]0x00E1   # a with acute (a)
$capDotD  = [char]0x1E0C   # D with dot below (for start of sentence, rare)

# Correct forms
$correctLower = "ri$($dotD)v$($aAcute)n"   # ridvan
$correctUpper = "Ri$($dotD)v$($aAcute)n"   # Ridvan

# Patterns to find (regex - regular d, either a or a)
# Matches: Ridvan, Ridvan, ridvan, ridvan (all with regular ASCII d U+0064)
$pattern = '(?-i)[Rr]idv[a' + $aAcute + ']n'

# Replacement function: preserve leading case
function Fix-Ridvan {
    param([string]$text)
    # Replace capital-R variant
    $text = [regex]::Replace($text, "Ridv[$aAcute`a]n", $correctUpper)
    # Replace lowercase-r variant
    $text = [regex]::Replace($text, "ridv[$aAcute`a]n", $correctLower)
    return $text
}

# -------------------------------------------------------------------
# Phase 1: Survey and fix file CONTENT
# -------------------------------------------------------------------
Write-Output "=== Phase 1: File content ==="
$contentFiles = @()
$totalContentMatches = 0

Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
    $_.FullName -notlike '*\.obsidian\*' -and $_.FullName -notlike '*\.trash\*'
} | ForEach-Object {
    $raw = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return }

    # Check for incorrect spellings (regular ASCII d = U+0064)
    $matches = [regex]::Matches($raw, "(?-i)[Rr]idv[$([char]0x00E1)a]n")
    if ($matches.Count -gt 0) {
        $fixed = Fix-Ridvan $raw
        Set-Content -LiteralPath $_.FullName -Value $fixed -Encoding UTF8 -NoNewline
        $contentFiles += [PSCustomObject]@{
            File    = $_.FullName.Replace($vault, '')
            Count   = $matches.Count
            Samples = ($matches | Select-Object -First 3 | ForEach-Object { $_.Value }) -join ', '
        }
        $totalContentMatches += $matches.Count
    }
}

if ($contentFiles.Count -eq 0) {
    Write-Output "  No incorrect spellings found in file content."
} else {
    $contentFiles | ForEach-Object {
        Write-Output "  [$($_.Count)x] $($_.File)"
        Write-Output "       Forms found: $($_.Samples)"
    }
}
Write-Output "  Total replacements in content: $totalContentMatches"

# -------------------------------------------------------------------
# Phase 2: Filenames containing Ridvan / Ridvan (without dotted d)
# -------------------------------------------------------------------
Write-Output "`n=== Phase 2: Filenames ==="
$renamedFiles = @()

Get-ChildItem $vault -Recurse | Where-Object {
    $_.FullName -notlike '*\.obsidian\*' -and
    $_.FullName -notlike '*\.trash\*' -and
    $_.Name -match "(?-i)[Rr]idv[$([char]0x00E1)a]n"
} | ForEach-Object {
    $oldName = $_.Name
    $newName = Fix-Ridvan $oldName
    if ($newName -ne $oldName) {
        $dir  = Split-Path $_.FullName -Parent
        $tmp  = Join-Path $dir ($newName + '.tmp')
        $dest = Join-Path $dir $newName
        # Two-step rename for Windows case sensitivity
        Rename-Item -LiteralPath $_.FullName -NewName ($newName + '.tmp')
        Rename-Item -LiteralPath $tmp -NewName $newName
        $renamedFiles += [PSCustomObject]@{ Old = $oldName; New = $newName }
        Write-Output "  Renamed: [$oldName]"
        Write-Output "        -> [$newName]"
    }
}

if ($renamedFiles.Count -eq 0) { Write-Output "  No filenames needed renaming." }

# -------------------------------------------------------------------
# Phase 3: Update wikilinks that pointed to renamed files
# -------------------------------------------------------------------
if ($renamedFiles.Count -gt 0) {
    Write-Output "`n=== Phase 3: Update wikilinks for renamed files ==="
    foreach ($r in $renamedFiles) {
        $oldBase = [System.IO.Path]::GetFileNameWithoutExtension($r.Old)
        $newBase = [System.IO.Path]::GetFileNameWithoutExtension($r.New)
        $escaped = [regex]::Escape($oldBase)
        $linksFixed = 0

        Get-ChildItem $vault -Recurse -Filter '*.md' | Where-Object {
            $_.FullName -notlike '*\.obsidian\*' -and $_.FullName -notlike '*\.trash\*'
        } | ForEach-Object {
            $c = Get-Content -LiteralPath $_.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
            if ($c -and $c -match $escaped) {
                $fixed = $c -replace $escaped, $newBase
                Set-Content -LiteralPath $_.FullName -Value $fixed -Encoding UTF8 -NoNewline
                $linksFixed++
            }
        }
        Write-Output "  Updated wikilinks [$oldBase] -> [$newBase] in $linksFixed file(s)"
    }
}

# -------------------------------------------------------------------
# Summary
# -------------------------------------------------------------------
Write-Output "`n=== Summary ==="
Write-Output "  Files with content fixes : $($contentFiles.Count)"
Write-Output "  Total replacements       : $totalContentMatches"
Write-Output "  Files renamed            : $($renamedFiles.Count)"
