# Apply tags to files in 20 - Permanent Notes (I-Z range)
# Rules: 1-5 tags from existing collection, clippings tag last, skip <20 chars content

$vaultPath = "D:\Obsidian\Main\20 - Permanent Notes"

# File -> Tags mapping (built from content analysis)
$tagMap = @{
    "I let my local LLM organize my chaotic Obsidian vault and it and it nailed it.md" = @("Obsidian", "AI", "PKM", "organization")
    "IGoogle Theme Maker.md" = @("Google", "web")
    "Imaginary Foundation.md" = $null  # skip - too short
    "Instapaper.md" = @("productivity", "reading", "web")
    "Introduction to the.md" = @("Programming", "Computers")
    "Is it eczema or psoriasis.md" = @("Health", "medical")
    "Israel bans fluoridated water.md" = @("Health", "Israel", "water_harvesting")
    "Jacqueline Depaul on TikTok.md" = @("recipe", "food", "cooking")
    "Jerry Talbot obituary Link.md" = @("Genealogy", "talbot", "family")
    "Journaley - A Simple.md" = @("Software", "Windows", "productivity")
    "Judaism.md" = @("Judiasm", "religion")
    "Key Data Perspective.md" = @("Genealogy", "FamilyTree", "talbot")
    "Kindle 3 Tips and Tricks.md" = @("Kindle", "eBook", "lifehacks")
    "Kindle 4 PC Shortcut.md" = @("Kindle", "Computers", "eBook")
    "LG--- dishwasher.md" = $null  # skip - too short
    "LiveCode - The Future.md" = @("Programming", "Code", "Software")
    "LNS JUST PIE CRUST.md" = @("recipe", "baking", "dessert")
    "Lee Etta Stanard.md" = @("Genealogy", "FamilyTree", "talbot")
    "MAKE Blog QRS halts.md" = $null  # skip - too short
    "Making Drums.md" = @("music", "craft", "maker")
    "Mapping the Uncharted Terr.md" = @("science", "nature", "geology")
    "Marshall Effron JUST PIE CRUST.md" = @("recipe", "baking", "dessert")
    "Mastering Git Course.md" = @("Programming", "Code", "Learning", "clippings")
    "Matthew Talbott.md" = @("Genealogy", "FamilyTree", "talbot")
    "Micro-Meteorite Hunting.md" = @("micrometeorites", "science", "Hobbies")
    "Microsoft Sculpt Ergonomic Desktop.md" = @("hardware", "Computers")
    "Mix Magazine.md" = @("music", "magazine")
    "Model Behavior Scale M.md" = @("NLP", "Psychology", "Behavior")
    "Mr. Money Mustache.md" = @("Finance", "lifehacks", "Sustainability")
    "My Obsidian And Gemini CLI Workflow.md" = @("Obsidian", "AI", "PKM", "productivity")
    "NLP Strategies - Spelli.md" = @("NLP", "Education", "Learning")
    "NRICH - National Resour.md" = @("science", "Education", "Learning")
    "Nagios NRPE - Compili.md" = @("Nagios", "Linux", "Monitoring")
    "National Semiconductor.md" = @("electronics", "retro-computer")
    "Naw Ruz.md" = @("bahai", "Holidays", "religion")
    "Ninite.md" = @("Software", "Windows", "productivity")
    "ORDER BY Clause (Transa.md" = @("SQL", "database", "Programming")
    "Obsidian Frontmatter Tag Fixer.md" = @("Obsidian", "PowerShell", "PKM")
    "Old Man and the Sea Intro.md" = @("literature", "book", "reading")
    "Oracle.md" = @("database", "SQL", "Software")
    "Order Postcards - the.md" = @("bahai", "architecture", "religion")
    "Parrot Zick headphones.md" = @("hardware", "Computers", "HeadPhones")
    "Pecan Crust.md" = @("recipe", "baking", "pecan", "dessert")
    "Pepper Ridge Sandwiches.md" = @("recipe", "food", "cooking")
    "Perl 5 Regex Cheat sheet.md" = @("Programming", "Code", "Linux")
    "PersonalWeb - DFW-TALBOT.md" = @("Genealogy", "talbot", "FamilyTree")
    "PersonalWeb - Edna Mae Fillingim H.md" = @("Genealogy", "FamilyTree", "talbot")
    "PersonalWeb - Henry Charles Bubba.md" = @("Genealogy", "FamilyTree", "talbot")
    "PersonalWeb - Loving poster.md" = $null  # skip - too short
    "PersonalWeb - MAGAbert.md" = $null  # skip - too short
    "PersonalWeb - PT.md" = $null  # skip - too short
    "PersonalWeb - Screen clipping ta-7.md" = $null  # skip - too short
    "Pinkish background.md" = $null  # skip - too short
    "Playing a Musical Saw.md" = @("music", "MusicalInstruments", "Hobbies")
    "Pluto is a Planet.md" = @("science", "Astronomy", "space")
    "PrintFriendly.md" = @("web", "productivity", "printing")
    "QR-Code Generator.md" = @("web", "Tools", "Code")
    "Quick list of every Windows 10 keyboard shortcut.md" = @("Windows", "Computers", "lifehacks")
    "ROOTS Technology.md" = @("Genealogy", "FamilyTree", "Software")
    "Reba Joyce Fillingim.md" = @("Genealogy", "FamilyTree", "talbot")
    "Recorder Fingering Charts.md" = @("recorder", "music", "MusicalInstruments")
    "Refrigerator Dills.md" = @("recipe", "Ferment", "food")
    "Request for military.md" = @("Genealogy", "military", "family")
    "Rick Steves Cruiseship Tips.md" = @("Travel", "cruise", "lifehacks")
    # Rings em-dash BLDGBLOG handled separately below
    "S100 Computers - Build your own Z80 Computer.md" = @("s100", "Z80", "retro-computer", "electronics")
    "SCORM - SCORM Explai.md" = @("Education", "Software", "Learning")
    "Samsung Galaxy Tab S Pro.md" = @("tablets", "review")
    "Science.md" = $null  # skip - too short
    "Scientists discover virus.md" = @("science", "biology", "medical")
    "Screen clipping t-12.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-1.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-1_2.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-4.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-5.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-6.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping take_3.md" = @("Genealogy", "FamilyTree", "talbot")
    "Set Up Windows Home Se.md" = @("Windows", "Computers", "networking")
    "Shopping List.md" = $null  # skip - too short
    "SourceForge Apex - Oracles Application Express.md" = @("database", "SQL", "Programming")
    "Spiced Pumpkin Oat Muffins.md" = @("recipe", "baking", "healthy-cooking")
    "Sugar Free Apple Pie.md" = @("recipe", "baking", "dessert")
    "Summit At Sea.md" = @("Entertainment", "cruise", "culture")
    "Switched On Bach.md" = @("music", "electronics", "retro-computer")
    "The Last Lecture.md" = @("book", "Education", "lifehacks")
    "The Vinyl Anachronist.md" = @("Vinyl", "music", "Hobbies")
    "The boy who harnessed the wind.md" = @("book", "Africa", "energy", "maker")
    "Tom Bihn.md" = @("products", "Travel", "review")
    "Transactions Screen (WCWBF).md" = @("bahai", "fundraising", "Software")
    "US path to world cup victory.md" = @("Soccer", "FIFAWorldCup")
    "UHJ 2025-12-31 To The Conference of the Continental Boards of Counsellors - AI Summary.md" = @("UHJ", "9YearPlan", "bahai")
    "UHJ 2025-12-31 To the Conference of the Continental Boards of Counsellors - Full Message.md" = @("UHJ", "9YearPlan", "bahai")
    "Unswindle Kindle de-.md" = @("Kindle", "DRM", "eBook")
    "Using AND and OR ope.md" = @("Programming", "database", "SQL")
    "VMware KB Installing.md" = @("virtualization", "Linux", "Computers")
    "Vera Irene Talbot.md" = @("Genealogy", "FamilyTree", "talbot")
    "Visual Studio 2022 Professional License Key.md" = @("SoftwareLicense", "Programming", "Windows")
    "WCWBF Transactions Screen.md" = @("bahai", "fundraising", "Software")
    "Welcome to AltairKit.md" = @("retro-computer", "electronics", "Hobbies")
    "Welcome to Writage.md" = @("MicrosoftWord", "writing", "productivity")
    "Where Are Your Keys.md" = @("language", "Learning", "Education")
    "Which Veggie Burgers are Really the Healthiest.md" = @("Vegetarian", "Health", "food")
    "Whole Earth Catalog.md" = @("culture", "book", "Sustainability")
    "Why humans have allergies.md" = @("Health", "allergy", "science")
    "Why is Google Books fair use.md" = @("Google", "law", "book")
    "William Henry White.md" = @("Genealogy", "FamilyTree", "talbot")
    "William Kamkwamba.md" = @("Africa", "energy", "maker", "Education")
    "Wind Chimes Maker.md" = @("craft", "music", "maker")
    "windows - vbscript o.md" = @("Windows", "Programming", "Code")
    "Windows and Linux Nagios LDAP.md" = @("Nagios", "networking", "Linux", "Windows")
    "Wood glue deep cleaning vinyl records.md" = @("Vinyl", "Cleaning", "Hobbies")
    "WorkRave.md" = @("Health", "Software", "productivity")
    "xkcd Is It Worth the Time.md" = @("xkcd", "productivity", "humor")
}

