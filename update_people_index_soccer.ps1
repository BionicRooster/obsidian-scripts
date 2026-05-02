# update_people_index_soccer.ps1
# Inserts all Austin FC 2026 roster players into People Index
# with links to box scores for matches they appeared in.

$path = "D:\Obsidian\Main\People Index.md"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Shorthand wikilinks for each box score
$minU = "[[2026-02-21 - Austin FC vs Minnesota United Box Score]]"
$dcu  = "[[2026-03-01 - Austin FC vs DC United Box Score]]"
$cfc  = "[[2026-03-07 - Charlotte FC vs Austin FC Box Score]]"
$rsl  = "[[2026-03-14 - Real Salt Lake vs Austin FC Box Score]]"
$lafc = "[[2026-03-21 - Austin FC vs Lafc Box Score]]"
$mia  = "[[2026-04-04 - Inter Miami Cf vs Austin FC Box Score]]"
$lag  = "[[2026-04-11 - Austin FC vs LA Galaxy Box Score]]"
$lou  = "[[2026-04-14 - Louisville City FC vs Austin FC Box Score]]"
$tor  = "[[2026-04-18 - Toronto FC vs Austin FC Box Score]]"
$sje  = "[[2026-04-22 - San Jose Earthquakes vs Austin FC Box Score]]"

# Build each player entry block
function Make-Entry {
    param ([string]$header, [string[]]$links)
    $lines = @("### $header")
    foreach ($lnk in $links) { $lines += "- $lnk" }
    return ($lines -join "`n")
}

# ---- Build all new entry strings ----

# A
$alastuey = Make-Entry "Alastuey, Jorge" @($rsl, $sje)

# B
$bell = Make-Entry "Bell, Jon" @($dcu, $cfc, $rsl, $lafc, $mia, $lou, $tor, $sje)
$biro = Make-Entry "Biro, Guilherme" @($dcu, $cfc, $mia, $lag, $lou, $tor, $sje)
$bukari = Make-Entry "Bukari, Osman" @("Austin FC 2026 roster (departed before season start)")
$burton = Make-Entry "Burton, Micah" @($sje)

# C
$cascante = Make-Entry "Cascante, Julio" @("Austin FC 2026 roster (option not exercised)")

# D
$desler = Make-Entry "Desler, Mikkel" @($lag, $lou, $tor, $sje)
$djordjevic = Make-Entry "Djordjevic, Mateja" @($rsl, $lou)
$dubersarsky = Make-Entry "Dubersarsky, Nicolas" @($cfc, $rsl, $lafc, $mia, $lag, $lou, $tor, $sje)

# F
$farkarlun = Make-Entry "Farkarlun, Jimmy" @("Austin FC 2026 roster (option not exercised)")
$fodrey = Make-Entry "Fodrey, CJ" @($cfc, $mia, $lag, $lou, $sje)

# G
$gallagher = Make-Entry "Gallagher, Jon" @($minU, $dcu, $cfc, $rsl, $lafc, $mia, $lag, $sje)

# H
$hinesike = Make-Entry "Hines-Ike, Brendan" @($minU, $dcu, $cfc, $rsl, $lafc, $mia, $lag, $lou, $sje)

# K
$kolmanic = Make-Entry "Kolmanic, Zan" @($minU, $mia, $lou, $sje)

# L
$las = Make-Entry "Las, Damian" @($lou)

# N
$nelson = Make-Entry "Nelson, Jayden" @($minU, $dcu, $cfc, $rsl, $mia, $lag, $lou, $tor)

# O
$obrian = Make-Entry "Obrian, Jader" @("Austin FC 2026 roster (contract bought out)")

# P
$pereira = Make-Entry "Pereira, Dani" @($minU, $dcu, $cfc, $lag, $lou)

# R
$ramirez = Make-Entry "Ramirez, Christian" @($dcu, $cfc, $rsl, $lafc, $mia, $lag, $tor, $sje)
$rosales = Make-Entry "Rosales, Joseph" @($minU, $dcu, $cfc, $rsl, $lafc, $mia, $lag, $lou, $tor, $sje)
$rubio   = Make-Entry "Rubio, Diego" @("Austin FC 2026 roster (option not exercised)")

