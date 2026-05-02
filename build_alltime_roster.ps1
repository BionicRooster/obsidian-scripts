# build_alltime_roster.ps1
# Parses Austin FC roster.md (fbref season tables) and builds all-time career stats note.
# Aggregates MP/Starts/Min/Gls/Ast/G-PK/PK/PKatt/CrdY/CrdR across all seasons (2021-2026).
# Adds jersey numbers, sorts by last name, writes 01/Soccer/Austin FC All-Time Roster.md.

$rosterPath = "D:\Obsidian\Main\Austin FC roster.md"
$outputPath = "D:\Obsidian\Main\01\Soccer\Austin FC All-Time Roster.md"

# ── Jersey number lookup ──────────────────────────────────────────────────────
# Key = exact fbref display name; Value = jersey string ("N" or "N1→N2→N3")
# Sources: Wikipedia season squad pages + Austin FC official site.
# Leave "" for numbers not confirmed from a primary source.
$jerseyMap = @{
    "Facundo Torres"           = ""
    "Brad Stuver"              = "41→1"
    "Brendan Hines-Ike"        = "4"
    "Joseph Rosales"           = ""
    "Myrto Uzuni"              = "10"
    "Jon Gallagher"            = "17"
    "Oleksandr Svatok"         = "21→5"
    "Nicolás Dubersarsky"      = "20"
    "Guilherme Biro"           = "29"
    "Jon Bell"                 = ""
    "Ilie Sánchez"             = "6"
    "Jayden Nelson"            = ""
    "Besard Sabovic"           = "14"
    "Christian Ramirez"        = ""
    "Daniel Pereira"           = "15→6→8"
    "Mikkel Desler"            = "3"
    "Žan Kolmanič"             = "21→23"
    "CJ Fodrey"                = "19"
    "Jorge Alastuey"           = ""
    "Damian Las"               = ""
    "Mateja Đorđević"          = "35"
    "Robert Taylor"            = "16"
    "Micah Burton"             = "32"
    "Ervin Torres"             = "38"
    "Riley Thomas"             = ""
    "Owen Wolff"               = "33"
    "Osman Bukari"             = "7→11"
    "Brandon Vazquez"          = "9"
    "Diego Rubio"              = "14→21"
    "Julio Cascante"           = "18"
    "Jáder Obrian"             = "11→7"
    "Stefan Cleveland"         = ""
    "Leo Väisänen"             = ""
    "Adrian Gonzalez"          = ""
    "Nico van Rijn"            = ""
    "Antonio Gomez"            = ""
    "Bryant Farkarlun"         = ""
    "Alexander Ring"           = "8"
    "Sebastián Driussi"        = "25→7→10"
    "Jhojan Valencia"          = ""
    "Gyasi Zardes"             = "9"
    "Matt Hedges"              = ""
    "Ethan Finlay"             = ""
    "Emiliano Rigoni"          = "77→7"
    "Hector Jiménez"           = ""
    "Alonso Ramirez"           = ""
    "Matt Bersano"             = ""
    "Valentin Noël"            = ""
    "Nick Lima"                = "24"
    "Diego Fagúndez"           = "14"
    "Maximiliano Urruti"       = "37"
    "Adam Lundqvist"           = ""
    "Rodney Redes"             = "11"
    "Aleksandar Radovanović"   = ""
    "Kipp Keller"              = ""
    "Sofiane Djeffal"          = ""
    "Will Bruin"               = ""
    "Memo Rodriguez"           = ""
    "Brandan Craig"            = ""
    "Joe Hafferty"             = ""
    "David Rodriguez"          = ""
    "Amro Tarek"               = ""
    "Ruben Gabrielsen"         = ""
    "Felipe"                   = ""
    "Cecilio Domínguez"        = "10"
    "Moussa Djitte"            = "99→2"
    "Danny Hoesen"             = "9"
    "Andrew Tarbell"           = ""
    "Jhohan Romaña"            = ""
    "Washington Corozo"        = ""
    "Jared Stroud"             = "5"
    "Tomas Pochettino"         = "7"
    "Matt Besler"              = ""
    "Sebastian Berhalter"      = "16"
    "Manny Perez"              = ""
    "Kekuta Manneh"            = ""
    "Aedan Stanley"            = ""
    "Ben Sweat"                = ""
    "McKinze Gaines"           = ""
    "Freddy Kleemann"          = ""
    "Will Pulisic"             = ""
}

# ── Parse roster.md ───────────────────────────────────────────────────────────
$raw = [System.IO.File]::ReadAllText($rosterPath, [System.Text.Encoding]::UTF8)

