# Script to check and add "Home" tag to files linked in MOC - Home & Practical Life
# UTF-8 encoding is preserved throughout

param(
    [string]$VaultPath = "D:\Obsidian\Main"
)

# Counter variables
$added = 0
$alreadyHad = 0
$notFound = 0
$skipped = 0

# List of files to check from the MOC - extracted and deduplicated
$filesToCheck = @(
    "Delores Joiner Photo", "James Tolbert (Talbot) Battle records", "Alfred Wayne Talbot",
    "What is a Centimorga", "Screen clipping take", "Vera Talbot - Google", "Genealogy library we",
    "Vera Irene Talbot", "Thomas Talbot", "Chester Hale Talbot", "Matthew Talbot Sr",
    "Bailey Talbot 1", "Ben Charles Talbot Obit", "Florence E Talbot", "Clarence H Talbot",
    "Lorrie Talbot Old pi", "Jerry Talbot obituary Newspaper", "Clayton Talbot 1",
    "Talbot Reference Books", "Carson Wayne Talbot", "Nadine Talbot Divorce Alfred E Talbot 1932",
    "Obituary - John Henry White", "Hale Talbot", "Jerry Talbot Obit", "DNA", "Did the Greeks Help",
    "Col Mathew Talbot", "Key Data Perspecti", "Mom's divorce", "Hale R Talbot", "Jerry Talbot",
    "Autosomal Inheritance", "Genealogy Jamboree", "Talbot Heredity", "Geneology 1",
    "PersonalWeb - Genealogy Help sites", "Talbot Address from",
    "Alfred E Talbot and Nadine Sutliff Talbot Divorce", "Genealogy Help sites", "Matthew Talbot Sons",
    "Egill Aunsson King", "Alfred W. Talbot Sr", "The Living Descendants of British Royal Blood Talbot Field",
    "Pagan Celebration of Yule", "Genetic Genealogy", "Probate more than a Will",
    "Making the $25k Odaiko Drum on a Budget", "Clean Air Floor Remodeling", "Removing Lock Screen",
    "Fix the Machine Not", "How to Erase Yoursel", "5 Tips on Building with SIPs",
    "How to Make DIY Weed Killer", "Jason's 800 Sq. Ft.", "All in One - System Rescue Toolkit Lite",
    "Low Profile Washer H", "Owens Corning Garage", "D and R Drywall Remodeli", "Nature as God Repair",
    "How to Choose New Countertops Cabinets and Floors", "Build With SIPs", "Check the Integrity",
    "FIRST TWO WEEKS in a CAMPERVAN", "Can You Buy a Quality Cabin For $5k", "Creating my first home server",
    "11 SUVs I Would Not Buy", "This holiday season", "How to Migrate to a",
    "Install the Google Play Store on the Amazon Fire Tablet", "Felipe Sanchez Landscaping",
    "Drywall Repair", "Microwave receipt", "How to Organize Your Entire Life with Trello",
    "Driveway Repair", "Garage Sales Yard", "Obsidian maintenance script", "Website claims to fi",
    "I've Got House Envy", "These 5 features make Echo Useful", "How to Get Your Apar",
    "How a group of neighbors created their own Internet service", "Wood Pallet Project",
    "Advice to Californians Building New Homes After The Fires", "Sustainable is Good",
    "Trailer homesteading in the Mojave", "Not Your Typical Yu", "Is Cordwood Masonry",
    "Top 8 Insulation Opt", "Farmer makes surpris", "The couple that quit renting to live in a tiny house",
    "Earthbag Construction", "10 Reasons to Build an Earthbag House", "Fruit Walls Urban Farming in the 1600s",
    "Low-cost Multipurpose Minibuilding Made with Earthbags", "Earthships Inspiration",
    "How to Build a Rocket Stove Using Cement Blocks", "George Nez Habitat",
    "Cool Tools Dickinson Marine Fireplace", "How to Make a Tipi",
    "An invasive plant is painting Iceland's deserts purple", "Fruit snack 3 in 1 Apple Tree",
    "Baker Creek Heirloom", "Blenheim Apricot Trees", "The Best Raised Gard", "Rogue Hoes- Garden H",
    "More kissing less k", "Baker Creek Heirloom Seeds", "Diet info for Cindy'", "The Northwest's Earl",
    "Sweet southern Cherry", "How to Grow Potatoes", "Replies", "How to Care for Air",
    "How to Grow a Fig Tr", "The EarthTainer", "'A living pantry' how an urban food forest in Arizona became a model for climate action",
    "How to use an olla t", "Urban Farm Magazine", "Create Small Fruit T",
    "Communities Grow Stronger with Fruit Tree Projects", "Turtle plant",
    "Upgrading Our RV Internet Connection", "Why Every RVer Should Own An Instant Pot",
    "Your Ultimate Guide To The National Park-To-Park Highway",
    "TV dialogue sound 3 simple tweaks", "How Akira Kurosawa's", "Dances With Wolves Dialogue",
    "Holly Near - Holly and Ronnie's Timeline", "An Oral History of Laurel Canyon",
    "How a Lost Marx Brothers Musical Found Its Way Back Onstage", "Tim's Vermeer Optical Tool",
    "The Oral History of", "Vic Fontaine Deep Space Nine's Safe Harbor In Wartime", "New Documentary Film",
    "The Simple Dollar", "The Dresden Files Books TV and Film",
    "Houston's Hobbit Cafe Has Welcomed Diners to the Shire for 50 Years", "Proposed movie list",
    "Vermeer's paintings might be 350 year-old color photographs", "The Women of Rohan",
    "A Mongolian Heavy Metal Band", "Texas Television Te", "The Daniel Norris Co",
    "How My Aunt Marge Ended Up in the Deep Freeze",
    "How Cincinnati Salvaged the Nation's Most Dangerous Neighborhood", "Five Steps to Take I",
    "Microsavings", "5 Strategies to Demystify the Learning Process for Struggling Students",
    "Changing These 4 Bel", "Why Invest", "I Copied 15 Japanese", "mind.Depositor by Sc",
    "Hand-Build an Earth Sheltered House", "National Park Maps", "Acknowledging memori",
    "8 Tiny Japanese Habits That Make a Massive Difference", "Using Virtual Desktops",
    "After a Death Occurs", "Get Better at Getting better - Kaizen Productivity Philosophy",
    "Six Habits of Highly Grateful People – Utne Magazine", "Introduction to the Middle Way Method",
    "Make your life paper", "Confusion on Where Money Lent via Kiva Goes", "How to Approach Retirement",
    "Cybercrime 3.0 stealing whole houses", "KeyRingThing Creates", "How to Sort Mail",
    "Dyslexia May Be the Brain Struggling to Adapt", "Education 3.0", "Nozbe and Evernote",
    "Uni Kuru Toga The Ultimate Pencil", "My Key Finder", "How to Read the Grocery Stickers",
    "Noodler's Inks", "Trevor Noah Explains How Kintsugi", "XJ Unisex Running Socks",
    "LUCY is a magical dr", "The Genius of Harry", "Land Navigation Manual", "Gestalt principles",
    "Primary Metaphor", "Zigzag trenches", "Contentment - What you Have Relative to What you Want",
    "Dunning–Kruger effect - Wikipedia", "A Visual Guide to Glasses and Frame Measurements",
    "FOL BOARD MTG", "FOL Organizational I", "FOL Postage Due Account", "FOL LGL Tribute Proc",
    "CC Information", "Communications team", "Compare Zeffy and Li", "eMail Opt Out Requirements",
    "Remove member Helen", "Bertram B", "PersonalWeb - 2021 Giving Season", "Little Green Light F",
    "Little Green Light -", "LGL Unsaved Records", "The 10 Best Direct M",
    "GCCMA Overview", "GCCMA History", "GCCMA Contacts", "GCCMA meeting Octobe", "Georgetown Cultural",
    "Citizens Memorial Ga", "Help needed to revive Willie Hall Center",
    "Bryan Burrough HCAS", "Mark Pryor HCAS"
)