# S
$sabovic   = Make-Entry "Sabovic, Besard" @($dcu, $cfc, $rsl, $mia, $lag, $lou, $tor, $sje)
$sanchez   = Make-Entry "Sanchez, Ilie" @($minU, $dcu, $cfc, $rsl, $lafc, $mia, $lag, $tor)
$stuver    = Make-Entry "Stuver, Brad" @($minU, $dcu, $cfc, $rsl, $lafc, $mia, $lag, $tor, $sje)
$svatok    = Make-Entry "Svatok, Oleksandr" @($minU, $dcu, $cfc, $rsl, $lafc, $mia, $lag, $tor)

# T
$taylorR   = Make-Entry "Taylor, Robert" @($lou, $tor)
$thomas    = Make-Entry "Thomas, Riley" @("Austin FC 2026 roster (no confirmed match appearances)")
$ervinT    = Make-Entry "Torres, Ervin" @($sje)
$facundoT  = Make-Entry "Torres, Facundo" @($minU, $dcu, $cfc, $rsl, $lafc, $mia, $lag, $lou, $tor, $sje)

# U
$uzuni = Make-Entry "Uzuni, Myrto" @($minU, $dcu, $cfc, $rsl, $lafc, $mia, $lag, $lou, $tor)

# V
$vazquez = Make-Entry "Vazquez, Brandon" @("Austin FC 2026 roster (out injured - knee)")

# W
$wolff = Make-Entry "Wolff, Owen" @("Austin FC 2026 roster (out injured - sports hernia)")

# ---- Now insert each entry at the correct location ----

# A: insert after the Ahrens block, before Anastasiou
$searchA = "- [[Ahrens-How to Take S]]"
if ($content.IndexOf($searchA) -ge 0) {
    $content = $content.Replace($searchA, $searchA + "`n" + $alastuey)
} else { Write-Warning "Could not find insertion point for Alastuey" }

# B: Bell - after Bates block, before Beers
$searchBell = "- [[19th Century Religious Movements]]`n### Beers"
if ($content.IndexOf($searchBell) -ge 0) {
    $content = $content.Replace($searchBell, "- [[19th Century Religious Movements]]`n" + $bell + "`n### Beers")
} else { Write-Warning "Could not find insertion point for Bell" }

# B: Biro - after Bieber block, before Bishop
$searchBiro = "- [[Ronald C. Bieber]]`n### Bishop"
if ($content.IndexOf($searchBiro) -ge 0) {
    $content = $content.Replace($searchBiro, "- [[Ronald C. Bieber]]`n" + $biro + "`n### Bishop")
} else { Write-Warning "Could not find insertion point for Biro" }

# B: Bukari - after Buettner block, before Bull
$searchBukari = "- [[What the World's Longest-Lived Women Eat]]`n### Bull"
if ($content.IndexOf($searchBukari) -ge 0) {
    $content = $content.Replace($searchBukari, "- [[What the World's Longest-Lived Women Eat]]`n" + $bukari + "`n### Bull")
} else { Write-Warning "Could not find insertion point for Bukari" }

# B: Burton - after Burke block, before Bush
$searchBurton = "- [[Be182 Year in Review]]`n### Bush"
if ($content.IndexOf($searchBurton) -ge 0) {
    $content = $content.Replace($searchBurton, "- [[Be182 Year in Review]]`n" + $burton + "`n### Bush")
} else { Write-Warning "Could not find insertion point for Burton" }

# C: Cascante - after Carter block, before Cederquist
$searchCasc = "- [[Chiasmus]]`n### Cederquist"
if ($content.IndexOf($searchCasc) -ge 0) {
    $content = $content.Replace($searchCasc, "- [[Chiasmus]]`n" + $cascante + "`n### Cederquist")
} else { Write-Warning "Could not find insertion point for Cascante" }

