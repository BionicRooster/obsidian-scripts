# Apply tags to files in 20 - Permanent Notes (I-Z range)
# Rules: 1-5 tags from existing collection, clippings tag last, skip <20 chars content

$vaultPath = "D:\Obsidian\Main\20 - Permanent Notes"

# File -> Tags mapping - ONLY files confirmed to exist in 20 - Permanent Notes
$tagMap = @{
    "IGoogle Theme Maker.md" = @("Google", "web")
    "Imaginary Foundation.md" = $null  # skip - too short
    "Instapaper.md" = @("productivity", "reading", "web")
    "Introduction to the.md" = @("Programming", "Computers")
    "Jerry Talbot obituary Link.md" = @("Genealogy", "talbot", "family")
    "Journaley - A Simple.md" = @("Software", "Windows", "productivity")
    "Judaism.md" = @("Judiasm", "religion")
    "Key Data Perspective.md" = @("Genealogy", "FamilyTree", "talbot")
    "LG--- dishwasher.md" = $null  # skip - too short
    "LiveCode  Create app.md" = @("Programming", "Code", "Software")
    "LNS JUST PIE.md" = @("recipe", "baking", "dessert")
    "Lee Etta Stanard.md" = @("Genealogy", "FamilyTree", "talbot")
    "MAKE Blog QRS halts.md" = $null  # skip - too short
    "Marshall Effron - JUST PIE.md" = @("recipe", "baking", "dessert")
    "Mastering Git Course.md" = @("Programming", "Code", "Learning", "clippings")
    "Matthew Talbott.md" = @("Genealogy", "FamilyTree", "talbot")
    "My Obsidian And Gemini CLI Workflow.md" = @("Obsidian", "AI", "PKM", "productivity")
    "Naw Ruz - Persian New Year.md" = @("bahai", "Holidays", "religion")
    "Ninite Easy PC Setup.md" = @("Software", "Windows", "productivity")
    "ORDER BY Clause (Tra.md" = @("SQL", "database", "Programming")
    "Order Postcards.md" = @("bahai", "architecture", "religion")
    "Parrot Zick headphones.md" = @("hardware", "Computers", "HeadPhones")
    "Pecan Crust.md" = @("recipe", "baking", "pecan", "dessert")
    "Pepper Ridge Sandwiches.md" = @("recipe", "food", "cooking")
    "Perl 5 Regex Cheat sheet.md" = @("Programming", "Code", "Linux")
    "PersonalWeb - Edna Mae Fillingim H.md" = @("Genealogy", "FamilyTree", "talbot")
    "PersonalWeb - Henry Charles Bubba.md" = @("Genealogy", "FamilyTree", "talbot")
    "PersonalWeb - Loving poster.md" = $null  # skip - too short
    "PersonalWeb - MAGAbert.md" = $null  # skip - too short
    "PersonalWeb - PT.md" = $null  # skip - too short
    "PersonalWeb - Screen clipping ta-7.md" = $null  # skip - too short
    "Pinkish background.md" = $null  # skip - too short
    "Reba Joyce Fillingim.md" = @("Genealogy", "FamilyTree", "talbot")
    "Refrigerator Dills 1.md" = @("recipe", "Ferment", "food")
    "Request for military.md" = @("Genealogy", "military", "family")
    "S100 Computers - Car.md" = @("s100", "Z80", "retro-computer", "electronics")
    "SCORM - SCORM Explai.md" = @("Education", "Software", "Learning")
    "Science.md" = $null  # skip - too short
    "Scientists discover virus that kills all grades of breast cancer.md" = @("science", "biology", "medical")
    "Screen clipping t-12.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-1.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-1_2.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-4.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-5.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping ta-6.md" = @("Genealogy", "FamilyTree", "talbot")
    "Screen clipping take_3.md" = @("Genealogy", "FamilyTree", "talbot")
    "Set Up Windows Home.md" = @("Windows", "Computers", "networking")
    "Shopping List.md" = $null  # skip - too short
    "SourceForge.net Apex.md" = @("database", "SQL", "Programming")
    "Spiced Pumpkin Oat-1.md" = @("recipe", "baking", "healthy-cooking")
    "Sugar Free Apple Pie.md" = @("recipe", "baking", "dessert")
    "The boy who harnessed the wind.md" = @("book", "Africa", "energy", "maker")
    "Transactions Screen.md" = @("bahai", "fundraising", "Software")
    "US path to world cup victory.md" = @("Soccer", "FIFAWorldCup")
    "UHJ 2025-12-31 To The Conference of the Continental Boards of Counsellors - AI Summary.md" = @("UHJ", "9YearPlan", "bahai")
    "UHJ 2025-12-31 To the Conference of the Continental Boards of Counsellors - Full Message.md" = @("UHJ", "9YearPlan", "bahai")
    "Unswindle Kindle de-.md" = @("Kindle", "DRM", "eBook")
    "Using AND and OR ope.md" = @("Programming", "database", "SQL")
    "VMware KB Installing.md" = @("virtualization", "Linux", "Computers")
    "Vera Irene Talbot.md" = @("Genealogy", "FamilyTree", "talbot")
    "Visual Studio 2022 Professional License Key.md" = @("SoftwareLicense", "Programming", "Windows")
    "Welcome to AltairKit.md" = @("retro-computer", "electronics", "Hobbies")
    "Welcome to Writage.md" = @("MicrosoftWord", "writing", "productivity")
    "Where Are Your Keys.md" = @("language", "Learning", "Education")
    "Which Veggie Burgers.md" = @("Vegetarian", "Health", "food")
    "Whole Earth Catalog.md" = @("culture", "book", "Sustainability")
    "Why humans have allergies.md" = @("Health", "allergy", "science")
    "Why is Google Books fair use.md" = @("Google", "law", "book")
    "William Henry White.md" = @("Genealogy", "FamilyTree", "talbot")
    "William Kamkwamba, a.md" = @("Africa", "energy", "maker", "Education")
    "Wind Chimes Maker in.md" = @("craft", "music", "maker")
    "windows - vbscript o.md" = @("Windows", "Programming", "Code")
    "Windows and Linux Ne.md" = @("Nagios", "networking", "Linux", "Windows")
    "Wood glue deep cleaning vinyl records.md" = @("Vinyl", "Cleaning", "Hobbies")
    "WorkRave (WindowsLin.md" = @("Health", "Software", "productivity")
    "xkcd Is It Worth the.md" = @("xkcd", "productivity", "humor")
}