# Dictionary: player display name -> career aggregation hashtable
$players = [System.Collections.Generic.Dictionary[string,hashtable]]::new()

$currentYear = 0

foreach ($line in ($raw -split "`r?`n")) {

    # Detect season year header (a line that is just a 4-digit year)
    if ($line -match '^\s*(\d{4})\s*$') {
        $currentYear = [int]$Matches[1]
        continue
    }

    # Skip table structure lines and non-player lines
    if ($line -match '^\|---' -or $line -match '^\|\|' -or $line -match '^\|Player') { continue }
    if ($line -notmatch '^\|\[') { continue }

    # Extract display name from markdown link [Name](url)
    if ($line -notmatch '^\|\[([^\]]+)\]') { continue }
    $name = $Matches[1]

    # Split row into columns (pipe-delimited)
    $cols = $line -split '\|'

    # cols indices after splitting a leading |:
    # [0]=""  [1]=player  [2]=nation  [3]=pos  [4]=age
    # [5]=MP  [6]=Starts  [7]=Min  [8]=90s
    # [9]=Gls  [10]=Ast  [11]=G+A  [12]=G-PK
    # [13]=PK  [14]=PKatt  [15]=CrdY  [16]=CrdR
    # [17..21]=per-90  [22]=Matches

    # Extract nation (3-letter uppercase code from "[xx XXX](url)" format)
    $nation = ""
    if ($cols.Count -gt 2 -and $cols[2] -match '\[..?\s+([A-Z]{3})\]') {
        $nation = $Matches[1]
    }

    # Extract position
    $pos = if ($cols.Count -gt 3) { $cols[3].Trim() } else { "" }

    # Safely read column value, returning "" if index out of range
    $getCol = { param($i) if ($cols.Count -gt $i) { $cols[$i] } else { "" } }

    $mp     = & $getCol 5  | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }
    $starts = & $getCol 6  | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }
    $min    = & $getCol 7  | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }
    $gls    = & $getCol 9  | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }
    $ast    = & $getCol 10 | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }
    $gpk    = & $getCol 12 | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }
    $pk     = & $getCol 13 | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }
    $pkatt  = & $getCol 14 | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }
    $crdy   = & $getCol 15 | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }
    $crdr   = & $getCol 16 | ForEach-Object { $v = $_ -replace ',','' -replace '\s',''; if ($v -match '^\d+$') { [int]$v } else { 0 } }

    # Create player entry if first encounter
    if (-not $players.ContainsKey($name)) {
        $players[$name] = @{
            Nation  = $nation
            Pos     = $pos
            Seasons = [System.Collections.Generic.SortedSet[int]]::new()
            MP = 0; Starts = 0; Min = 0
            Gls = 0; Ast = 0; GPK = 0; PK = 0; PKatt = 0; CrdY = 0; CrdR = 0
        }
    }

    $p = $players[$name]

    # Track season; use position from earliest season (lowest year) since file is newest-first
    if ($currentYear -gt 0) { [void]$p.Seasons.Add($currentYear) }

    # Accumulate career stats
    $p.MP     += $mp
    $p.Starts += $starts
    $p.Min    += $min
    $p.Gls    += $gls
    $p.Ast    += $ast
    $p.GPK    += $gpk
    $p.PK     += $pk
    $p.PKatt  += $pkatt
    $p.CrdY   += $crdy
    $p.CrdR   += $crdr
}

# For position: re-do a second pass using earliest season position.
# Simplest: since SortedSet is ascending, first season year is $p.Seasons.Min.
# We already have position from first encounter (newest first); re-reading to get oldest
# would add complexity. The current pos field is the position from the 2026 data
# (or whatever the player's most recent season is). This is the most relevant position.
# No action needed.

# ── Sort helper: extract last name for alphabetical ordering ──────────────────
function Get-LastName ($fullName) {
    # Special cases
    if ($fullName -eq "Felipe")           { return "Felipe" }   # mononym
    if ($fullName -eq "Nico van Rijn")    { return "van Rijn" }
    # Default: last space-delimited token
    $parts = $fullName -split '\s+'
    return $parts[-1]
}

# Sort player names by last name, then first name
$sorted = $players.Keys | Sort-Object { Get-LastName $_ }, { $_ }

# ── Build output markdown ─────────────────────────────────────────────────────
$sb = [System.Text.StringBuilder]::new()

