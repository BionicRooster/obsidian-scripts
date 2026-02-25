param()
$vaultRoot  = "D:\Obsidian\Main"
$outputFile = "C:\Users\awt\people_name_results.txt"
$excludeFolders = @("15 - People","00 - Home Dashboard","00 - Journal","Templates")
$nonNameWords = @(
    "The","How","What","This","That","My","In","For","To","A","An","Of",
    "And","Or","Is","Are","Was","Were","With","From","New","Old","All",
    "About","Your","Our","Their","Its","It","We","You","He","She","They",
    "Not","But","So","If","On","At","By","As","Up","Do","Go","See","Get",
    "Can","May","Will","Has","Have","Had","Been","Be","Make","Take","Come",
    "Know","Use","Find","Give","Tell","Keep","Let","Put","Set","Run","Try",
    "Ask","Say","Show","Play","Move","Live","Work","Look","Turn","Start",
    "Part","Some","More","Most","One","Two","Three","Four","Five","Six",
    "Black","White","Green","Red","Blue","Yellow","Brown","Dark","Light",
    "Big","Small","High","Low","Long","Short","Good","Bad","Best","First",
    "Last","Next","Other","Same","Only","Just","Also","Even","Still","Well",
    "Now","Then","Here","There","When","Where","Why","Who","Which","While",
    "After","Before","During","Over","Under","Between","Through","Without",
    "North","South","East","West","American","United","National","Global",
    "World","Life","Time","Year","Day","Week","Month","Home","House","School",
    "Book","Page","Note","List","File","Data","Case","Type","Way","Place",
    "People","Person","Man","Woman","Men","Women","Child","Children","Family",
    "Group","Team","Club","Society","Community","Company","Food","Water","Air",
    "Earth","Fire","Mind","Body","Soul","Heart","Hand","Eye","Face","Head",
    "Point","Level","Side","Area","Field","Line","Word","Name","Number",
    "Power","Force","Energy","System","Process","State","Issue","Topic",
    "Summary","Index","Master","Main","MOC","Hub","Dashboard","Overview",
    "Introduction","Chapter","Section","Appendix","Volume","Edition",
    "Report","Review","Study","Research","Analysis","Guide","Manual",
    "Reading","Writing","Speaking","Thinking","Learning","Teaching",
    "Making","Building","Creating","Finding","Using","Getting","Taking",
    "Simple","Easy","Hard","Fast","Slow","Early","Late","Free","Full",
    "Open","Close","Right","Wrong","True","False","Real","Actual",
    "General","Special","Common","Local","Public","Private","Personal",
    "Annual","Daily","Weekly","Monthly","Modern","Ancient","Classic",
    "Basic","Advanced","Central","Primary","Secondary","Final","Total",
    "Great","Little","Much","Many","Few","Both","Each","Every","Any",
    "Always","Never","Often","Sometimes","Usually","Recently","Currently",
    "Already","Again","Back","Down","Out","Off","Far","Near","Away",
    "Together","Apart","Inside","Outside","Above","Below","Across","Along",
    "Toward","Against","Beyond","Within","Among","Around","Behind","Beside",
    "Holy","Sacred","Divine","Lord","God","Allah","Buddha",
    "Than","Such","Less","Very","Really","Quite","Rather","Mostly","Truly",
    "These","Those","Them","Him","Her","Whose","Whom",
    "Neither","Either","Nor","Yet","Once","Twice","Almost","Enough",
    "Second","Third","Based","Former","Founded","Named","Late","Per",
    "Kitchen","Cuisine","Recipe","Recipes","Dish","Dishes","Meal","Meals"
)
$nonNameSet = @{}
foreach ($w in $nonNameWords) { $nonNameSet[$w] = $true }

function Test-LooksLikeName {
    param([string]$candidate)
    $candidate = $candidate.Trim()
    if ($candidate -match "\d") { return $false }
    $words = $candidate -split "\s+"
    if ($words.Count -lt 2 -or $words.Count -gt 5) { return $false }
    foreach ($word in $words) {
        if ($word -notmatch "^[A-Z]") { return $false }
        if ($word.Length -lt 2) { return $false }
        if ($nonNameSet.ContainsKey($word)) { return $false }
    }
    return $true
}

function Clean-AuthorValue {
    param([string]$raw)
    $c = $raw -replace "^[\s\-\p{Pi}\p{Pf}""]+", ""
    $c = $c -replace "[\s\p{Pi}\p{Pf}""]+$", ""
    return $c.Trim()
}

