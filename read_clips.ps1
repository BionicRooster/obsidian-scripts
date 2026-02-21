$base = 'D:\Obsidian\Main\10 - Clippings'
$targetFiles = @(
    "All in One - System Rescue Toolkit Lite.md",
    "Andy's Ocarina Recommendations.md",
    "Archaeologists Discover They Have Been Excavating Lost Assyrian City.md",
    "Archaeologists Found the Long-Buried Remains of a 2,500-Year-Old Roman Society.md",
    "Book Summary Request.md",
    "Chasing Quicksilver History in Beautiful Big Bend.md",
    "Check the Integrity.md",
    "Checkout.md",
    "Collect general trib.md",
    "Device Listing  My A.md",
    "Did Neanderthals Die Out Because of the Paleo Diet.md",
    "Differences in recorders.md",
    "Digi-Comp II First Edition Evil Mad Scientist.md",
    "Dunning-Kruger effect - Wikipedia.md",
    "firefox always show.md",
    "Fruit Walls Urban Farming in the 1600s.md",
    "Heavy Sleepers' Alarm Clock.md",
    "How to Choose New Countertops, Cabinets, and Floors.md",
    "How to find easement.md",
    "How to play all the.md",
    "If You're Tired of F.md",
    "Intel's revolutionary 4004 Chip.md",
    "LUCY is a magical drawing tool based on the classic camera lucida.md",
    "Making the `$25k Odaiko Drum on a Budget.md",
    "Mermaid Chart.md",
    "Obituary - John Henry White.md",
    "Pace Layers - Six layers of robust and adaptable civilizations.md",
    "Perplexity.md",
    "Podium vs Lectern.md",
    "Rethinking Neanderthals.md",
    "Scientists Found the Temperature That Makes Cookies Turn Out Better.md",
    "Secret Tunnel May Finally Solve the Mysteries of Teotihuacan.md",
    "Seeking A Life That Is Spiritual But Not Religious - Utne.md",
    "Set Up a Fully Automated Media Center.md",
    "Setting Early American Sites on Fire.md",
    "SMART Goals.md",
    "So You Want My Job Luthier (Guitar Maker).md",
    "StackSkills.md",
    "Statement by the Republic of Slovenia.md",
    "Submarine finds anomalous structures in Antarctica.md",
    "The Aliens Are Silent Because They Are Extinct.md",
    "The College Student Who Decoded the Data Hidden in Inca Knots.md",
    "The First Commons Country - Utne Magazine.md",
    "The Instant Mongolian Home.md",
    "The Post-American Internet 39C3, Hamburg, Dec 28.md",
    "The Prof's Book Alan.md",
    "The Singularity.md",
    "This Archaeological Site in Texas Might Hold the Secret to the Universe.md",
    "Trailer homesteading in the Mojave.md",
    "Travel With Ubikey Secure Login.md",
    "TV dialogue sound 3 simple tweaks.md",
    "Ukraine's mammoth bone shelters were used 18,000 years ago.md",
    "Under the Bed Nightlight.md",
    "Understanding Types of Servo Motors.md",
    "Unearthing the World of Jesus.md",
    "Use the Mobile Passport App to Breeze Through Customs.md",
    "Wayback Machine.md",
    "What are small language models 1.md",
    "What Killed These Marine Reptiles.md",
    "What's it like to live in a yurt in Northern Montana.md",
    "Winegard Elite 7550.md",
    "Winxvideo AI receipt.md",
    "Writage License.md",
    "Yukagir mammoth.md",
    "Zapier Learn.md",
    "A quote by Abdul'-Baha - Slave to your moods.md"
)

foreach ($fname in $targetFiles) {
    $path = Join-Path $base $fname
    # Try exact path first, then glob
    if (-not (Test-Path -LiteralPath $path)) {
        $pattern = Join-Path $base ($fname.Substring(0, [Math]::Min(20, $fname.Length)) + '*')
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $path = $found.FullName }
        else { Write-Output "===SKIP: $fname (NOT FOUND)==="; continue }
    }
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $len = $content.Length
    $preview = $content.Substring(0, [Math]::Min(600, $len))
    Write-Output "===FILE: $fname (len=$len)==="
    Write-Output $preview
    Write-Output "===END==="
}