# People to skip (simple contact files)
$peopleToSkip = @(
    "Chuck Collins", "Angela Bryant", "Jody Patterson", "Karen Harrison", "Ricki McMillian",
    "Mindy Klein", "Sally Miculek", "Wayne Talbot", "Terrie Hahn", "Kalena Powell",
    "Diane Moukourie", "Diane Sandlin"
)

# MOC files to skip
$mocToSkip = @(
    "Master MOC Index", "MOC - Home & Practical Life"
)

Write-Host "Starting Home tag check..."
Write-Host "Total files to check: $($filesToCheck.Count)"
Write-Host ""

# Process each file
foreach ($filename in $filesToCheck) {
    # Skip people files
    if ($peopleToSkip -contains $filename) {
        Write-Host "SKIP (Person): $filename"
        $skipped++
        continue
    }

    # Skip MOC files
    if ($mocToSkip -contains $filename) {
        Write-Host "SKIP (MOC): $filename"
        $skipped++
        continue
    }

    # Find the file - search for markdown files matching the name
    $foundFiles = @()

    # Try exact match first with wildcard for extensions
    $searchPattern = "$filename.md"
    $foundFiles = Get-ChildItem -Path $VaultPath -Filter "$searchPattern" -Recurse -ErrorAction SilentlyContinue

    # If not found, try a more flexible search
    if ($foundFiles.Count -eq 0) {
        $foundFiles = Get-ChildItem -Path $VaultPath -Filter "*$filename*" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq ".md" } | Select-Object -First 5
    }

    if ($foundFiles.Count -eq 0) {
        Write-Host "NOT FOUND: $filename"
        $notFound++
        continue
    }

    # Process the first found file
    $file = $foundFiles[0]

    # Skip if in "09 - Kindle Clippings"
    if ($file.FullName -like "*09 - Kindle Clippings*") {
        Write-Host "SKIP (Kindle): $($file.Name)"
        $skipped++
        continue
    }

    # Read file with UTF-8 encoding
    $content = Get-Content -Path $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue

    if ($null -eq $content) {
        Write-Host "ERROR reading: $($file.Name)"
        $notFound++
        continue
    }

    # Check if file already has Home tag (case-insensitive)
    $hasHomeTag = $false

    # Check for YAML frontmatter tags
    if ($content -match '(?i)tags:\s*\[.*\bHome\b.*\]') {
        $hasHomeTag = $true
    }

    # Check for inline #Home tag
    if ($content -match '(?i)#Home\b') {
        $hasHomeTag = $true
    }

    if ($hasHomeTag) {
        Write-Host "HAS TAG: $($file.Name)"
        $alreadyHad++
        continue
    }

    # File doesn't have Home tag - need to add it
    # Check if it has YAML frontmatter (starts with ---)
    $lines = @($content)
    if ($lines[0] -eq "---") {
        # Has frontmatter - find the closing --- and add/update tags
        $foundClosing = $false
        $closingLineIndex = -1

        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -eq "---") {
                $closingLineIndex = $i
                $foundClosing = $true
                break
            }
        }

        if ($foundClosing) {
            # Search for existing tags line
            $tagsLineIndex = -1
            for ($i = 1; $i -lt $closingLineIndex; $i++) {
                if ($lines[$i] -match '^tags:\s*') {
                    $tagsLineIndex = $i
                    break
                }
            }

            if ($tagsLineIndex -ge 0) {
                # Update existing tags line
                $lines[$tagsLineIndex] = $lines[$tagsLineIndex] -replace '(\[|$)', ',' + ' Home]' -replace '\],', ']'
                if ($lines[$tagsLineIndex] -notmatch 'Home') {
                    $lines[$tagsLineIndex] = $lines[$tagsLineIndex] -replace '(\])', ', Home]'
                }
            } else {
                # Add new tags line before closing ---
                [array]$newLines = $lines[0..$($closingLineIndex-1)]
                $newLines += "tags: [Home]"
                $newLines += $lines[$closingLineIndex..$($lines.Count-1)]
                $lines = $newLines
            }
        }
    } else {
        # No frontmatter - create new YAML with Home tag
        $newContent = @("---", "tags: [Home]", "---", "") + $lines
        $lines = $newContent
    }

    # Write back with UTF-8 encoding
    $newContent = $lines -join "`n"
    Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8 -ErrorAction SilentlyContinue

    Write-Host "ADDED: $($file.Name)"
    $added++
}

Write-Host ""
Write-Host "========== SUMMARY =========="
Write-Host "Added Home tag: $added"
Write-Host "Already had tag: $alreadyHad"
Write-Host "Not found: $notFound"
Write-Host "Skipped: $skipped"
Write-Host "Total processed: $($added + $alreadyHad + $notFound + $skipped)"
