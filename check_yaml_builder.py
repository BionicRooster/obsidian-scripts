#!/usr/bin/env python3
# Writes check_yaml.ps1 cleanly without escaping issues

script = """\
# check_yaml.ps1 - Scan and fix YAML frontmatter issues in Obsidian vault
# Checks for:
#   1. Inline tags (space/comma/bracket separated on one line)
#   2. Unclosed frontmatter (--- open but no closing ---)
#   3. Frontmatter merged with body (--- ## Heading on same line)
#   4. Unquoted values containing colons in title/description/etc.
#   5. Duplicate keys in frontmatter
#
# UTF-8 safe: reads/writes with System.Text.Encoding::UTF8, never re-encodes.

param(
    [string]$VaultRoot = "C:\\Users\\awt\\Sync\\Obsidian",
    [switch]$DryRun = $false
)

# Folders to skip - images, system, templates
$SkipFolders = @("00 - Images", "Attachments", ".obsidian", "Templates")

# UTF-8 without BOM for writing
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Counters
$filesScanned = 0
$filesFixed = 0
$issueCount = 0

# Fix log
$fixLog = [System.Collections.Generic.List[PSCustomObject]]::new()

function Should-Skip {
    param([string]$FilePath)
    foreach ($folder in $SkipFolders) {
        if ($FilePath -like "*\\$folder\\*") { return $true }
    }
    return $false
}

function Log-Fix {
    param([string]$File, [string]$Issue)
    $fixLog.Add([PSCustomObject]@{ File = $File; Issue = $Issue })
    $script:issueCount++
}

# Convert an inline tags value to a YAML list block string
# Handles: bracket [a,b], comma a,b,c, inline dash - a - b, space-sep a b c
function Convert-InlineTags {
    param([string]$Value)
    $v = $Value.Trim()
    # Strip enclosing brackets
    if ($v -match '^\\[(.+)\\]$') { $v = $Matches[1] }
    # Inline dash list: "- tag1 - tag2"
    if ($v -match '^-\\s') {
        $tags = ($v -split '\\s+-\\s+') | ForEach-Object { $_.TrimStart('-').Trim() } | Where-Object { $_ -ne '' }
    } elseif ($v -match ',') {
        # Comma separated
        $tags = ($v -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    } elseif ($v -match '\\s') {
        # Space separated
        $tags = ($v -split '\\s+') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    } else {
        $tags = @($v)
    }
    $lines = $tags | ForEach-Object { "  - $_" }
    return $lines -join "`n"
}

# Check if a YAML value needs quoting (contains unquoted colon)
function Needs-Quoting {
    param([string]$Value)
    $v = $Value.Trim()
    # Already double-quoted
    if ($v.StartsWith('"') -and $v.EndsWith('"') -and $v.Length -ge 2) { return $false }
    # Already single-quoted
    if ($v.StartsWith("'") -and $v.EndsWith("'") -and $v.Length -ge 2) { return $false }
    # Contains colon
    return ($v -match ':')
}

# Wrap a value in double quotes, escaping internal double quotes
function Quote-Value {
    param([string]$Value)
    $v = $Value.Trim()
    $v = $v.Replace('"', '\\"')
    return '"' + $v + '"'
}

# Process a single markdown file
function Process-File {
    param([string]$Path)

    # Read file as UTF-8
    $content = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)

    # Normalise line endings; remember original style
    $hadCRLF = $content.Contains("`r`n")
    $content = $content.Replace("`r`n", "`n")

    # Skip files with no frontmatter
    if (-not $content.StartsWith('---')) { return }

    $changed = $false

    # --- Fix 1: "--- ## Body content" merged on opening line ---
    # E.g. the first line is "---## Technology" or "--- ## Heading"
    if ($content -match '^---([^-\\n].+)\\n') {
        $merged = $Matches[1].Trim()
        $content = "---`n$merged`n" + $content.Substring($content.IndexOf("`n") + 1)
        Log-Fix -File $Path -Issue "Merged open marker split: content '$merged' was on same line as '---'"
        $changed = $true
    }

    # --- Match frontmatter block ---
    $fmRegex = [regex]'^---\\n([\\s\\S]*?)\\n---(?:\\n|$)'
    $fmMatch = $fmRegex.Match($content)

    if (-not $fmMatch.Success) {
        # Check for unclosed frontmatter
        $dashCount = ([regex]::Matches($content, '(?m)^---\\s*$')).Count
        if ($dashCount -lt 2) {
            Log-Fix -File $Path -Issue "UNCLOSED frontmatter: file starts with '---' but has no closing '---' (manual review needed)"
        }
        # Write if merge fix was applied
        if ($changed -and -not $DryRun) {
            $out = if ($hadCRLF) { $content.Replace("`n", "`r`n") } else { $content }
            [System.IO.File]::WriteAllText($Path, $out, $Utf8NoBom)
            $script:filesFixed++
        }
        return
    }

    # Extract the three parts: everything before, the FM body, everything after
    $fmStart  = $fmMatch.Index                          # Position of the opening "---"
    $fmLength = $fmMatch.Length                          # Length of entire match incl delimiters
    $fmBody   = $fmMatch.Groups[1].Value                 # YAML content between the --- lines
    $afterFM  = $content.Substring($fmStart + $fmLength) # Body after closing ---

    # Split FM into lines for key-by-key processing
    $fmLines = $fmBody -split "`n"
    $newLines = [System.Collections.Generic.List[string]]::new()
    $seenKeys = @{}  # Track keys to detect duplicates

    $i = 0
    while ($i -lt $fmLines.Count) {
        $line = $fmLines[$i]

        # Match a top-level YAML key line: "key: value" or "key:"
        if ($line -match '^([A-Za-z_][A-Za-z0-9_-]*):\\s*(.*)$') {
            $key      = $Matches[1]
            $value    = $Matches[2]
            $keyLower = $key.ToLower()

            # --- Fix 5: Duplicate key ---
            if ($seenKeys.ContainsKey($keyLower)) {
                Log-Fix -File $Path -Issue "Duplicate key removed: '$key' (keeping first occurrence)"
                $i++
                $changed = $true
                continue
            }
            $seenKeys[$keyLower] = $true

            # --- Fix 1: Inline tags ---
            if ($keyLower -eq 'tags') {
                $trimmedVal = $value.Trim()

                # If value is empty, this is a proper multi-line list start - pass through
                if ($trimmedVal -eq '') {
                    $newLines.Add($line)
                    $i++
                    # Consume all following list items (lines starting with spaces + dash)
                    while ($i -lt $fmLines.Count -and $fmLines[$i] -match '^\\s+-') {
                        $newLines.Add($fmLines[$i])
                        $i++
                    }
                    continue
                }

                # Determine if inline expansion is needed
                $needsExpand = $false
                if ($trimmedVal -match '^\\[.+\\]$')           { $needsExpand = $true }  # [tag1, tag2]
                elseif ($trimmedVal -match '^-\\s+\\S')        { $needsExpand = $true }  # - tag1 - tag2
                elseif ($trimmedVal -match ',')                { $needsExpand = $true }  # tag1, tag2
                elseif ($trimmedVal -match '^\\S+\\s+\\S+' -and
                        -not $trimmedVal.StartsWith('"') -and
                        -not $trimmedVal.StartsWith("'"))      { $needsExpand = $true }  # tag1 tag2

                if ($needsExpand) {
                    $listBlock = Convert-InlineTags -Value $trimmedVal
                    $newLines.Add('tags:')
                    foreach ($tagLine in ($listBlock -split "`n")) { $newLines.Add($tagLine) }
                    Log-Fix -File $Path -Issue "Inline tags expanded to list: '$trimmedVal'"
                    $changed = $true
                } else {
                    # Single tag value not in list form
                    if ($trimmedVal -ne '' -and -not $trimmedVal.StartsWith('[')) {
                        $newLines.Add('tags:')
                        $newLines.Add("  - $trimmedVal")
                        Log-Fix -File $Path -Issue "Single inline tag converted to list: '$trimmedVal'"
                        $changed = $true
                    } else {
                        $newLines.Add($line)
                    }
                }
                $i++
                continue
            }

            # --- Fix 4: Unquoted colon in string-value keys ---
            $quoteableKeys = @('title','description','subtitle','summary','author','subject','source')
            if ($quoteableKeys -contains $keyLower -and (Needs-Quoting -Value $value)) {
                $quoted = Quote-Value -Value $value
                $newLines.Add("${key}: $quoted")
                Log-Fix -File $Path -Issue "Unquoted colon in '$key' value wrapped in double quotes"
                $changed = $true
                $i++
                continue
            }

            # No fix needed for this key
            $newLines.Add($line)
            $i++

        } else {
            # Continuation line, list item, blank line, comment — pass through unchanged
            $newLines.Add($line)
            $i++
        }
    }

    # Reconstruct and write if anything changed
    if ($changed) {
        $newFmBody  = $newLines -join "`n"
        $newContent = "---`n$newFmBody`n---`n$afterFM"
        if ($hadCRLF) { $newContent = $newContent.Replace("`n", "`r`n") }
        if (-not $DryRun) {
            [System.IO.File]::WriteAllText($Path, $newContent, $Utf8NoBom)
        }
        $script:filesFixed++
    }
}

# ── Main ─────────────────────────────────────────────────────────────────────

Write-Host "Scanning vault: $VaultRoot"
Write-Host "Dry run: $DryRun"
Write-Host ""

$allFiles = Get-ChildItem -Path $VaultRoot -Recurse -Filter "*.md" -File
foreach ($file in $allFiles) {
    if (Should-Skip -FilePath $file.FullName) { continue }
    $filesScanned++
    Process-File -Path $file.FullName
}

Write-Host ""
Write-Host "======================================================"
Write-Host "  YAML Frontmatter Scan Complete"
Write-Host "======================================================"
Write-Host "  Files scanned : $filesScanned"
Write-Host "  Files fixed   : $filesFixed"
Write-Host "  Issues found  : $issueCount"
if ($DryRun) { Write-Host "  *** DRY RUN - no files were written ***" }
Write-Host ""

if ($fixLog.Count -gt 0) {
    Write-Host "Detail log:"
    $grouped = $fixLog | Group-Object -Property File
    foreach ($group in $grouped) {
        $shortName = $group.Name -replace [regex]::Escape($VaultRoot), ''
        Write-Host "  $shortName"
        foreach ($entry in $group.Group) {
            Write-Host "    -> $($entry.Issue)"
        }
    }
} else {
    Write-Host "No issues found."
}
"""

with open(r'C:\Users\awt\check_yaml.ps1', 'w', encoding='utf-8') as f:
    f.write(script)
print('Script written successfully.')
