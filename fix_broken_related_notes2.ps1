# fix_broken_related_notes2.ps1
# Fixes two remaining broken patterns in Related Notes sections:
#   1. Bare MOC references:  - MOC - Finance & Investment
#      Action: REMOVE (MOC files should not appear in Related Notes per vault rules)
#   2. Bare path references: - Clippings/The Destiny of America
#      Action: extract filename, look up in vault, convert to [[wikilink]] or remove

$vaultPath = 'D:\Obsidian\Main'
$logPath   = 'C:\Users\awt\PowerShell\logs\fix_related_notes2_log.txt'

# -------------------------------------------------------------------------
# Build vault file index (lowercase stem -> actual basename)
# -------------------------------------------------------------------------
Write-Host 'Building vault file index...' -ForegroundColor Cyan
$vaultIndex = @{}
Get-ChildItem $vaultPath -Recurse -Filter '*.md' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $key = $_.BaseName.ToLower()
        if (-not $vaultIndex.ContainsKey($key)) { $vaultIndex[$key] = $_.BaseName }
    }
Write-Host "  Indexed $($vaultIndex.Count) files" -ForegroundColor Green

# -------------------------------------------------------------------------
# Patterns to match
# -------------------------------------------------------------------------
# Pattern 1: bare MOC reference  e.g.  - MOC - Finance & Investment
$mocBareRx = '^- (MOC - .+)$'

# Pattern 2: bare path without alias  e.g.  - Clippings/The Destiny of America
# Must have a / but no | and no [[ and not starting with "- -" (sub-bullet)
$pathBareRx = '^- (?!\[\[)(?!MOC )([A-Za-z0-9][^|[]+)/([^|[\r\n]+[^\s/])$'

# -------------------------------------------------------------------------
# Find files that match either pattern
# -------------------------------------------------------------------------
Write-Host 'Finding files with remaining broken link patterns...' -ForegroundColor Cyan
$affectedFiles = Get-ChildItem $vaultPath -Recurse -Filter '*.md' -ErrorAction SilentlyContinue |
    Where-Object {
        $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        ($content -match '(?m)^- MOC - [^\[]') -or
        ($content -match '(?m)^- (?!\[\[)(?!MOC )[A-Za-z0-9][^|[]+/[^|[\r\n]+[^\s/]$')
    }
Write-Host "  Found $($affectedFiles.Count) files to process" -ForegroundColor Green

# -------------------------------------------------------------------------
# Process each file
# -------------------------------------------------------------------------
$totalFixed   = 0
$totalRemoved = 0
$totalFiles   = 0
$log          = [System.Collections.Generic.List[string]]::new()
$log.Add("fix_broken_related_notes2.ps1 run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$log.Add('')

foreach ($file in $affectedFiles) {
    $bytes  = [System.IO.File]::ReadAllBytes($file.FullName)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $enc    = [System.Text.Encoding]::UTF8
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

    $lines     = $text -split '\r?\n'
    $newLines  = [System.Collections.Generic.List[string]]::new()
    $fileFixed = 0
    $fileRemoved = 0
    $changed   = $false

    # Track whether we are inside a Related Notes section
    # (we only want to modify lines in Related-type sections, not in
    #  body content like tables or other lists)
    $inRelated = $false

    foreach ($line in $lines) {
        # Detect section boundaries
        if ($line -match '^#{1,3} ') {
            # New heading -- check if it looks like a Related section
            $inRelated = $line -match '(?i)^#{1,3} related'
        }

        # --- Pattern 1: bare MOC reference ---
        if ($line -match $mocBareRx) {
            $mocName = $Matches[1].Trim()
            # Remove it regardless of section (these are always invalid plain-text MOC refs)
            $log.Add("  REMOVE MOC: '$mocName'  [in: $($file.Name)]")
            $fileRemoved++
            $totalRemoved++
            $changed = $true
            continue   # Don't add to newLines
        }

        # --- Pattern 2: bare path reference (only in Related sections) ---
        if ($inRelated -and $line -match $pathBareRx) {
            $displayName = $Matches[2].Trim()   # Filename after last /
            # Strip trailing parenthetical comments like "(parent body)"
            $displayName = $displayName -replace '\s*\([^)]+\)\s*$', ''
            $displayName = $displayName.Trim()

            $lookupKey  = $displayName.ToLower()
            $actualName = $vaultIndex[$lookupKey]

            if ($null -eq $actualName) {
                # Try partial / truncated match
                $partial = $vaultIndex.Keys | Where-Object { $_ -like "$lookupKey*" } | Select-Object -First 1
                if ($partial) { $actualName = $vaultIndex[$partial] }
            }

            if ($null -ne $actualName) {
                $newLine = "- [[$actualName]]"
                $newLines.Add($newLine)
                $log.Add("  FIXED path: '$displayName' -> [[$actualName]]  [in: $($file.Name)]")
                $fileFixed++
                $totalFixed++
                $changed = $true
            } else {
                $log.Add("  REMOVE (not found): '$displayName'  [in: $($file.Name)]")
                $fileRemoved++
                $totalRemoved++
                $changed = $true
            }
            continue
        }

        $newLines.Add($line)
    }

    if ($changed) {
        $newText  = $newLines -join "`n"
        $outBytes = $enc.GetBytes($newText)
        if ($hasBom) { $outBytes = [byte[]](0xEF, 0xBB, 0xBF) + $outBytes }
        [System.IO.File]::WriteAllBytes($file.FullName, $outBytes)
        $totalFiles++
        $log.Add("  -> UPDATED: $($file.Name) (fixed: $fileFixed, removed: $fileRemoved)")
    }
}

$log.Add('')
$log.Add("SUMMARY:")
$log.Add("  Files modified : $totalFiles")
$log.Add("  Links converted: $totalFixed")
$log.Add("  Links removed  : $totalRemoved")
[System.IO.File]::WriteAllLines($logPath, $log, [System.Text.Encoding]::UTF8)

Write-Host ''
Write-Host '=== COMPLETE ===' -ForegroundColor Green
Write-Host "  Files modified : $totalFiles"
Write-Host "  Links converted: $totalFixed"
Write-Host "  Links removed  : $totalRemoved"
Write-Host "  Log: $logPath"
