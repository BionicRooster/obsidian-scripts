# fix_broken_related_notes.ps1
# Finds all files with broken "Related Notes" entries in the format:
#   - FolderPath/FileName|Alias
# and converts them to proper Obsidian wikilinks:
#   - [[FileName]]
# Removes entries where the target file does not exist in the vault.
# Also removes links to system/MOC files that should not appear in Related Notes.

$vaultPath   = 'D:\Obsidian\Main'   # Root of Obsidian vault
$logPath     = 'C:\Users\awt\PowerShell\logs\fix_related_notes_log.txt'   # Output log

# System files that should never appear in Related Notes
$systemFiles = @(
    'Master MOC Index',
    'Orphan Files',
    'People Index',
    'Truncated Filenames'
)

# MOC files prefix — any file starting with "MOC - " should be excluded
$mocPrefix = 'MOC - '

# -------------------------------------------------------------------------
# Step 1: Build a case-insensitive lookup of all .md files in the vault
# Key = lowercase basename (no extension), Value = actual basename
# -------------------------------------------------------------------------
Write-Host 'Building vault file index...' -ForegroundColor Cyan
$vaultIndex = @{}   # Lowercase stem -> actual basename (no extension)

Get-ChildItem $vaultPath -Recurse -Filter '*.md' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $key = $_.BaseName.ToLower()   # Lowercase key for case-insensitive lookup
        if (-not $vaultIndex.ContainsKey($key)) {
            $vaultIndex[$key] = $_.BaseName   # Store actual casing
        }
    }

Write-Host "  Indexed $($vaultIndex.Count) files" -ForegroundColor Green

# -------------------------------------------------------------------------
# Step 2: Find all files that contain broken related-notes links
# Pattern: line starts with "- ", has no "[[", contains "/" and "|"
# -------------------------------------------------------------------------
Write-Host 'Finding files with broken Related Notes links...' -ForegroundColor Cyan

# Regex to match a broken link line:
#   ^- followed by non-[ character (not a wikilink), path/name|alias
$brokenPattern = '^- (?!\[\[)(?!\[)([A-Za-z0-9][^|]*)/([^|]+)\|(.+)$'

$affectedFiles = Get-ChildItem $vaultPath -Recurse -Filter '*.md' -ErrorAction SilentlyContinue |
    Where-Object {
        # Quick pre-filter: file must contain the pipe and slash on a bullet line
        $content = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
        $content -match '(?m)^- (?!\[\[)[A-Za-z0-9][^|]*/[^|]+\|'
    }

Write-Host "  Found $($affectedFiles.Count) files to process" -ForegroundColor Green

# -------------------------------------------------------------------------
# Step 3: Process each file
# -------------------------------------------------------------------------
$totalFixed   = 0   # Count of links successfully converted to [[wikilinks]]
$totalRemoved = 0   # Count of links removed (not found or system file)
$totalFiles   = 0   # Count of files modified
$log          = [System.Collections.Generic.List[string]]::new()   # Change log

$log.Add("fix_broken_related_notes.ps1 run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$log.Add("Vault: $vaultPath")
$log.Add('')

foreach ($file in $affectedFiles) {
    $filePath = $file.FullName   # Full path to this file

    # Read file with BOM detection
    $bytes  = [System.IO.File]::ReadAllBytes($filePath)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $enc    = [System.Text.Encoding]::UTF8
    $text   = if ($hasBom) { $enc.GetString($bytes, 3, $bytes.Length - 3) } else { $enc.GetString($bytes) }

    $lines      = $text -split '\r?\n'   # Split into lines (handle both CRLF and LF)
    $newLines   = [System.Collections.Generic.List[string]]::new()
    $fileFixed  = 0   # Links fixed in this file
    $fileRemoved = 0  # Links removed in this file
    $changed    = $false

    foreach ($line in $lines) {
        # Check if this line matches the broken link pattern
        if ($line -match $brokenPattern) {
            $folderPath  = $Matches[1].Trim()   # e.g., "20 - Permanent Notes"
            $displayName = $Matches[2].Trim()   # e.g., "Groasis Waterboxx Greening the World"
            $alias       = $Matches[3].Trim()   # e.g., same as displayName usually

            # Check if this is a system/MOC file that should be removed
            $isSystem = ($systemFiles | Where-Object { $displayName -like "*$_*" }).Count -gt 0
            $isMoc    = $displayName -like "$mocPrefix*"

            if ($isSystem -or $isMoc) {
                # Remove this line
                $log.Add("  REMOVE (system/MOC): $displayName  [in: $($file.Name)]")
                $fileRemoved++
                $totalRemoved++
                $changed = $true
                # Don't add line to newLines — effectively deletes it
                continue
            }

            # Look up the display name in the vault index
            $lookupKey = $displayName.ToLower()   # Lowercase for lookup
            $actualName = $vaultIndex[$lookupKey]   # Try exact lowercase match

            if ($null -eq $actualName) {
                # Try partial match: see if any indexed name starts with the display name
                # (handles truncated filenames like "SCORM - SCORM Explai")
                $partialMatch = $vaultIndex.Keys | Where-Object { $_ -like "$lookupKey*" } | Select-Object -First 1
                if ($partialMatch) {
                    $actualName = $vaultIndex[$partialMatch]
                }
            }

            if ($null -ne $actualName) {
                # File exists — convert to proper wikilink
                $newLine = "- [[$actualName]]"
                $newLines.Add($newLine)
                $log.Add("  FIXED: '$displayName' -> [[$actualName]]  [in: $($file.Name)]")
                $fileFixed++
                $totalFixed++
                $changed = $true
            } else {
                # File not found — remove this line
                $log.Add("  REMOVE (not found): '$displayName'  [in: $($file.Name)]")
                $fileRemoved++
                $totalRemoved++
                $changed = $true
                # Don't add line to newLines — effectively deletes it
            }
        } else {
            # Normal line — keep as-is
            $newLines.Add($line)
        }
    }

    if ($changed) {
        # Reconstruct text from lines
        $newText  = $newLines -join "`n"

        # Write back with original BOM if present
        $outBytes = $enc.GetBytes($newText)
        if ($hasBom) { $outBytes = [byte[]](0xEF, 0xBB, 0xBF) + $outBytes }
        [System.IO.File]::WriteAllBytes($filePath, $outBytes)

        $totalFiles++
        $log.Add("  -> FILE UPDATED: $($file.Name) (fixed: $fileFixed, removed: $fileRemoved)")
    }
}

# -------------------------------------------------------------------------
# Step 4: Write log and print summary
# -------------------------------------------------------------------------
$log.Add('')
$log.Add("SUMMARY:")
$log.Add("  Files modified:    $totalFiles")
$log.Add("  Links converted:   $totalFixed")
$log.Add("  Links removed:     $totalRemoved")

[System.IO.File]::WriteAllLines($logPath, $log, [System.Text.Encoding]::UTF8)

Write-Host ''
Write-Host '=== COMPLETE ===' -ForegroundColor Green
Write-Host "  Files modified : $totalFiles"
Write-Host "  Links converted: $totalFixed  (broken path|alias -> [[wikilink]])"
Write-Host "  Links removed  : $totalRemoved  (file not found or system file)"
Write-Host "  Log written to : $logPath"