# D: Desler - after Desjardins block, before Devotionals
$searchDesler = "- [[Grouping Objects in Access_ An Organizational Tip You Can't Miss - MicroKnowledge, Inc]]`n### Devotionals"
if ($content.IndexOf($searchDesler) -ge 0) {
    $content = $content.Replace($searchDesler, "- [[Grouping Objects in Access_ An Organizational Tip You Can't Miss - MicroKnowledge, Inc]]`n" + $desler + "`n### Devotionals")
} else { Write-Warning "Could not find insertion point for Desler" }

# D: Djordjevic - after Dillard block, before DIR
$searchDjord = "- [[The Magic of Moss and What It Teaches Us About the Art of Attentiveness to Life at All Scales]]`n### DIR"
if ($content.IndexOf($searchDjord) -ge 0) {
    $content = $content.Replace($searchDjord, "- [[The Magic of Moss and What It Teaches Us About the Art of Attentiveness to Life at All Scales]]`n" + $djordjevic + "`n### DIR")
} else { Write-Warning "Could not find insertion point for Djordjevic" }

# D: Dubersarsky - after Drumm block, before Dwyer
$searchDuber = "- [[Digirule 2, 2A and 2U " + [char]0x2013 + " Brads Electronic Projects]]`n### Dwyer"
if ($content.IndexOf($searchDuber) -ge 0) {
    $content = $content.Replace($searchDuber, "- [[Digirule 2, 2A and 2U " + [char]0x2013 + " Brads Electronic Projects]]`n" + $dubersarsky + "`n### Dwyer")
} else { Write-Warning "Could not find insertion point for Dubersarsky" }

# F: Farkarlun - after Fargo block, before Feldenkrais
$searchFark = "- [[Truncated Filenames]]`n### Feldenkrais"
if ($content.IndexOf($searchFark) -ge 0) {
    $content = $content.Replace($searchFark, "- [[Truncated Filenames]]`n" + $farkarlun + "`n### Feldenkrais")
} else { Write-Warning "Could not find insertion point for Farkarlun" }

# F: Fodrey - after Flaccavento block, before Foley
$searchFod = "- [[Anthony Flaccavento]]`n### Foley"
if ($content.IndexOf($searchFod) -ge 0) {
    $content = $content.Replace($searchFod, "- [[Anthony Flaccavento]]`n" + $fodrey + "`n### Foley")
} else { Write-Warning "Could not find insertion point for Fodrey" }

# G: Gallagher - before Gameros (first entry in G section)
$searchGal = "## G`n### Gameros"
if ($content.IndexOf($searchGal) -ge 0) {
    $content = $content.Replace($searchGal, "## G`n" + $gallagher + "`n### Gameros")
} else { Write-Warning "Could not find insertion point for Gallagher" }

# H: Hines-Ike - after Hinds block, before Hitler
$searchHI = "- [[Takane Hinds]]`n### Hitler"
if ($content.IndexOf($searchHI) -ge 0) {
    $content = $content.Replace($searchHI, "- [[Takane Hinds]]`n" + $hinesike + "`n### Hitler")
} else { Write-Warning "Could not find insertion point for Hines-Ike" }

# K: Kolmanic - after Klein block, before Kondo
$searchKol = "- [[Mindy Klein]]`n## L"
# Actually let me check: Klein is followed by what? Let me look for Klein then Kondo
$searchKol2 = "- [[Mindy Klein]]`n### Kond"
if ($content.IndexOf($searchKol2) -ge 0) {
    $content = $content.Replace($searchKol2, "- [[Mindy Klein]]`n" + $kolmanic + "`n### Kond")
} else {
    Write-Warning "Could not find insertion point for Kolmanic (Kondo variant)"
    # try L section header
    if ($content.IndexOf("- [[Mindy Klein]]`n## L") -ge 0) {
        $content = $content.Replace("- [[Mindy Klein]]`n## L", "- [[Mindy Klein]]`n" + $kolmanic + "`n## L")
    } else { Write-Warning "Could not find insertion point for Kolmanic (L section variant)" }
}

# L: Las - after Larsen block, before Lashley
$searchLas = "- [[On the Trail of Stardust The Guide to Finding Micrometeorites]]`n### Lashley"
if ($content.IndexOf($searchLas) -ge 0) {
    $content = $content.Replace($searchLas, "- [[On the Trail of Stardust The Guide to Finding Micrometeorites]]`n" + $las + "`n### Lashley")
} else { Write-Warning "Could not find insertion point for Las" }

