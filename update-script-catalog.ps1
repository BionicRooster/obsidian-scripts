# update-script-catalog.ps1
# Scans all PowerShell (.ps1) and Python (.py) scripts in C:\Users\awt\ (root only),
# extracts a one-line description from each file's header comment block, and writes
# a categorized markdown catalog to two destinations:
#
#   1. C:\Users\awt\.claude\projects\C--Users-awt\memory\domain\scripts.md
#      -- the Claude memory file consulted before writing new code
#
#   2. C:\Users\awt\Sync\Obsidian\01\Claude\Script Catalog.md
#      -- the vault note for human review
#
# Run this script whenever new scripts are added to keep the catalog current.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File "C:\Users\awt\update-script-catalog.ps1"

# --- Paths ---
$ScriptRoot    = "C:\Users\awt"                                                          # Root folder to scan (non-recursive)
$MemoryOutput  = "C:\Users\awt\.claude\projects\C--Users-awt\memory\domain\scripts.md"  # Claude memory destination
$VaultOutput   = "C:\Users\awt\Sync\Obsidian\01\Claude\Script Catalog.md"                         # Obsidian vault destination
$GeneratedDate = Get-Date -Format "yyyy-MM-dd HH:mm"                                    # Timestamp for the catalog header
$EmDash        = [char]0x2014                                                            # Em dash character (avoids non-ASCII literals in PS1 source)

# --- Category mapping: filename prefix -> human-readable group ---
# Each key is a regex pattern matched against the script filename (case-insensitive).
# First match wins. More specific patterns must appear before general ones.
$CategoryPatterns = [ordered]@{
    '^(obsidian_maintenance|obsidian_)'                = 'Obsidian Core'
    '^(moc_|build_moc|alphabetize_moc|analyze_moc|add_moc|fix_moc)' = 'MOC Management'
    '^(add_)'                                          = 'Add / Link'
    '^(analyze_|Analyze-)'                             = 'Analysis'
    '^(check_)'                                        = 'Check / Validate'
    '^(fix_|repair_)'                                  = 'Fix / Repair'
    '^(find_)'                                         = 'Find / Search'
    '^(build_|generate_)'                              = 'Build / Generate'
    '^(batch_|bulk_)'                                  = 'Batch Operations'
    '^(update_)'                                       = 'Update'
    '^(export_)'                                       = 'Export'
    '^(convert_|pdf_)'                                 = 'Convert / Import'
    '^(install_|setup_|move_|bootstrap)'               = 'Setup / Install'
    '^(dashboard_)'                                    = 'Dashboard'
    '^(append_)'                                       = 'Append / Log'
    '^(apply_)'                                        = 'Apply'
    '^(backfill_|migrate_)'                            = 'Backfill / Migrate'
    '^(scan_|search_)'                                 = 'Scan / Search'
    '^(test_)'                                         = 'Testing'
    '\.py$'                                            = 'Python Scripts'
}
$DefaultCategory = 'Other'  # Fallback for scripts that match no pattern

# --- Helper: extract a one-line description from a script's header ---
# For PS1: reads first 20 lines; returns first substantive # comment line,
#   skipping blank comments, dividers, and lines that just restate the filename.
# For PY: checks for triple-quoted docstring or # comment lines.
function Get-ScriptDescription {
    param(
        [System.IO.FileInfo]$File  # The script file to inspect
    )

    # Read up to 20 lines to capture the header comment block
    $lines = @()
    try {
        $lines = Get-Content $File.FullName -Encoding UTF8 -ErrorAction Stop |
                 Select-Object -First 20
    } catch {
        return "(unreadable)"
    }

    $ext = $File.Extension.ToLower()  # File extension determines parsing strategy

    if ($ext -eq '.py') {
        # Python: check for triple-quoted docstring opening, then fall back to # comments
        $inDocstring = $false  # Tracks whether we are inside a triple-quoted block
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if (-not $inDocstring -and ($trimmed -match '^"""' -or $trimmed -match "^'''")) {
                $inDocstring = $true
                # Extract content on the same line as the opening quotes
                $content = $trimmed -replace '^"{3}', '' -replace '"{3}$', ''
                $content = $content.Trim()
                if ($content.Length -gt 3) { return $content }
                continue
            }
            if ($inDocstring -and $trimmed.Length -gt 0) {
                return $trimmed  # First non-empty line inside docstring = description
            }
            if ($trimmed -match '^#\s+(.+)') {
                $candidate = $Matches[1].Trim()
                if ($candidate -notmatch '^-+$' -and $candidate -notmatch '^=+$') {
                    return $candidate
                }
            }
        }
    } else {
        # PowerShell: scan # comment lines, skip filename references and dividers
        $filename = $File.Name  # Used to skip lines that just repeat the filename
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -match '^#\s*(.*)') {
                $candidate = $Matches[1].Trim()  # Text after the # character
                if ($candidate.Length -eq 0)                        { continue }  # Skip blank comments
                if ($candidate -match '^[-=]+$')                    { continue }  # Skip divider lines
                if ($candidate -ieq $filename)                      { continue }  # Skip filename restatements
                if ($candidate -imatch [regex]::Escape($filename))  { continue }  # Skip partial filename refs
                return $candidate  # First substantive comment line = description
            }
        }
    }

    return "(no description found)"  # Fallback when no comment block is present
}