Write-Host "Scanning vault for .md files..."
$allFiles = Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" | Where-Object {
    $fp = $_.FullName; $ex = $false
    foreach ($folder in $excludeFolders) {
        if ($fp -like ("*\" + $folder + "\*") -or $fp -like ("*\" + $folder)) { $ex = $true; break }
    }
    if ($_.Name -eq "People Index.md") { $ex = $true }
    -not $ex
}
Write-Host ("Found " + $allFiles.Count + " files to scan.")

$nameToFiles = @{}

function Add-NameRecord {
    param([string]$name,[string]$filePath)
    $name = ($name -replace "\s+"," ").Trim()
    if ([string]::IsNullOrWhiteSpace($name) -or $name.Length -lt 3) { return }
    if (-not $nameToFiles.ContainsKey($name)) {
        $nameToFiles[$name] = [System.Collections.Generic.List[string]]::new()
    }
    if (-not $nameToFiles[$name].Contains($filePath)) { $nameToFiles[$name].Add($filePath) }
}

$fc = 0; $tot = $allFiles.Count
foreach ($file in $allFiles) {
    $fc++
    if ($fc % 500 -eq 0) { Write-Host ("  Processing " + $fc + " of " + $tot + "...") }
    try { $lines = [System.IO.File]::ReadAllLines($file.FullName,[System.Text.Encoding]::UTF8) }
    catch { Write-Warning ("Could not read: " + $file.FullName); continue }
    $rp = $file.FullName.Substring($vaultRoot.Length).TrimStart("\")

    # METHOD 1: Frontmatter author/authors fields
    $inFM=$false; $fmDone=$false; $inAB=$false; $fmStart=$false
    foreach ($line in $lines) {
        if (-not $fmStart) {
            if ($line.Trim() -eq "---") { $fmStart=$true; $inFM=$true }
            continue
        }
        if ($inFM -and -not $fmDone) {
            if ($line.Trim() -eq "---") { $fmDone=$true; $inFM=$false; break }
            if ($line -match "^authors?\s*:\s*(.*)$") {
                $val = $Matches[1].Trim()
                if ($val -ne "" -and $val -ne "[]" -and $val -ne "null") {
                    if ($val -match "^\[(.+)\]$") {
                        foreach ($item in ($Matches[1] -split ",")) {
                            $c = Clean-AuthorValue $item
                            if ($c.Length -gt 2) { Add-NameRecord -name $c -filePath $rp }
                        }
                        $inAB = $false
                    } else {
                        $c = Clean-AuthorValue $val
                        if ($c.Length -gt 2) { Add-NameRecord -name $c -filePath $rp }
                        $inAB = $false
                    }
                } else { $inAB = $true }
                continue
            }
            if ($inAB) {
                if ($line -match "^\s+-\s+(.+)$") {
                    $c = Clean-AuthorValue $Matches[1]
                    if ($c.Length -gt 2) { Add-NameRecord -name $c -filePath $rp }
                } elseif ($line -match "^\S") { $inAB = $false }
            }
        }
    }

    $fullContent = [string]::Join([char]10, $lines)

    # METHOD 2: Wikilinks that look like person names
    foreach ($m in [regex]::Matches($fullContent, "\[\[([^\]|#]+)(?:\|[^\]]*)?\]\]")) {
        $lt = $m.Groups[1].Value.Trim()
        if ($lt -match "/") { $lt = ($lt -split "/")[-1].Trim() }
        if (Test-LooksLikeName -candidate $lt) { Add-NameRecord -name $lt -filePath $rp }
    }

    # METHOD 3a: "by FirstName LastName" patterns
    foreach ($m in [regex]::Matches($fullContent, "(?i)\bby\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})\b")) {
        $name = $m.Groups[1].Value.Trim()
        if (Test-LooksLikeName -candidate $name) { Add-NameRecord -name $name -filePath $rp }
    }

    # METHOD 3b: Em-dash attributions (Unicode en/em dash)
    foreach ($m in [regex]::Matches($fullContent, "[\u2014\u2013]\s*([A-Z][a-z]+\s+[A-Z][a-z]+)")) {
        $name = $m.Groups[1].Value.Trim()
        if (Test-LooksLikeName -candidate $name) { Add-NameRecord -name $name -filePath $rp }
    }

    # METHOD 3c: Role labels (contributor, editor, translator, etc.)
    foreach ($m in [regex]::Matches($fullContent, "(?i)(?:contributor|editor|translator|foreword by|introduction by|illustrated by)\s*[:\s]+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})")) {
        $name = $m.Groups[1].Value.Trim()
        if (Test-LooksLikeName -candidate $name) { Add-NameRecord -name $name -filePath $rp }
    }
}

Write-Host ("Scan complete. Unique names: " + $nameToFiles.Count)
$out = [System.Collections.Generic.List[string]]::new()
$out.Add("# People Names Found in Obsidian Vault")
$out.Add("# Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$out.Add("# Total unique names: " + $nameToFiles.Count)
$out.Add("# Files scanned: " + $tot)
$out.Add("")
$out.Add("=" * 80)
$out.Add("")
$sorted = $nameToFiles.Keys | Sort-Object { ($_ -split "\s+")[-1] }, { $_ }
foreach ($name in $sorted) {
    $out.Add("NAME: " + $name)
    foreach ($f in ($nameToFiles[$name] | Sort-Object)) { $out.Add("  FILE: " + $f) }
    $out.Add("")
}
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($outputFile, $out, $enc)
Write-Host ("Done. Results saved to: " + $outputFile)
Write-Host ("Total unique names: " + $nameToFiles.Count)