# N: Nelson - after Narayanan block, before Nguyen
$searchNel = "- [[Moravec's Paradox]]" + " " + [char]0x2014 + " Princeton CS Professor; argues Moravec's Paradox is `"neither useful nor true`"`n### Nguyen"
if ($content.IndexOf($searchNel) -ge 0) {
    $content = $content.Replace($searchNel, "- [[Moravec's Paradox]]" + " " + [char]0x2014 + " Princeton CS Professor; argues Moravec's Paradox is `"neither useful nor true`"`n" + $nelson + "`n### Nguyen")
} else {
    # Simpler search
    $searchNel2 = "### Nguyen, Joseph"
    if ($content.IndexOf($searchNel2) -ge 0) {
        $narayananBlock = "Narayanan, Arvind`n- [[Moravec"
        # find position of Nguyen and insert before it
        $pos = $content.IndexOf("### Nguyen, Joseph")
        if ($pos -ge 0) {
            $content = $content.Insert($pos, $nelson + "`n")
        }
    } else { Write-Warning "Could not find insertion point for Nelson" }
}

# O: Obrian - after Obama block, before O'Brien Karen
$searchObrian = "- [[Chiasmus]]`n### O'Brien, Karen"
if ($content.IndexOf($searchObrian) -ge 0) {
    $content = $content.Replace($searchObrian, "- [[Chiasmus]]`n" + $obrian + "`n### O'Brien, Karen")
} else { Write-Warning "Could not find insertion point for Obrian" }

# P: Pereira - after Peek block, before Perez Carmen
$searchPer = "- [[2017 Personal Calendar Summary]]`n### Perez, Carmen"
if ($content.IndexOf($searchPer) -ge 0) {
    $content = $content.Replace($searchPer, "- [[2017 Personal Calendar Summary]]`n" + $pereira + "`n### Perez, Carmen")
} else { Write-Warning "Could not find insertion point for Pereira" }

# R: Ramirez - after Ralls block, before Ray
$searchRam = "- [[New Insights Into How the Famed Antikythera Mechanism May Have Worked]]`n### Ray"
if ($content.IndexOf($searchRam) -ge 0) {
    $content = $content.Replace($searchRam, "- [[New Insights Into How the Famed Antikythera Mechanism May Have Worked]]`n" + $ramirez + "`n### Ray")
} else { Write-Warning "Could not find insertion point for Ramirez" }

# R: Rosales - after Roosevelt block, before Rowan
$searchRos = "- [[Lost Lincoln Portrait From Teddy Roosevelt's Office Reemerges After a Century]]`n### Rowan"
if ($content.IndexOf($searchRos) -ge 0) {
    $content = $content.Replace($searchRos, "- [[Lost Lincoln Portrait From Teddy Roosevelt's Office Reemerges After a Century]]`n" + $rosales + "`n### Rowan")
} else { Write-Warning "Could not find insertion point for Rosales" }

# R: Rubio - after Rowe block, before Rule
$searchRub = "- [[Mike Rowe]]`n### Rule"
if ($content.IndexOf($searchRub) -ge 0) {
    $content = $content.Replace($searchRub, "- [[Mike Rowe]]`n" + $rubio + "`n### Rule")
} else { Write-Warning "Could not find insertion point for Rubio" }

# S: Sabovic - at very start of S section, before Sale
$searchSab = "## S`n### Sale"
if ($content.IndexOf($searchSab) -ge 0) {
    $content = $content.Replace($searchSab, "## S`n" + $sabovic + "`n### Sale")
} else { Write-Warning "Could not find insertion point for Sabovic" }

# S: Sanchez - after Samuelson block, before Sandlin
$searchSanch = "- [[White Paper - The Copyright Grab]]`n### Sandlin"
if ($content.IndexOf($searchSanch) -ge 0) {
    $content = $content.Replace($searchSanch, "- [[White Paper - The Copyright Grab]]`n" + $sanchez + "`n### Sandlin")
} else { Write-Warning "Could not find insertion point for Sanchez" }

# S: Stuver - after Stultz block, before Styron
$searchStu = "- [[CNCs That Won't Take Your Whole Garage]]`n### Styron"
if ($content.IndexOf($searchStu) -ge 0) {
    $content = $content.Replace($searchStu, "- [[CNCs That Won't Take Your Whole Garage]]`n" + $stuver + "`n### Styron")
} else { Write-Warning "Could not find insertion point for Stuver" }

# S: Svatok - after Support block, before Switchboard
$searchSvat = "- [[Be175]]`n### Switchboard"
if ($content.IndexOf($searchSvat) -ge 0) {
    $content = $content.Replace($searchSvat, "- [[Be175]]`n" + $svatok + "`n### Switchboard")
} else { Write-Warning "Could not find insertion point for Svatok" }

# T: Taylor Robert - after Tate block, before Teles
$searchTayR = "- [[GCCMA Black Author Panel]]`n### Teles"
# Actually let me find Tate ReShonda's last link then Teles
$searchTayR2 = "- [[ReShonda Tate]]`n### Teles"
if ($content.IndexOf($searchTayR2) -ge 0) {
    $content = $content.Replace($searchTayR2, "- [[ReShonda Tate]]`n" + $taylorR + "`n### Teles")
} else { Write-Warning "Could not find insertion point for Taylor Robert" }

# T: Thomas Riley - after Terry block, before Timourian
$searchThom = "- [[2015 Personal Calendar Summary]]`n### Timourian"
if ($content.IndexOf($searchThom) -ge 0) {
    $content = $content.Replace($searchThom, "- [[2015 Personal Calendar Summary]]`n" + $thomas + "`n### Timourian")
} else { Write-Warning "Could not find insertion point for Thomas Riley" }

# T: Torres Ervin and Torres Facundo - after Tipping block, before Trump
$searchTorres = "- [[Jim Tipping]]`n### Trump"
if ($content.IndexOf($searchTorres) -ge 0) {
    $content = $content.Replace($searchTorres, "- [[Jim Tipping]]`n" + $ervinT + "`n" + $facundoT + "`n### Trump")
} else { Write-Warning "Could not find insertion point for Torres" }

# U: Uzuni - after Union block, before V section
$searchUzu = "- [[2013 Personal Calendar Summary]]`n## V"
if ($content.IndexOf($searchUzu) -ge 0) {
    $content = $content.Replace($searchUzu, "- [[2013 Personal Calendar Summary]]`n" + $uzuni + "`n## V")
} else { Write-Warning "Could not find insertion point for Uzuni" }

# V: Vazquez - after Varela block, before Verdone
$searchVaz = "- [[Prometheus, the 5,000-year-old Tree That Was Cut Down by Mistake]]`n### Verdone"
if ($content.IndexOf($searchVaz) -ge 0) {
    $content = $content.Replace($searchVaz, "- [[Prometheus, the 5,000-year-old Tree That Was Cut Down by Mistake]]`n" + $vazquez + "`n### Verdone")
} else { Write-Warning "Could not find insertion point for Vazquez" }

# W: Wolff - after Wilson Sophia block, before Wolfram
$searchWolff = "- [[2026-04-25]]`n### Wolfram"
if ($content.IndexOf($searchWolff) -ge 0) {
    $content = $content.Replace($searchWolff, "- [[2026-04-25]]`n" + $wolff + "`n### Wolfram")
} else { Write-Warning "Could not find insertion point for Wolff" }

# Write result back
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)

Write-Host "People Index updated successfully."
Write-Host "Entries added: Alastuey, Bell, Biro, Bukari, Burton, Cascante, Desler, Djordjevic, Dubersarsky, Farkarlun, Fodrey, Gallagher, Hines-Ike, Kolmanic, Las, Nelson, Obrian, Pereira, Ramirez, Rosales, Rubio, Sabovic, Sanchez, Stuver, Svatok, Taylor(Robert), Thomas(Riley), Torres(Ervin), Torres(Facundo), Uzuni, Vazquez, Wolff"