# --- Helper: determine category for a script ---
function Get-Category {
    param([string]$FileName)  # Filename (not full path) to match against patterns

    foreach ($pattern in $CategoryPatterns.Keys) {
        if ($FileName -match $pattern) {
            return $CategoryPatterns[$pattern]
        }
    }
    return $DefaultCategory
}

# --- Scan scripts ---
Write-Host "Scanning $ScriptRoot for scripts..." -ForegroundColor Cyan

# Collect all PS1 and PY files in the root directory only (non-recursive)
$allScripts = @(
    Get-ChildItem $ScriptRoot -Filter "*.ps1" -File
    Get-ChildItem $ScriptRoot -Filter "*.py"  -File
) | Sort-Object Name  # Alphabetical sort within categories

$totalCount = $allScripts.Count  # Total scripts found
Write-Host "Found $totalCount scripts. Extracting descriptions..." -ForegroundColor Cyan

# Build result objects: name, category, description, last-modified date
$results = foreach ($script in $allScripts) {
    $desc     = Get-ScriptDescription -File $script           # One-line description from header
    $category = Get-Category -FileName $script.Name          # Functional group
    $modified = $script.LastWriteTime.ToString("yyyy-MM-dd")  # Last modified date

    [PSCustomObject]@{
        Name        = $script.Name
        Category    = $category
        Description = $desc
        Modified    = $modified
    }
}

# Group results by category for sectioned output
$grouped = $results | Group-Object Category | Sort-Object Name

# --- Build markdown content ---
$sb = [System.Text.StringBuilder]::new()  # String builder for efficient concatenation

$null = $sb.AppendLine("# Script Catalog")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("Auto-generated by ``update-script-catalog.ps1`` $EmDash run this script to refresh.")
$null = $sb.AppendLine("Generated: $GeneratedDate | Total scripts: $totalCount")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("> **Claude usage rule:** Before writing new code, search this catalog for an")
$null = $sb.AppendLine("> existing script that covers the task. Use ``Grep`` on this file with keywords")
$null = $sb.AppendLine("> from the task description.")
$null = $sb.AppendLine("")

# Table of contents
$null = $sb.AppendLine("## Contents")
$null = $sb.AppendLine("")
foreach ($group in $grouped) {
    $anchor = $group.Name.ToLower() -replace '[^a-z0-9\s]', '' -replace '\s+', '-'
    $null = $sb.AppendLine("- [$($group.Name) ($($group.Count))]($anchor)")
}
$null = $sb.AppendLine("")
$null = $sb.AppendLine("---")
$null = $sb.AppendLine("")

# One section per category
foreach ($group in $grouped) {
    $null = $sb.AppendLine("## $($group.Name)")
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("| Script | Description | Modified |")
    $null = $sb.AppendLine("| ------ | ----------- | -------- |")

    foreach ($entry in ($group.Group | Sort-Object Name)) {
        # Escape pipe characters in description to avoid breaking the markdown table
        $safeDesc = $entry.Description -replace '\|', '\|'
        $null = $sb.AppendLine("| ``$($entry.Name)`` | $safeDesc | $($entry.Modified) |")
    }

    $null = $sb.AppendLine("")
}

$markdown = $sb.ToString()  # Final markdown string

# --- Write to Claude memory ---
Write-Host "Writing memory file: $MemoryOutput" -ForegroundColor Yellow
$memDir = Split-Path $MemoryOutput -Parent
if (-not (Test-Path $memDir)) { New-Item -ItemType Directory -Path $memDir -Force | Out-Null }
[System.IO.File]::WriteAllText($MemoryOutput, $markdown, [System.Text.Encoding]::UTF8)
Write-Host "  Done." -ForegroundColor Green

# --- Write to Obsidian vault ---
Write-Host "Writing vault note: $VaultOutput" -ForegroundColor Yellow
$vaultDir = Split-Path $VaultOutput -Parent
if (-not (Test-Path $vaultDir)) { New-Item -ItemType Directory -Path $vaultDir -Force | Out-Null }
[System.IO.File]::WriteAllText($VaultOutput, $markdown, [System.Text.Encoding]::UTF8)
Write-Host "  Done." -ForegroundColor Green

Write-Host ""
Write-Host "Catalog complete: $totalCount scripts across $($grouped.Count) categories." -ForegroundColor Cyan
Write-Host "Memory : $MemoryOutput"
Write-Host "Vault  : $VaultOutput"
