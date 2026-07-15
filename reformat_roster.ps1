# reformat_roster.ps1
# Rewrites Austin FC roster.md as a properly structured Obsidian note:
#   - Frontmatter with tags
#   - One ## section per season (2021-2026), newest first
#   - Clean table headers (no merged-cell rows, per-90 cols renamed)
#   - Player names as plain text (URLs stripped)
#   - Nation as plain 3-letter code
#   - Matches column removed
#   - Nav links and Related Notes

$inPath  = "C:\Users\awt\Sync\Obsidian\Austin FC roster.md"
$outPath = "C:\Users\awt\Sync\Obsidian\Austin FC roster.md"

$raw = [System.IO.File]::ReadAllText($inPath, [System.Text.Encoding]::UTF8)

# Normalize line endings to LF for processing
$lines = $raw -replace "`r`n", "`n" -split "`n"

# ── Helper: strip markdown link, return display text ─────────────────────────
function Strip-Link ($cell) {
    $cell = $cell.Trim()
    # [display](url) → display
    if ($cell -match '^\[([^\]]+)\]\([^)]+\)$') { return $Matches[1] }
    # bare cell value (no link)
    return $cell
}

# ── Helper: extract nation code from "[xx NAT](url)" or "xx NAT" ─────────────
function Get-Nation ($cell) {
    $cell = $cell.Trim()
    if ($cell -match '\[..\s+([A-Z]{3})\]') { return $Matches[1] }
    if ($cell -match '..\s+([A-Z]{3})')      { return $Matches[1] }
    return $cell
}

# ── Collect season blocks ─────────────────────────────────────────────────────
# Each block: { Year, Rows[] } where Rows are parsed data rows (not header/separator)
$seasons = [System.Collections.Generic.List[hashtable]]::new()
$currentSeason = $null

foreach ($line in $lines) {
    # Season year header (bare 4-digit year on its own line)
    if ($line -match '^\s*(\d{4})\s*$') {
        if ($currentSeason) { $seasons.Add($currentSeason) }
        $currentSeason = @{ Year = [int]$Matches[1]; Rows = [System.Collections.Generic.List[string[]]]::new() }
        continue
    }

    if (-not $currentSeason) { continue }

    # Skip merged-span header rows (start with ||)
    if ($line -match '^\|+\s*\|') { continue }
    # Skip separator rows
    if ($line -match '^\|---') { continue }
    # Skip the column-name header row
    if ($line -match '^\|Player\|') { continue }
    # Skip blank / whitespace-only lines
    if ($line.Trim() -eq '') { continue }
    # Skip non-table lines
    if (-not $line.TrimStart().StartsWith('|')) { continue }

    # Parse data row
    $cols = $line -split '\|'
    # cols[0]="" cols[1]=Player cols[2]=Nation cols[3]=Pos cols[4]=Age
    # cols[5]=MP cols[6]=Starts cols[7]=Min cols[8]=90s
    # cols[9]=Gls cols[10]=Ast cols[11]=G+A cols[12]=G-PK
    # cols[13]=PK cols[14]=PKatt cols[15]=CrdY cols[16]=CrdR
    # cols[17]=Gls/90 cols[18]=Ast/90 cols[19]=G+A/90 cols[20]=G-PK/90 cols[21]=G+A-PK/90
    # cols[22]=Matches cols[23]=""

    if ($cols.Count -lt 4) { continue }

    $player = Strip-Link $cols[1]
    $nation = Get-Nation $cols[2]
    $pos    = $cols[3].Trim()
    $age    = if ($cols.Count -gt 4)  { $cols[4].Trim()  } else { "" }
    $mp     = if ($cols.Count -gt 5)  { $cols[5].Trim()  } else { "" }
    $starts = if ($cols.Count -gt 6)  { $cols[6].Trim()  } else { "" }
    $min    = if ($cols.Count -gt 7)  { $cols[7].Trim()  } else { "" }
    $n90s   = if ($cols.Count -gt 8)  { $cols[8].Trim()  } else { "" }
    $gls    = if ($cols.Count -gt 9)  { $cols[9].Trim()  } else { "" }
    $ast    = if ($cols.Count -gt 10) { $cols[10].Trim() } else { "" }
    $gpa    = if ($cols.Count -gt 11) { $cols[11].Trim() } else { "" }
    $gpk    = if ($cols.Count -gt 12) { $cols[12].Trim() } else { "" }
    $pk     = if ($cols.Count -gt 13) { $cols[13].Trim() } else { "" }
    $pkatt  = if ($cols.Count -gt 14) { $cols[14].Trim() } else { "" }
    $crdy   = if ($cols.Count -gt 15) { $cols[15].Trim() } else { "" }
    $crdr   = if ($cols.Count -gt 16) { $cols[16].Trim() } else { "" }
    $g90    = if ($cols.Count -gt 17) { $cols[17].Trim() } else { "" }
    $a90    = if ($cols.Count -gt 18) { $cols[18].Trim() } else { "" }
    $ga90   = if ($cols.Count -gt 19) { $cols[19].Trim() } else { "" }
    $gpk90  = if ($cols.Count -gt 20) { $cols[20].Trim() } else { "" }
    $gapk90 = if ($cols.Count -gt 21) { $cols[21].Trim() } else { "" }

    $currentSeason.Rows.Add(@($player,$nation,$pos,$age,$mp,$starts,$min,$n90s,$gls,$ast,$gpa,$gpk,$pk,$pkatt,$crdy,$crdr,$g90,$a90,$ga90,$gpk90,$gapk90))
}
if ($currentSeason) { $seasons.Add($currentSeason) }

