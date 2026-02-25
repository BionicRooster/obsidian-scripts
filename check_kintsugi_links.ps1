$vault = "D:\Obsidian\Main"
$links = @(
    "02 - Working Projects\Linux home office server",
    "20 - Permanent Notes\How the coronavirus",
    "01\NLP_Psy\Time Line Therapy",
    "20 - Permanent Notes\How to Get Your Apartment Off the Grid",
    "20 - Permanent Notes\SCORM - SCORM Explai",
    "00 - Home Dashboard\Master MOC Index",
    "20 - Permanent Notes\The boy who harnessed the wind",
    "01\Religion\World Peace",
    "20 - Permanent Notes\Why humans have allergies",
    "00 - Home Dashboard\MOC - Home & Practical Life",
    "MOC - NLP & Psychology"
)
foreach ($l in $links) {
    $path = "$vault\$l.md"
    $exists = Test-Path $path
    Write-Host "$exists | $l"
}