$results = @()

foreach ($entry in $tagMap.GetEnumerator()) {
    $fileName = $entry.Key
    $tags = $entry.Value

    # Handle the em dash file
    $actualName = $fileName
    if ($fileName -like "Rings*BLDGBLOG*") {
        $found = Get-ChildItem $vaultPath -Filter "Rings*BLDGBLOG*"
        if ($found) { $actualName = $found.Name }
    }

    $filePath = Join-Path $vaultPath $actualName

    if (-not (Test-Path $filePath)) {
        $results += [PSCustomObject]@{ File = $fileName; Tags = "FILE NOT FOUND"; Status = "Error" }
        continue
    }

    if ($null -eq $tags) {
        $results += [PSCustomObject]@{ File = $fileName; Tags = "SKIPPED (<20 chars)"; Status = "Skipped" }
        continue
    }

    # Read file
    $content = Get-Content $filePath -Raw -Encoding UTF8

    # Build YAML tag block - clippings always last
    $orderedTags = @()
    $hasClippings = $false
    foreach ($t in $tags) {
        if ($t -eq "clippings") {
            $hasClippings = $true
        } else {
            $orderedTags += $t
        }
    }
    if ($hasClippings) { $orderedTags += "clippings" }

    $tagBlock = "tags:`n"
    foreach ($t in $orderedTags) {
        $tagBlock += "  - $t`n"
    }
    $tagBlock = $tagBlock.TrimEnd("`n")

    # Check if file has frontmatter
    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $yaml = $Matches[1]
        # Replace or add tags in existing frontmatter
        if ($yaml -match '(?s)tags:\s*\r?\n(\s*-\s*.+\r?\n)*') {
            # Has existing tags block - replace it
            $newYaml = $yaml -replace '(?s)tags:\s*(\r?\n\s*-\s*.+)*', $tagBlock
        } elseif ($yaml -match 'tags:\s*$') {
            # Has empty tags: line
            $newYaml = $yaml -replace 'tags:\s*$', $tagBlock
        } elseif ($yaml -match 'tags:\s*\r?\n\s*\r?\n') {
            # tags: followed by blank line
            $newYaml = $yaml -replace 'tags:\s*\r?\n', "$tagBlock`n"
        } else {
            # No tags key, add it
            $newYaml = $yaml + "`n" + $tagBlock
        }
        $newContent = $content -replace '(?s)^---\r?\n.*?\r?\n---', "---`n$newYaml`n---"
    } else {
        # No frontmatter - add one
        $newContent = "---`n$tagBlock`n---`n" + $content
    }

    # Write back
    [System.IO.File]::WriteAllText($filePath, $newContent, [System.Text.UTF8Encoding]::new($false))

    $tagStr = ($orderedTags -join ", ")
    $results += [PSCustomObject]@{ File = $fileName; Tags = $tagStr; Status = "Tagged" }
}

