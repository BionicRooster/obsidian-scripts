# add_moc_links.ps1 — Classify unclassified notes into their MOC sections
# UTF-8 encoding throughout; special chars handled via [char] escapes in strings

$ErrorActionPreference = 'Stop'
$vault  = 'C:\Users\awt\Sync\Obsidian'
$dashDir = "$vault\00 - Home Dashboard"

# ─────────────────────────────────────────────────────────────────────────────
# Helper: append link lines after a section heading (before the next heading)
# ─────────────────────────────────────────────────────────────────────────────
function Add-LinksToSection {
    param(
        [string]$FilePath,
        [string]$SectionHeading,
        [string[]]$Links
    )
    $content = Get-Content -LiteralPath $FilePath -Encoding UTF8 -Raw
    $idx = $content.IndexOf($SectionHeading)
    if ($idx -lt 0) {
        Write-Warning "  Section '$SectionHeading' not found in $(Split-Path $FilePath -Leaf)"
        return
    }
    $afterHeading = $idx + $SectionHeading.Length
    $nextSect = [regex]::Match($content.Substring($afterHeading), '(?m)^#{1,3} ')
    if ($nextSect.Success) {
        $insertPos = $afterHeading + $nextSect.Index
        # Walk back past trailing blank lines
        while ($insertPos -gt ($afterHeading + 2) -and $content[$insertPos - 1] -match '[\r\n]') {
            $insertPos--
        }
        $insertPos++
        $newLinks = "`n" + ($Links -join "`n")
        $content = $content.Substring(0, $insertPos) + $newLinks + $content.Substring($insertPos)
    } else {
        $content = $content.TrimEnd() + "`n" + ($Links -join "`n") + "`n"
    }
    Set-Content -LiteralPath $FilePath -Value $content -Encoding UTF8 -NoNewline
    Write-Host "  +$($Links.Count) -> '$SectionHeading' in $(Split-Path $FilePath -Leaf)"
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 0: Remove the bad link inserted earlier in the Baha'i MOC
# ─────────────────────────────────────────────────────────────────────────────
$bahaiMOC = (Get-ChildItem $dashDir | Where-Object { $_.Name -like '*Bah*Faith*' }).FullName
$c = Get-Content -LiteralPath $bahaiMOC -Encoding UTF8 -Raw
$c = [regex]::Replace($c, "\r?\n- \[\[Bah\$\(\(\[char\]0x[0-9a-f]+\]\)\)[^\]]+\]\]", '')
Set-Content -LiteralPath $bahaiMOC -Value $c -Encoding UTF8 -NoNewline
Write-Host "STEP 0: Cleaned bad links from Baha'i MOC"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Fix double-space filename for the Baha'i names file
# ─────────────────────────────────────────────────────────────────────────────
$bahaiDir = "$vault\01\Bah$([char]0x00e1)'$([char]0x00ed)"
$doubleSpaceFile = Get-ChildItem $bahaiDir | Where-Object { $_.Name -like '*Names with Diacritical*' -and $_.Name -match '  ' }
if ($doubleSpaceFile) {
    $newName = $doubleSpaceFile.Name -replace '  ', ' '
    Rename-Item -LiteralPath $doubleSpaceFile.FullName -NewName $newName
    Write-Host "STEP 1: Renamed '$($doubleSpaceFile.Name)' -> '$newName'"
} else {
    Write-Host "STEP 1: Double-space file not found (already fixed)"
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: MOC - Baha'i Faith
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Baha'i Faith"
Add-LinksToSection $bahaiMOC '## Community & Service' @(
    "- [[Ruth Kronick Funeral (Allen)]]",
    "- [[Wayne Talbot In Bluebonnets]]"
)
Add-LinksToSection $bahaiMOC "## Rid$([char]0x00e1)n Messages" @(
    "- [[UHJ - 2026 Ridvan Message (English) Summary]]",
    "- [[UHJ - 2026 Ridvan Message (English)]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: MOC - Finance & Investment
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Finance & Investment"
$fin = "$dashDir\MOC - Finance & Investment.md"
Add-LinksToSection $fin '## Financial Management' @(
    "- [[The Biggest Ponzi Schemes in Modern History]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: MOC - Friends of the Georgetown Public Library
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Friends of the Georgetown Library"
$fol = "$dashDir\MOC - Friends of the Georgetown Public Library.md"
Add-LinksToSection $fol '## FOL Operations & Procedures' @(
    "- [[Communications Team]]",
    "- [[LGLDataDictionary]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: MOC - Health & Nutrition
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Health & Nutrition"
$health = "$dashDir\MOC - Health & Nutrition.md"
Add-LinksToSection $health '## Medical & Health' @(
    "- [[Hibiclens Uses, Side Effects]]",
    "- [[University Dental]]"
)
Add-LinksToSection $health '## Premature Birth & Respiratory Health' @(
    "- [[Young Adults Born Preterm May Live with Lungs of Elderly -- ScienceDaily]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6: MOC - Home & Practical Life
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Home & Practical Life"
$homeMOC = "$dashDir\MOC - Home & Practical Life.md"
Add-LinksToSection $homeMOC '## Entertainment & Film' @(
    "- [[San Gabriel Film Series Meeting]]"
)
Add-LinksToSection $homeMOC '## Georgetown Cultural Citizens Memorial Association' @(
    "- [[WCWBF 2021-08-12 03_58 PM Advisory Committee]]",
    "- [[GCCMA Meeting Pictures]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 7: MOC - Music & Record
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Music & Record"
$music = "$dashDir\MOC - Music & Record.md"
Add-LinksToSection $music '## Music Performances & Articles' @(
    "- [[New in Top Free MP3 Albums_ #10_ Praise His Name]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 8: MOC - NLP & Psychology
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - NLP & Psychology"
$nlp = "$dashDir\MOC - NLP & Psychology.md"
Add-LinksToSection $nlp '## NLP Techniques & Communication' @(
    "- [[Embedded Commands in]]",
    "- [[Major Presupposition]]",
    "- [[NLP for Programmers]]",
    "- [[NLP Forum $([char]0x2014) Taste #2 Alt.psy.nlp (December 1994)]]",
    "- [[NLP World]]",
    "- [[NLP]]",
    "- [[Quick Profiling]]",
    "- [[Six Themes of NLP]]",
    "- [[Ramblings 3]]",
    "- [[Reciprocity]]",
    "- [[Institute of NLP of Austin Texas]]"
)
Add-LinksToSection $nlp '## NLP Master Class' @(
    "- [[Alignment of Logical]]",
    "- [[Fast Phobia Cure]]",
    "- [[NLP Training Week 1]]",
    "- [[NLP Training Week 2]]",
    "- [[NLP Training Week 3]]",
    "- [[NLP Training Week 4]]",
    "- [[NLP Training Week 5]]",
    "- [[NLP Training Week 6]]",
    "- [[Six Step Reframe]]",
    "- [[Well Formed Outcomes]]",
    "- [[Wired Logical Levels]]"
)
Add-LinksToSection $nlp '## Cognitive Science' @(
    "- [[Dyslexia May Be the Brain Struggling to Adapt]]",
    "- [[The Dyslexie Font Ma]]",
    "- [[Why Some People Think in Words, While Others Think in Pictures & Feelings]]",
    "- [[Cocktail Party Effect]]",
    "- [[Inattentional Blindness An Overview]]",
    "- [[Misdirected Attentio]]",
    "- [[The Advantages of Dyslexia]]",
    "- [[Thinking, Fast and S]]"
)
Add-LinksToSection $nlp '## Psychology & Behavior' @(
    "- [[Personal Development]]",
    "- [[Product of Discipline]]",
    "- [[The Power of Free]]",
    "- [[Jigsaw Puzzles Can Improve Your Quality of Life]]",
    "- [[Power of Proximity]]",
    "- [[The Trolly Problem]]",
    "- [[Adults who apologize]]"
)
Add-LinksToSection $nlp '## Learning & Skills' @(
    "- [[5 Strategies to Demystify the Learning Process for Struggling Students]]"
)
Add-LinksToSection $nlp '## Productivity & Focus' @(
    "- [[SMART Goals]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 9: MOC - Reading & Literature
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Reading & Literature"
$reading = "$dashDir\MOC - Reading & Literature.md"
Add-LinksToSection $reading '## Chrome/Web Clippings' @(
    "- [[Can You Say...$([char]0x22)Hero$([char]0x22)  Esquire  November 1998]]"
)
Add-LinksToSection $reading '### Fiction & Literature' @(
    "- [[Microfiction #6_ The Good People $([char]0x2013) Jim Butcher]]"
)
Add-LinksToSection $reading '## Kindle Clippings' @(
    "- [[# Ice Age Flood Tour in Full Color]]",
    "- [[Ahrens-How to Take S]]",
    "- [[Kond$([char]0x014d)-The Life-Changing Magic of Tidying Up]]",
    "- [[Larsen-On the Trail of Stardust The Guide to Finding Micrometeorites]]",
    "- [[On the Trail of Stardust The Guide to Finding Micrometeorites]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 10: MOC - Recipes
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Recipes"
$recipes = "$dashDir\MOC - Recipes.md"
Add-LinksToSection $recipes '## Soups & Stews' @(
    "- [[Borlotti Bean and Mussel Stew with Zucchini]]",
    "- [[Feijoada - Brazilian Black Bean Stew]]",
    "- [[Javanese-Inspired Chicken Soup (Vegan Soto Aya m)]]",
    "- [[Vegan Chicken and Dumpling Stew]]"
)
Add-LinksToSection $recipes '## Main Dishes' @(
    "- [[Corned Seitan and Cabbage]]",
    "- [[Four Simple Slow-Cooker Recipes Our Family Loves [feedly]]]",
    "- [[Gluten-Free Chicken Style Seitan]]",
    "- [[Gluten-Free Sweet Potato Dumplings]]",
    "- [[Healthy Sesame Soba Noodles with Spinach and Tofu [feedly] Recipe]]",
    "- [[Huevos Rancheros]]",
    "- [[Irish Fauxsages (Vegan Irish Sausages)]]",
    "- [[Sloppy Giuseppes]]"
)
Add-LinksToSection $recipes '## Sides & Salads' @(
    "- [[Fresh Fava Beans with Mint and Scallions]]",
    "- [[Red Beans and Rice Salad]]"
)
Add-LinksToSection $recipes '## Sauces, Dips & Condiments' @(
    "- [[Quick-Pickle Apples]]",
    "- [[Spinach Artichoke Dip]]"
)
Add-LinksToSection $recipes '## Breads & Baked Goods' @(
    "- [[Easy, Healthy, Vegan Soda Bread for St. Paddys Da y]]"
)
Add-LinksToSection $recipes '## Reference' @(
    "- [[How to Free Yourself from Recipes with a Few Golden Cooking Ratios [feedly]]]",
    "- [[Vegan Planet - Recipe (1)]]",
    "- [[Vegan Planet - Recipe (4)]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 11: MOC - Science & Nature
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Science & Nature"
$science = "$dashDir\MOC - Science & Nature.md"
Add-LinksToSection $science '## Micrometeorites' @(
    "- [[How to Build Your Own Micrometeorite Collection]]",
    "- [[The Men Collecting Stardust From Gutters and Rooftops]]",
    "- [[Larsen-On the Trail of Stardust The Guide to Finding Micrometeorites]]",
    "- [[On the Trail of Stardust The Guide to Finding Micrometeorites]]"
)
Add-LinksToSection $science '## Gardening & Botany' @(
    "- [[Fig Tree Pruning Plan]]",
    "- [[Fruit Walls Urban Farming in the 1600s]]",
    "- [[Groasis Waterboxx Greening the World]]"
)
Add-LinksToSection $science '## Science Articles & Clippings' @(
    "- [[An Invasive Plant is Painting Iceland's Deserts Purple]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 12: MOC - Social Issues
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Social Issues"
$social = "$dashDir\MOC - Social Issues.md"
Add-LinksToSection $social '## Religion & Society' @(
    "- [[9 Archaeological Sites of Biblical Importance]]",
    "- [[Anthony Flaccavento - Obama Santorum and Religion]]",
    "- [[Christianity]]",
    "- [[Rare Maya Burial Temple Discovered in Belize]]",
    "- [[Religion]]",
    "- [[Unearthing the World of Jesus]]",
    "- [[Matthew 7_16-23 Kjv - Ye Shall Know Them by Their Fruits. Do - Bible Gateway_2]]",
    "- [[War on Christian Terrorism]]"
)
Add-LinksToSection $social '## Justice & Politics' @(
    "- [[Several Ice Agents Were Arrested in Recent Months, Showing Risk of Misconduct]]",
    "- [[The Squalor of the Epstein Class]]",
    "- [[Trump Administration Working to Expand Effort to Strip Citizenship from Foreign-born Americans]]",
    "- [[What If the Typical Worker's Pay Had Risen Like CEO Salaries]]",
    "- [[Worst of the Worst Most US Immigrants Targeted for Deportation in 2025 Had No Criminal Charges, Documents Reveal]]",
    "- [[Little V. Llano County Legalized Library Censorship. What Exactly Does This Mean Book Censorship News, February 13, 2026]]"
)
Add-LinksToSection $social '## Cultural Commentary' @(
    "- [[What the Classroom Didn't Teach Me About the American Empire - An Illustrated Video]]",
    "- [[Backpack Discovered as Search for Nancy Guthrie Reaches Day 22]]",
    "- [[UCLA Study Identifies How the Brain Makes Memories]]",
    "- [[A History of Georgetown's Westside Neighborhood]]",
    "- [[African-American Community Builders]]"
)
Add-LinksToSection $social '## Race & Equity' @(
    "- [[2024-11-06]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 13: MOC - Technology & Computers
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Technology & Computers"
$tech = "$dashDir\MOC - Technology & Computers.md"
Add-LinksToSection $tech '## Computer Sciences' @(
    "- [[## What the AA Battery Codes Actually Mean]]",
    "- [[African Fractals - Ron Eglash  Profile]]",
    "- [[Device Listing  My A]]"
)
Add-LinksToSection $tech '## Troubleshooting & Guides' @(
    "- [[How to Copy Only New Files and Changed Files With XCopy on Windows]]",
    "- [[How to Find the Disk and Volume Guid on Windows 10]]",
    "- [[How to Scan Removable Drives With Microsoft Defender]]",
    "- [[Merge Instructions for Changing Case for Word 2016 & Word 2008 _ Nc State Extension]]",
    "- [[Mount and Dismount Hard Drive Through a Script or Software]]",
    "- [[Restore Old Right-click Context Menu in Windows 11]]",
    "- [[Wayback Machine]]"
)
Add-LinksToSection $tech '## Excel VBA' @(
    "- [[Add Months to Date in MSExcel]]",
    "- [[Apply Color to Alternate Rows or Columns - Microsoft Support]]",
    "- [[Automatically Format Numbers in Thousands, Millions, Billions in Excel 2 Techniques]]",
    "- [[These Pivot Table Tricks Massively Save Your Time >> Excel Tips & Tricks]]"
)
Add-LinksToSection $tech '## Databases & Access' @(
    "- [[Access Wizard Finding Information on All Linked Tables - The Easy Way]]",
    "- [[AccessBlog.net Access System Tables Tips and Tricks, News, Links, Downloads on Microsoft Access]]",
    "- [[Assistant Database Administrator]]",
    "- [[Convert the Text in the Field of a Microsoft Access Table to Proper Case with a Query]]",
    "- [[Documenting Query Dependencies in Access - Home - DataWright Information Services 1]]",
    "- [[Documenting Query Dependencies in Access - Home - DataWright Information Services]]",
    "- [[Documenting Tables - DataWright Information Services - Home - DataWright Information Services]]",
    "- [[Grouping Objects in Access_ An Organizational Tip You Can't Miss - MicroKnowledge, Inc.]]",
    "- [[Rick Fisher Consulting (Find and Replace for Microsoft Access)]]",
    "- [[Search For Text, A2000+ - UtterAccess Forums]]",
    "- [[SQLite3 SQL Commands Explained with Examples]]"
)
Add-LinksToSection $tech '## Retrocomputing' @(
    "- [[Altair-Duino - the Low-cost Altair 8800]]",
    "- [[Brian K. White _b.kenyon.w@gmail.com_]]",
    "- [[Digirule 2, 2A and 2U - Brads Electronic Projects]]",
    "- [[Tech Explorations KiCad Like a Professional]]",
    "- [[Z80 Retrocomputing 11 - Cpm on the RC2014 - Dr. Scott M. Baker]]",
    "- [[Z80 Retrocomputing 5 - Single Stepper for RC2014 - Dr. Scott M. Baker]]",
    "- [[Z80 Retrocomputing 6 - RC2014 Til311 Front Panel Board - Dr. Scott M. Baker]]",
    "- [[Re_ [M100] REXCPM Question]]"
)
Add-LinksToSection $tech '### PiDP-8 (DEC PDP-8 Replica)' @(
    "- [[pidp8 Another Pathetic Newbie, to Both Pidp 8 and Linux]]",
    "- [[pidp8 buildroot Version of PiDP_8 with SimH 4.0]]",
    "- [[pidp8 Mounting OS8 ImageFiles Read Only to Avoid Corruption.]]",
    "- [[pidp8 Re_ buildroot Version of PiDP_8 with SimH 4.0]]",
    "- [[pidp8 Re_ Display Update for the PiDP8]]",
    "- [[pidp8 Re_ VC8E.pde]]",
    "- [[pidp8 VC8E.pde]]"
)
Add-LinksToSection $tech '## AI & Machine Learning' @(
    "- [[Claude Code  Prompting Bug]]"
)
Add-LinksToSection $tech '## Software & Tools' @(
    "- [[CSV-to-ICS Converter Format]]",
    "- [[Handbrake Documentation - Audio and Subtitle Defaults]]"
)
Add-LinksToSection $tech '## Automation & Workflow Tools' @(
    "- [[This November at IFTTT We're Thankful For...]]"
)
Add-LinksToSection $tech '## Digital Privacy & Security' @(
    "- [[ExpressVPN Password]]"
)
Add-LinksToSection $tech '## Devices & Hardware' @(
    "- [[HP Calculator Batteries]]",
    "- [[Hearing Aids Better, Cheaper, and More Accessible Than Ever]]"
)
Add-LinksToSection $tech '## Technology Articles & Clippings' @(
    "- [[We Are in a Digital Version of the Enclosures - Like the Landowners, Big Tech Has Power Without Responsibility]]",
    "- [[Microfiction 6 The G]]"
)
Add-LinksToSection $tech '## Software Licenses & Purchases' @(
    "- [[Acronis True Image Order]]",
    "- [[Microsoft Office 2021 License Personal]]",
    "- [[Print Artist Gold 25 Receipt]]",
    "- [[Purchase CSV Ics Converter]]",
    "- [[TurboTax 2021 Key]]",
    "- [[Windows 11 Pro Unused]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 14: MOC - Travel & Exploration
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Travel & Exploration"
$travel = "$dashDir\MOC - Travel & Exploration.md"
Add-LinksToSection $travel '## National Parks & Nature' @(
    "- [[Protecting Arizona's Petrified Forest]]"
)
Add-LinksToSection $travel '## RV & Alternative Living' @(
    "- [[Two Winters in a Tip]]"
)
Add-LinksToSection $travel '### Kerrville, TX' @(
    "- [[Plan Your Visit  Museum Of Western Art  Kerrville, Texas]]"
)
Add-LinksToSection $travel '## Travel Tips & Resources' @(
    "- [[To Do List]]"
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 15: MOC - Genealogy
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`nMOC - Genealogy"
$geneal = "$dashDir\MOC - Genealogy.md"
Add-LinksToSection $geneal '## Talbot Family Members' @(
    "- [[Elias White Talbot]]"
)

Write-Host "`nDone!"