$results = @()

foreach ($entry in $tagMap.GetEnumerator()) {
    $fileName = $entry.Key
    $tags = $entry.Value
    $filePath = Join-Path $vaultPath $fileName

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
        if ($t -eq "clippings") { $hasClippings = $true }
        else { $orderedTags += $t }
    }
    if ($hasClippings) { $orderedTags += "clippings" }

    $tagLines = ($orderedTags | ForEach-Object { "  - $_" }) -join "`n"
    $tagBlock = "tags:`n$tagLines"

    # Check if file has frontmatter
    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $fullMatch = $Matches[0]
        $yaml = $Matches[1]

        # Remove existing tags block from YAML
        $newYaml = $yaml -replace '(?m)^tags:\s*\r?\n(\s+-\s+.*\r?\n)*', ''
        # Also remove empty tags: line
        $newYaml = $newYaml -replace '(?m)^tags:\s*$', ''
        # Clean up extra blank lines
        $newYaml = ($newYaml -replace '(\r?\n){3,}', "`n").Trim()

        # Add tag block
        if ($newYaml.Length -gt 0) {
            $newYaml = "$tagBlock`n$newYaml"
        } else {
            $newYaml = $tagBlock
        }

        $newFrontmatter = "---`n$newYaml`n---"
        $newContent = $content.Replace($fullMatch, $newFrontmatter)
    } else {
        # No frontmatter - add one
        $newContent = "---`n$tagBlock`n---`n$content"
    }

    # Write back with UTF-8 no BOM
    [System.IO.File]::WriteAllText($filePath, $newContent, [System.Text.UTF8Encoding]::new($false))

    $tagStr = ($orderedTags -join ", ")
    $results += [PSCustomObject]@{ File = $fileName; Tags = $tagStr; Status = "Tagged" }
}

