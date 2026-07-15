# Script to update Clippings files that have special characters in names
# Uses LiteralPath to avoid path interpretation issues

$clippingsPath = "C:\Users\awt\Sync\Obsidian\10 - Clippings"

# ============================================================
# Can You Say..."Hero" - just needs nav added, author fixed
# ============================================================
$heroFile = Get-ChildItem -LiteralPath $clippingsPath | Where-Object { $_.Name -like "*Hero*" } | Select-Object -First 1
if ($heroFile) {
    $content = Get-Content -LiteralPath $heroFile.FullName -Encoding UTF8 -Raw
    # Replace the author list with just Tom Junod, add nav
    $oldYaml = @"
---
title: "Can You Say..."Hero"? | Esquire | NOVEMBER 1998"
source: "https://classic.esquire.com/article/1998/11/1/can-you-say-hero"
author:
  - "[[MICHAEL PATERNITI]]"
  - "[[MARK WARREN]]"
  - "[[Scott Raab]]"
  - "[[Charles P. Pierce]]"
  - "[[SARA CORBETT]]"
  - "[[Merry Stockman]]"
  - "[[CAL FUSSMAN]]"
  - "[[TOM JUNOD]]"
  - "[[Tom Junod]]"
  - "[[Burton Hersh]]"
published:
created: 2026-02-26
description: "Fred Rogers has been doing the same small good thing for a very long time"
tags:
  - "TV"
  - "MrRogers"
  - "Children"
---
"@
    $newYaml = @"
---
nav: "[[00 - Home Dashboard/MOC - Reading & Literature]]"
title: "Can You Say Hero? | Esquire | November 1998"
source: "https://classic.esquire.com/article/1998/11/1/can-you-say-hero"
author:
  - "[[Tom Junod]]"
published: 1998-11-01
created: 2026-02-26
description: "Fred Rogers has been doing the same small good thing for a very long time"
tags:
  - TV
  - MrRogers
  - Children
  - Kindness
  - Esquire
---
"@
    $content = $content.Replace($oldYaml, $newYaml)
    [System.IO.File]::WriteAllText($heroFile.FullName, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Updated: $($heroFile.Name)"
}

# ============================================================
# Changing the direction of your ceiling fan
# ============================================================
$fanFile = Get-ChildItem -LiteralPath $clippingsPath | Where-Object { $_.Name -like "*ceiling fan*" } | Select-Object -First 1
if ($fanFile) {
    $content = Get-Content -LiteralPath $fanFile.FullName -Encoding UTF8 -Raw
    # Add nav to frontmatter
    $content = $content -replace '---\r?\ntitle: "Changing the direction of your ceiling fan can change your life"', "---`nnav: `"[[00 - Home Dashboard/MOC - Home & Practical Life]]`"`ntitle: `"Changing the direction of your ceiling fan can change your life`""
    # Remove boingboing READ THE REST sidebar items (everything from the first "- [![" related articles block)
    $sidebarPattern = '(?s)\r?\n- \[!\[.*?READ THE REST\].*?\n- \[!\[.*?READ THE REST\].*?\n- \[!\[.*?READ THE REST\].*?\n- \[!\[.*?READ THE REST\].*?\n- \[!\[.*?READ THE REST\].*?\n- \[!\[.*?READ THE REST\]\(.*?\)\s*$'
    $content = $content -replace $sidebarPattern, ''
    [System.IO.File]::WriteAllText($fanFile.FullName, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Updated: $($fanFile.Name)"
}

# ============================================================
# Discover Kolams
# ============================================================
$kolamFile = Get-ChildItem -LiteralPath $clippingsPath | Where-Object { $_.Name -like "*Kolam*" } | Select-Object -First 1
if ($kolamFile) {
    $content = Get-Content -LiteralPath $kolamFile.FullName -Encoding UTF8 -Raw
    # Add nav to frontmatter
    $content = $content -replace '---\r?\ntitle: "Discover Kolams', "---`nnav: `"[[00 - Home Dashboard/MOC - Science & Nature]]`"`ntitle: `"Discover Kolams"
    # Remove the social sharing buttons at the start of body (before main text)
    $content = $content -replace '\r?\nin \| May 20th, 2019 \[Leave a Comment\].*?\r?\n\r?\n\[Bluesky\].*?\[Share\]\(https://www\.addtoany\.com.*?\)\r?\n\r?\n', "`n`n"
    # Remove the duplicate sharing block at the end + support section + newsletter
    $socialEnd = '[Bluesky](https://www.openculture.com/#bluesky "Bluesky") [Facebook]'
    $idx = $content.LastIndexOf($socialEnd)
    if ($idx -gt 0) {
        $content = $content.Substring(0, $idx).TrimEnd()
    }
    # Fix hyphenated words: common patterns from the OCR hyphenation
    $fixes = @{
        'accom-plished' = 'accomplished'
        'geo-met-ri-cal' = 'geometrical'
        'demo-graph-ic' = 'demographic'
        'art-school' = 'art-school'
        'cur-ricu-lum' = 'curriculum'
        'rig-or' = 'rigor'
        'prac-ticed' = 'practiced'
        'every-where' = 'everywhere'
        'hum-ble' = 'humble'
        'mate-ri-als' = 'materials'
        'inter-weave' = 'interweave'
        'reli-gious' = 'religious'
        'philo-soph-i-cal' = 'philosophical'
        'mag-i-cal' = 'magical'
        'kolam artist' = 'kolam artist'
        'Tak-ing' = 'Taking'
        'coconut shell' = 'coconut shell'
        'kolam artist' = 'kolam artist'
        'fresh-ly' = 'freshly'
        'geo-met-ric' = 'geometric'
        'labyrinthine' = 'labyrinthine'
        'hexag-o-nal' = 'hexagonal'
        'flo-ral' = 'floral'
        'resem-bling' = 'resembling'
        'god-dess' = 'goddess'
        'pros-per-i-ty' = 'prosperity'
        'illus-tra-tion' = 'illustration'
        'pros-per-i-ty' = 'prosperity'
        'pass-ing' = 'passing'
        'crea-tures' = 'creatures'
        'Uni-ver-si-ty' = 'University'
        'San Fran-cis-co' = 'San Francisco'
        'The-ol-o-gy' = 'Theology'
        'Reli-gious Stud-ies' = 'Religious Studies'
        'pro-fes-sor' = 'professor'
        'describ-ing' = 'describing'
        'ful-fill-ment' = 'fulfillment'
        'Hin-du' = 'Hindu'
        'karmic oblig-a-tion' = 'karmic obligation'
        'thou-sand souls' = 'thousand souls'
        'gen-uine' = 'genuine'
        'math-e-mati-cians' = 'mathematicians'
        'com-put-er sci-en-tists' = 'computer scientists'
        'recur-sive' = 'recursive'
        'con-tin-u-ing' = 'continuing'
        'sub-pat-tern' = 'subpattern'
        'com-plex' = 'complex'
        'over-all' = 'overall'
        'e-luc-i-date' = 'elucidate'
        'fun-da-men-tal' = 'fundamental'
        'math-e-mat-i-cal' = 'mathematical'
        'tra-di-tion-al' = 'traditional'
        'prac-ti-tion-ers' = 'practitioners'
        'mas-tery' = 'mastery'
        'with-out' = 'without'
        'stand-ing' = 'standing'
        'hard-ly' = 'hardly'
        'dying out' = 'dying out'
        'cre-ators' = 'creators'
        'expo-sure' = 'exposure'
        'every-where' = 'everywhere'
        'occa-sion-al' = 'occasional'
        'com-plex-i-ty' = 'complexity'
        'geom-e-try' = 'geometry'
        'accord-ing' = 'according'
        'for-m' = 'form'
        'beau-ty' = 'beauty'
        'Relat-ed' = 'Related'
        'Con-tent' = 'Content'
        'Math-e-mat-ics' = 'Mathematics'
        'Vis-i-ble' = 'Visible'
        'Extra-or-di-nary' = 'Extraordinary'
        'Math-e-mat-i-cal' = 'Mathematical'
        'Iran-ian' = 'Iranian'
        'Ele-gant' = 'Elegant'
        'Geom-e-try' = 'Geometry'
        'Islam-ic' = 'Islamic'
        'Com-plex' = 'Complex'
        'Intro-duc-tion' = 'Introduction'
        'Base in Seoul' = 'Based in Seoul'
        'Col-in Mar-shall' = 'Colin Marshall'
        'broad-casts' = 'broadcasts'
        'lan-guage' = 'language'
        'Cul-ture' = 'Culture'
        'State-less' = 'Stateless'
        'Walk through' = 'Walk through'
        'Ange-les' = 'Angeles'
        'Cin-e-ma' = 'Cinema'
        'Fol-low' = 'Follow'
        'Face-book' = 'Facebook'
        'Insta-gram' = 'Instagram'
        'Based in Seoul' = 'Based in Seoul'
        'k olam' = 'kolam'
    }
    foreach ($key in $fixes.Keys) {
        $content = $content.Replace($key, $fixes[$key])
    }
    [System.IO.File]::WriteAllText($kolamFile.FullName, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Updated: $($kolamFile.Name)"
}

Write-Host "Done"
