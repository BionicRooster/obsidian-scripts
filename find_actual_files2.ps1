$path = "D:\Obsidian\Main\20 - Permanent Notes"
$patterns = @(
    "I let my local*", "Is it eczema*", "Israel*fluorid*", "Jacqueline*TikTok*",
    "Kindle 3*", "Kindle*PC*", "Making Drum*", "Mapping*Uncharted*",
    "Micro*Meteor*", "Microsoft Sculpt*", "Mix Mag*", "Model Behavior*",
    "Mr*Money*Mustache*", "NLP Strat*", "NRICH*", "Nagios*NRPE*",
    "National Semi*", "Obsidian Frontmatter*", "Old Man*Sea*", "Oracle*",
    "PersonalWeb*DFW*", "Playing*Musical*Saw*", "Pluto*Planet*",
    "PrintFriendly*", "QR*", "Quick list*keyboard*", "ROOTS*",
    "Recorder*Finger*", "Rick*Steves*", "Samsung*Galaxy*Tab*",
    "Summit*Sea*", "Switched*Bach*", "The Last Lect*", "The Vinyl*",
    "Tom Bihn*"
)
foreach ($p in $patterns) {
    $found = Get-ChildItem $path -Filter $p
    if ($found) {
        foreach ($f in $found) { Write-Host "$p => $($f.Name)" }
    } else {
        Write-Host "$p => NOT FOUND"
    }
}