# Handle Rings em-dash BLDGBLOG separately
$ringsFile = Get-ChildItem $vaultPath -Filter "Rings*BLDGBLOG*" | Select-Object -First 1
if ($ringsFile) {
    $ringsTags = @("architecture", "design", "art")
    $tagLines = ($ringsTags | ForEach-Object { "  - $_" }) -join "`n"
    $tagBlock = "tags:`n$tagLines"
    $content = Get-Content $ringsFile.FullName -Raw -Encoding UTF8
    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $fullMatch = $Matches[0]
        $yaml = $Matches[1]
        $newYaml = $yaml -replace '(?m)^tags:\s*\r?\n(\s+-\s+.*\r?\n)*', ''
        $newYaml = $newYaml -replace '(?m)^tags:\s*$', ''
        $newYaml = ($newYaml -replace '(\r?\n){3,}', "`n").Trim()
        if ($newYaml.Length -gt 0) { $newYaml = "$tagBlock`n$newYaml" } else { $newYaml = $tagBlock }
        $newContent = $content.Replace($fullMatch, "---`n$newYaml`n---")
    } else {
        $newContent = "---`n$tagBlock`n---`n$content"
    }
    [System.IO.File]::WriteAllText($ringsFile.FullName, $newContent, [System.Text.UTF8Encoding]::new($false))
    $results += [PSCustomObject]@{ File = $ringsFile.Name; Tags = ($ringsTags -join ", "); Status = "Tagged" }
}

# Handle Tom's Fried Rice separately (smart quotes in name)
$tomsFile = Get-ChildItem $vaultPath -Filter "Tom*Fried*Rice*" | Select-Object -First 1
if ($tomsFile) {
    $tomsTags = @("recipe", "cooking", "food")
    $tagLines = ($tomsTags | ForEach-Object { "  - $_" }) -join "`n"
    $tagBlock = "tags:`n$tagLines"
    $content = Get-Content $tomsFile.FullName -Raw -Encoding UTF8
    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') {
        $fullMatch = $Matches[0]
        $yaml = $Matches[1]
        $newYaml = $yaml -replace '(?m)^tags:\s*\r?\n(\s+-\s+.*\r?\n)*', ''
        $newYaml = $newYaml -replace '(?m)^tags:\s*$', ''
        $newYaml = ($newYaml -replace '(\r?\n){3,}', "`n").Trim()
        if ($newYaml.Length -gt 0) { $newYaml = "$tagBlock`n$newYaml" } else { $newYaml = $tagBlock }
        $newContent = $content.Replace($fullMatch, "---`n$newYaml`n---")
    } else {
        $newContent = "---`n$tagBlock`n---`n$content"
    }
    [System.IO.File]::WriteAllText($tomsFile.FullName, $newContent, [System.Text.UTF8Encoding]::new($false))
    $results += [PSCustomObject]@{ File = $tomsFile.Name; Tags = ($tomsTags -join ", "); Status = "Tagged" }
}

# Output results
$results | Sort-Object File | Format-Table -AutoSize -Wrap
Write-Host "`nTotal: $($results.Count) files processed"
Write-Host "Tagged: $(($results | Where-Object {$_.Status -eq 'Tagged'}).Count)"
Write-Host "Skipped: $(($results | Where-Object {$_.Status -eq 'Skipped'}).Count)"
Write-Host "Errors: $(($results | Where-Object {$_.Status -eq 'Error'}).Count)"