# Handle Rings em-dash BLDGBLOG separately
$ringsFile = Get-ChildItem $vaultPath -Filter "Rings*BLDGBLOG*" | Select-Object -First 1
if ($ringsFile) {
    $ringsTags = @("architecture", "design", "art")
    $tagBlock = "tags:`n"
    foreach ($t in $ringsTags) { $tagBlock += "  - $t`n" }
    $tagBlock = $tagBlock.TrimEnd("`n")
    $content = Get-Content $ringsFile.FullName -Raw -Encoding UTF8
    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $yaml = $Matches[1]
        if ($yaml -match '(?s)tags:\s*(\r?\n\s*-\s*.+)*') {
            $newYaml = $yaml -replace '(?s)tags:\s*(\r?\n\s*-\s*.+)*', $tagBlock
        } else {
            $newYaml = $yaml + "`n" + $tagBlock
        }
        $newContent = $content -replace '(?s)^---\r?\n.*?\r?\n---', "---`n$newYaml`n---"
    } else {
        $newContent = "---`n$tagBlock`n---`n" + $content
    }
    [System.IO.File]::WriteAllText($ringsFile.FullName, $newContent, [System.Text.UTF8Encoding]::new($false))
    $results += [PSCustomObject]@{ File = $ringsFile.Name; Tags = ($ringsTags -join ", "); Status = "Tagged" }
}