# Sort seasons newest-first
$seasons = @($seasons | Sort-Object { $_.Year } -Descending)

# ── Build output ──────────────────────────────────────────────────────────────
$sb = [System.Text.StringBuilder]::new()

[void]$sb.AppendLine("---")
[void]$sb.AppendLine("tags: [AustinFC, Soccer, MLS, Stats, Roster]")
[void]$sb.AppendLine("created: 2026-04-25")
[void]$sb.AppendLine("nav: '[[MOC - Sports & Recreation]]'")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("# Austin FC Season Stats")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Standard statistics by season for Austin FC (MLS, 2021–2026). Source: [fbref.com](https://fbref.com). Per-90 figures are as reported by fbref for that season.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("[[15 - People]] | [[Austin FC All-Time Roster]] | [[MOC - Sports & Recreation]]")
[void]$sb.AppendLine("")

# Standard table header and separator
$tableHeader = "| Player | Nation | Pos | Age | MP | Starts | Min | 90s | Gls | Ast | G+A | G-PK | PK | PKatt | CrdY | CrdR | Gls/90 | Ast/90 | G+A/90 | G-PK/90 | G+A-PK/90 |"
$tableSep    = "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"

foreach ($season in $seasons) {
    [void]$sb.AppendLine("## $($season.Year)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine($tableHeader)
    [void]$sb.AppendLine($tableSep)

    foreach ($r in $season.Rows) {
        $row = "| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} | {10} | {11} | {12} | {13} | {14} | {15} | {16} | {17} | {18} | {19} | {20} |" -f `
            $r[0],$r[1],$r[2],$r[3],$r[4],$r[5],$r[6],$r[7],$r[8],$r[9],$r[10],$r[11],$r[12],$r[13],$r[14],$r[15],$r[16],$r[17],$r[18],$r[19],$r[20]
        [void]$sb.AppendLine($row)
    }
    [void]$sb.AppendLine("")
}

[void]$sb.AppendLine("## Related Notes")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- [[Austin FC All-Time Roster]]")
[void]$sb.AppendLine("- [[MOC - Sports & Recreation]]")

$output = $sb.ToString()
[System.IO.File]::WriteAllText($outPath, $output, [System.Text.Encoding]::UTF8)
Write-Host "Done. $($seasons.Count) seasons written."
foreach ($s in $seasons) { Write-Host "  $($s.Year): $($s.Rows.Count) players" }
