# Find actual filenames for all I-Z files in 20 - Permanent Notes
$path = "D:\Obsidian\Main\20 - Permanent Notes"
$patterns = @(
    "I let my local LLM*", "Is it eczema*", "Israel bans*", "Jacqueline Depaul*",
    "Kindle 3*", "Kindle 4*", "LiveCode*", "LNS JUST*", "Making Drums*",
    "Mapping the Uncharted*", "Marshall Effron*", "Micro*Meteorite*",
    "Microsoft Sculpt*", "Mix Magazine*", "Model Behavior*", "Mr. Money*",
    "NLP Strategies*", "NRICH*", "Nagios NRPE*", "National Semiconductor*",
    "Naw Ruz*", "Ninite*", "ORDER BY*", "Obsidian Frontmatter*",
    "Old Man and the Sea*", "Oracle*", "Order Postcards*", "PersonalWeb*DFW*",
    "Playing a Musical*", "Pluto*", "PrintFriendly*", "QR*Code*",
    "Quick list*", "ROOTS*", "Recorder Fingering*", "Refrigerator Dills*",
    "Rick Steves*", "S100*", "Samsung Galaxy*", "Scientists discover*",
    "Set Up Windows*", "SourceForge*", "Spiced Pumpkin*", "Summit At Sea*",
    "Switched On Bach*", "The Last Lecture*", "The Vinyl*", "Tom Bihn*",
    "Transactions Screen*", "WCWBF*Trans*", "Which Veggie*", "William Kamkwamba*",
    "Wind Chimes*", "Windows and Linux*", "WorkRave*", "xkcd*Worth*"
)
foreach ($p in $patterns) {
    $found = Get-ChildItem $path -Filter $p
    if ($found) {
        foreach ($f in $found) { Write-Host "$p => $($f.Name)" }
    } else {
        Write-Host "$p => NOT FOUND"
    }
}
