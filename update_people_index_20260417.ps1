# Update People Index with new names from 2026-04-17 classification session
# Reads and writes with UTF-8 encoding to preserve Obsidian content
$indexPath = 'C:\Users\awt\Sync\Obsidian\People Index.md'

# Read file preserving UTF-8 encoding
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

# Special characters
$ellipsis = [char]0x2026
$curlyApos = [char]0x2019
$dash = " - "

# Build note links
$lincolnNote = "[[Lost Lincoln Portrait From Teddy Roosevelt" + $curlyApos + "s Office Reemerges After a Century]]"
$fungiNote = "[[How Mobile Phone Cameras Have Helped Unearth a Mysterious Kingdom]]"
$chestnutNote = "[[A Lost Icon The American Chestnut and Its Central Place in the Eastern Landscape]]"
$nasalNote = "[[This Nasal Spray Rewinds the Aging Brain, Restoring Memory and Reversing Inflammation in Preclinical Models]]"
$moravecNote = "[[Moravec" + $curlyApos + "s Paradox]]"
$ifYouNote = "[[If You Can" + $curlyApos + "t Say Something Nice" + $ellipsis + "]]"
$maryNote = "[[Mary" + $curlyApos + "s Chromebook Setup]]"

# -----------------------------------------------------------------------
# Helper: Insert new entry BEFORE a given anchor line
# -----------------------------------------------------------------------
function Insert-Before {
    param(
        [string]$Text,
        [string]$Anchor,
        [string]$NewEntry
    )
    $idx = $Text.IndexOf($Anchor)
    if ($idx -ge 0) {
        return $Text.Substring(0, $idx) + $NewEntry + "`r`n" + $Text.Substring($idx)
    }
    return $null  # anchor not found
}

# -----------------------------------------------------------------------
# 1. Update existing Langness entry (add new link)
# -----------------------------------------------------------------------
$langOld = "### Langness, David`r`n- [[Is World Peace Just a Pipe Dream]]"
$langNew = "### Langness, David`r`n- [[Is World Peace Just a Pipe Dream]]`r`n- $ifYouNote"
if ($content.Contains($langOld) -and -not $content.Contains($ifYouNote)) {
    $content = $content.Replace($langOld, $langNew)
    Write-Output "UPDATED: Langness, David"
}

# -----------------------------------------------------------------------
# 2. New entries by section
# -----------------------------------------------------------------------

# B - Benzine, Vittoria (after Bauer, before Boehringer or next B-e+ entry)
$benEntry = "### Benzine, Vittoria`r`n- $lincolnNote"
$anchors = @("### Boehringer", "### Bohm", "### Bo ", "### Bond", "### Bott", "### Bradley", "### Braun")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $benEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Benzine, Vittoria" } else { Write-Output "WARN: could not place Benzine" }

# G - Goldberg, Ken (after Gibran, before Graber/Groff/Grover)
$gbEntry = "### Goldberg, Ken`r`n- $moravecNote"
$anchors = @("### Goett", "### Graber", "### Groff", "### Grover", "### Greene,", "### H`r`n")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $gbEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Goldberg, Ken" } else { Write-Output "WARN: could not place Goldberg" }

# G - Greene, Belle da Costa (after Goldberg, before Graber/Groff)
$greeneEntry = "### Greene, Belle da Costa`r`n- $lincolnNote"
$anchors = @("### Graber", "### Groff", "### Grover", "### Gupta", "### ## H")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $greeneEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Greene, Belle da Costa" } else { Write-Output "WARN: could not place Greene" }

# H - Ham, Larissa (after Hahn, before Haley)
$hamEntry = "### Ham, Larissa`r`n- $fungiNote"
$result = Insert-Before $content "### Haley," $hamEntry
if ($null -ne $result) { $content = $result; Write-Output "ADDED: Ham, Larissa" } else { Write-Output "WARN: could not place Ham" }

# H - Holzer, Harold (after Handa, before next H-o entry)
$holzerEntry = "### Holzer, Harold`r`n- $lincolnNote"
$anchors = @("### Hooper", "### Hort", "### Howard", "### Howell", "### Hoyt", "### Huff", "### Hull", "### ## I")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $holzerEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Holzer, Harold" } else { Write-Output "WARN: could not place Holzer" }

# K - Kodali, Maheedhar (after Kennedy, before Ko* entries)
$kodEntry = "### Kodali, Maheedhar`r`n- $nasalNote"
$anchors = @("### Koh", "### Korn", "### Kronick", "### Kruse", "### ## L")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $kodEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Kodali, Maheedhar" } else { Write-Output "WARN: could not place Kodali" }