# Handle Tom's Fried Rice separately (smart quotes in name)
$tomsFile = Get-ChildItem $vaultPath -Filter "Tom*Fried*Rice*" | Select-Object -First 1
if ($tomsFile) {
    $tomsTags = @("recipe", "cooking", "food")
    $tagBlock = "tags:`n"
    foreach ($t in $tomsTags) { $tagBlock += "  - $t`n" }
    $tagBlock = $tagBlock.TrimEnd("`n")
    $content = Get-Content $tomsFile.FullName -Raw -Encoding UTF8
    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $yaml = $Matches[1]
        if ($yaml -match '(?s)tags:\s*(\r?\n\s*-\s*.+)*') {
            $newYaml = $yaml -replace '(?s)tags:\s*(\r?\n\s*-\s*.+)*', $tagBlock
        } else {
            $newYaml = $yaml + "`n" + $tagBlock
        }
        $newContent = $content -replace '(?s)^---\r?\n.*?\r?\n---', "---`n$newYaml`n---"
    } else {
        $newContent = "---`n$tagBlock`n---`n" + $content
    }
    [System.IO.File]::WriteAllText($tomsFile.FullName, $newContent, [System.Text.UTF8Encoding]::new($false))
    $results += [PSCustomObject]@{ File = $tomsFile.Name; Tags = ($tomsTags -join ", "); Status = "Tagged" }
}

# Output results
$results | Sort-Object File | Format-Table -AutoSize -Wrap
Write-Host "`nTotal: $($results.Count) files processed"
Write-Host "Tagged: $(($results | Where-Object Status -eq 'Tagged').Count)"
Write-Host "Skipped: $(($results | Where-Object Status -eq 'Skipped').Count)"
Write-Host "Errors: $(($results | Where-Object Status -eq 'Error').Count)"
