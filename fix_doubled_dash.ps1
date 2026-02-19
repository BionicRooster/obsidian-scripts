# fix_doubled_dash.ps1
# Fixes the "  - - tag" doubled dash issue in YAML tags
# caused by the inline tag splitter not stripping the leading "- " from first token.

param(
    [switch]$WhatIf,
    [switch]$Apply
)

if (-not $WhatIf -and -not $Apply) {
    Write-Host "Usage: .\fix_doubled_dash.ps1 -WhatIf | -Apply"
    exit 1
}

$vaultPath = "D:\Obsidian\Main"
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" -File
$fixCount = 0

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    $hasCarriageReturn = $content.Contains("`r`n")
    $lineEnding = if ($hasCarriageReturn) { "`r`n" } else { "`n" }
    $hasBom = $content.StartsWith([char]0xFEFF)
    $lines = $content -split "`r?`n"

    # State tracking for frontmatter
    $inFrontmatter = $false
    $frontmatterStart = $false
    $currentKey = ""
    $modified = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Track frontmatter boundaries
        if ($line -match '^\s*---\s*$') {
            if (-not $frontmatterStart) {
                $frontmatterStart = $true
                $inFrontmatter = $true
            } else {
                $inFrontmatter = $false
            }
            continue
        }

        if (-not $inFrontmatter) { continue }

        # Track current YAML key
        if ($line -match '^([a-zA-Z_][a-zA-Z0-9_-]*)\s*:') {
            $currentKey = $Matches[1]
            continue
        }

        # Fix doubled dash only under tags key
        if ($currentKey -eq 'tags' -and $line -match '^\s+-\s+-\s+(.+)$') {
            $tagValue = $Matches[1].Trim().Trim('"').Trim("'")
            # Detect indent
            $line -match '^(\s+)' | Out-Null
            $indent = $Matches[1]
            $lines[$i] = "$indent- $tagValue"
            $modified = $true
        }
    }

    if ($modified) {
        $newContent = $lines -join $lineEnding
        $relativePath = $file.FullName.Substring($vaultPath.Length + 1)

        if ($Apply) {
            if ($hasBom) {
                $utf8 = [System.Text.UTF8Encoding]::new($true)
            } else {
                $utf8 = [System.Text.UTF8Encoding]::new($false)
            }
            [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8)
            Write-Host "FIXED: $relativePath"
        } else {
            Write-Host "WOULD FIX: $relativePath"
        }
        $fixCount++
    }
}

Write-Host ""
Write-Host "Mode: $(if ($Apply) {'Applied'} else {'Preview'})"
Write-Host "Files fixed: $fixCount"