# L - Leach, Sam (after Lawson, before Leasca)
$leachEntry = "### Leach, Sam`r`n- $fungiNote"
$result = Insert-Before $content "### Leasca," $leachEntry
if ($null -ne $result) { $content = $result; Write-Output "ADDED: Leach, Sam" } else { Write-Output "WARN: could not place Leach" }

# M - Minchin, Tim (after Marshall, before Mitchell/Moore)
$minchinEntry = "### Minchin, Tim`r`n- $fungiNote"
$anchors = @("### Mitchell", "### Moore", "### Morgan", "### Morris")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $minchinEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Minchin, Tim" } else { Write-Output "WARN: could not place Minchin" }

# M - Moravec, Hans (after Minchin, before Morgan)
$moravecEntry = "### Moravec, Hans`r`n- $moravecNote"
$anchors = @("### Morgan", "### Morris", "### Moss", "### Muir")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $moravecEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Moravec, Hans" } else { Write-Output "WARN: could not place Moravec" }

# N - Narayana, Madhu Leelavathi (before Narayanan)
$narEntry = "### Narayana, Madhu Leelavathi`r`n- $nasalNote"
$result = Insert-Before $content "### Narayanan," $narEntry
if ($null -ne $result) { $content = $result; Write-Output "ADDED: Narayana, Madhu Leelavathi" } else { Write-Output "WARN: could not place Narayana" }

# O - Ouellette, Mary (after O'Brien entries)
$ouelEntry = "### Ouellette, Mary`r`n- $maryNote"
$anchors = @("### Oz,", "### ## P", "`r`n## P`r`n")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $ouelEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Ouellette, Mary" } else { Write-Output "WARN: could not place Ouellette" }

# P - Phillis, Michael (after Perrod area, before Ph+ entries)
$phillisEntry = "### Phillis, Michael`r`n- $chestnutNote"
$anchors = @("### Picard", "### Pierce", "### Philpot", "### Porter", "### Powell", "### Price")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $phillisEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Phillis, Michael" } else { Write-Output "WARN: could not place Phillis" }

# P - Pouliot, Alison (after Phillis, before Powell/Price)
$pouliotEntry = "### Pouliot, Alison`r`n- $fungiNote"
$anchors = @("### Powell", "### Price", "### ## R", "`r`n## R`r`n")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $pouliotEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Pouliot, Alison" } else { Write-Output "WARN: could not place Pouliot" }

# S - Sarna, Susan (before Schedule)
$sarnaEntry = "### Sarna, Susan`r`n- $lincolnNote"
$result = Insert-Before $content "### Schedule," $sarnaEntry
if ($null -ne $result) { $content = $result; Write-Output "ADDED: Sarna, Susan" } else { Write-Output "WARN: could not place Sarna" }

# S - Shetty, Ashok (after Sarna area, before Shoghi/Sibley)
$shettyEntry = "### Shetty, Ashok`r`n- $nasalNote"
$anchors = @("### Shoghi", "### Sibley", "### Silver", "### Simon", "### Simons")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $shettyEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Shetty, Ashok" } else { Write-Output "WARN: could not place Shetty" }

# S - Soderquist, David (before Spear area)
$soderEntry = "### Soderquist, David`r`n- $lincolnNote"
$anchors = @("### Spear", "### Spencer", "### Stacy", "### Steele", "### Stein")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $soderEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Soderquist, David" } else { Write-Output "WARN: could not place Soderquist" }

# S - Spear, Felicity (after Soderquist, before Stacy/Steele)
$spearEntry = "### Spear, Felicity`r`n- $fungiNote"
$anchors = @("### Stacy", "### Steele", "### Stein", "### Stern", "### Stevens")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $spearEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Spear, Felicity" } else { Write-Output "WARN: could not place Spear" }

# W - Wells, Ernest (after Watson/Weakley/Webster area, before Wenger/West)
$wellsEntry = "### Wells, Ernest`r`n- $lincolnNote"
$anchors = @("### Wenger", "### West,", "### Weston", "### White,", "### Wicker")
$inserted = $false
foreach ($a in $anchors) {
    $result = Insert-Before $content $a $wellsEntry
    if ($null -ne $result) { $content = $result; $inserted = $true; break }
}
if ($inserted) { Write-Output "ADDED: Wells, Ernest" } else { Write-Output "WARN: could not place Wells" }

# -----------------------------------------------------------------------
# Write back with UTF-8 encoding (no BOM)
# -----------------------------------------------------------------------
[System.IO.File]::WriteAllText($indexPath, $content, [System.Text.Encoding]::UTF8)
Write-Output "`nPeople Index saved successfully."