[void]$sb.AppendLine("---")
[void]$sb.AppendLine("tags: [AustinFC, Soccer, MLS, Roster]")
[void]$sb.AppendLine("created: 2026-04-25")
[void]$sb.AppendLine("nav: '[[MOC - Sports & Recreation]]'")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("# Austin FC All-Time Roster")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Career statistics for all Austin FC MLS players (2021–2026), aggregated across seasons. Jersey numbers from Wikipedia season squad articles and Austin FC official site; blank = not confirmed. `#` column uses `N1→N2` format for changes within an Austin FC tenure.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("[[Austin FC roster]] | [[MOC - Sports & Recreation]]")
[void]$sb.AppendLine("")

# Table header (fbref format + # column + Seasons column replacing Age)
[void]$sb.AppendLine("| # | Player | Nation | Pos | Seasons | MP | Starts | Min | 90s | Gls | Ast | G+A | G-PK | PK | PKatt | CrdY | CrdR | Gls/90 | Ast/90 | G+A/90 | G-PK/90 | G+A-PK/90 |")
[void]$sb.AppendLine("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")

foreach ($name in $sorted) {
    $p = $players[$name]

    # Jersey number
    $jersey = if ($jerseyMap.ContainsKey($name)) { $jerseyMap[$name] } else { "" }

    # Season list (comma-separated ascending years)
    $seasonStr = ($p.Seasons | Sort-Object) -join ", "

    # Derived totals
    $ga = $p.Gls + $p.Ast

    # Per-90 stats (recalculated from career totals; blank if no minutes played)
    if ($p.Min -gt 0) {
        $nineties  = [math]::Round($p.Min / 90.0, 1)
        $n90       = $p.Min / 90.0
        $gls90     = [math]::Round($p.Gls / $n90, 2).ToString("F2")
        $ast90     = [math]::Round($p.Ast / $n90, 2).ToString("F2")
        $ga90      = [math]::Round($ga     / $n90, 2).ToString("F2")
        $gpk90     = [math]::Round($p.GPK  / $n90, 2).ToString("F2")
        $gapk90    = [math]::Round(($p.GPK + $p.Ast) / $n90, 2).ToString("F2")
        $ninetiesF = $nineties.ToString("F1")
        $minF      = "{0:N0}" -f $p.Min
        $mpF       = $p.MP.ToString()
        $startsF   = $p.Starts.ToString()
        $glsF      = $p.Gls.ToString()
        $astF      = $p.Ast.ToString()
        $gaF       = $ga.ToString()
        $gpkF      = $p.GPK.ToString()
        $pkF       = $p.PK.ToString()
        $pkattF    = $p.PKatt.ToString()
        $crdyF     = $p.CrdY.ToString()
        $crdrF     = $p.CrdR.ToString()
    } else {
        # Player on roster but never played
        $ninetiesF = ""; $minF = ""; $mpF = "0"; $startsF = "0"
        $glsF = ""; $astF = ""; $gaF = ""; $gpkF = ""
        $pkF = ""; $pkattF = ""; $crdyF = ""; $crdrF = ""
        $gls90 = ""; $ast90 = ""; $ga90 = ""; $gpk90 = ""; $gapk90 = ""
    }

    [void]$sb.AppendLine("| $jersey | $name | $($p.Nation) | $($p.Pos) | $seasonStr | $mpF | $startsF | $minF | $ninetiesF | $glsF | $astF | $gaF | $gpkF | $pkF | $pkattF | $crdyF | $crdrF | $gls90 | $ast90 | $ga90 | $gpk90 | $gapk90 |")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Notes")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **#**: Jersey number(s) at Austin FC. `N1→N2` = changed numbers during tenure; blank = unconfirmed.")
[void]$sb.AppendLine("- **Seasons**: Calendar years listed on Austin FC first-team roster (fbref).")
[void]$sb.AppendLine("- **Stats**: Aggregated from fbref.com season pages. Per-90 figures recalculated from career minute totals.")
[void]$sb.AppendLine("- **MP = 0**: Player appeared on squad list but recorded no minutes in official league matches.")
[void]$sb.AppendLine("- **G-PK**: Non-penalty goals. **G+A-PK/90**: Non-penalty goals + assists per 90 minutes.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Related Notes")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- [[Austin FC roster]]")
[void]$sb.AppendLine("- [[MOC - Sports & Recreation]]")

# Write file with UTF-8 encoding (no BOM)
$output = $sb.ToString()
[System.IO.File]::WriteAllText($outputPath, $output, [System.Text.Encoding]::UTF8)
Write-Host "Done. $($players.Count) players written to $outputPath"
