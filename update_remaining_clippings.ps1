# Update remaining 10 - Clippings files
# Adds nav property and cleans content for each file
# Uses LiteralPath to handle special characters in filenames

$vault = "C:\Users\awt\Sync\Obsidian"
$clippings = "$vault\10 - Clippings"

function WriteUTF8 {
    param($path, $content)
    [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $false))
}

function AddNav {
    param($content, $navTarget)
    # Insert nav: line after the opening ---
    $content -replace '(?m)^---\r?\n', "---`nnav: `"$navTarget`"`n"
}

# ------------------------------------------------------------------
# Changing the direction of your ceiling fan
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*ceiling fan*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Home & Practical Life]]"
    # Remove boingboing related items (from first "- [![[" after the main content)
    # The main content ends with: image via [HomeSpot HQ](...)
    $cutMarker = "image via [HomeSpot HQ](http://www.homespothq.com/)"
    $cutIdx = $c.IndexOf($cutMarker)
    if ($cutIdx -ge 0) {
        $c = $c.Substring(0, $cutIdx + $cutMarker.Length).TrimEnd() + "`n"
    }
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# How to Make DIY Weed Killer
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Weed Killer*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Home & Practical Life]]"
    # Remove "Sharing is caring!" line + following blank line
    $c = $c -replace "(?m)^Sharing is caring!\r?\n\r?\n", ""
    # Remove "Clipped from:" line at start of body
    $c = $c -replace "(?m)^Clipped from: \[https://thekitchengarten\.com/diy-weed-killer/\]\(.*?\)\r?\n", ""
    # Remove the affiliate disclaimer paragraph
    $c = $c -replace "\*This post may contain affiliate links.*?Thank you for supporting my site!\*\r?\n", ""
    # Clean up double blank lines
    $c = $c -replace "(?m)(\r?\n){3,}", "`n`n"
    # Fix the title (remove " - The Kitchen Garten" from h1)
    $c = $c -replace "# How to Make DIY Weed Killer \(Only 3 Ingredients!\) - The Kitchen Garten", "# How to Make DIY Weed Killer"
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# How to Prune Fruit Trees to Keep Them Small - Mother Earth News
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Prune Fruit*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Science & Nature]]"
    # Remove breadcrumb link at top of body
    $c = $c -replace "(?m)^\[Organic Gardening Articles\]\(.*?\)\r?\n\r?\n", ""
    # Remove duplicate subtitle heading (second "## How to Prune Fruit Trees to Keep Them Small")
    # The first appears as the article subtitle: "## Learn how to prune..."
    # The second is a section header that's identical to the title
    $c = $c -replace "(?m)^## How to Prune Fruit Trees to Keep Them Small: The First Cut\r?\n\r?\n## How to Prune Fruit Trees to Keep Them Small\r?\n\r?\n", "## How to Prune Fruit Trees to Keep Them Small: The First Cut`n`n"
    # Remove the "Need Help? Call" promo at bottom and the store ad image before it
    $needHelpIdx = $c.IndexOf("[![[ed460163524f5aa289513162acaabe21_MD5.png]]](https://store.motherearthnews.com/)")
    if ($needHelpIdx -ge 0) {
        $c = $c.Substring(0, $needHelpIdx).TrimEnd() + "`n"
    }
    # Fix title in h1 (remove the source site suffix)
    $c = $c -replace "# How to Prune Fruit Trees to Keep Them Small .+", "# How to Prune Fruit Trees to Keep Them Small"
    # Remove the duplicate "## How to Prune Fruit Trees to Keep Them Small" heading (second one, below the intro subtitle)
    # Pattern: after the author/date block comes a duplicate heading
    $c = $c -replace "(?m)^Updated on May 26, 2022\r?\n\r?\n!\[\[f48bb.*?\r?\n\r?\nby PhotoBotanic.*?\r?\n\r?\nAfter fruit", "Updated on May 26, 2022`n`n![[f48bb084257dfb7feebd04df7357da3d_MD5.jpg]]`n`nby PhotoBotanic/Saxon Holt`n`nAfter fruit was thinned to 8 inches apart, this 5-year-old tree still produced 84 large apples.`n`nMany fruit"
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# In Ireland, Drought And A Drone Revealed The Outline Of An Ancient Henge
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Ireland*Henge*" -or $_.Name -like "*Ireland*Drone*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Science & Nature]]"
    # Remove <audio> tag
    $c = $c -replace "<audio[^>]*></audio>\r?\n\r?\n", ""
    # Remove duplicate caption blocks (the "Anthony Murphy/Mythical Ireland" text repeated)
    # First occurrence: "Anthony Murphy/Mythical Ireland ****hide caption****\n\nAnthony Murphy/Mythical Ireland\n\n..."
    $c = $c -replace "Anthony Murphy/Mythical Ireland \*\*\*\*hide caption\*\*\*\*\r?\n\r?\nAnthony Murphy/Mythical Ireland\r?\n\r?\n", "Anthony Murphy/Mythical Ireland`n`n"
    # Second occurrence in article
    $c = $c -replace "Anthony Murphy/Mythical Ireland \*\*\*\*hide caption\*\*\*\*\r?\n\r?\n", ""
    # Fix mojibake Brú na Bóinne (shows as Br? na B?inne or Br\ufffd na B\ufffd inne)
    $c = $c -replace 'Br[^\s]+ na B[^\s]+inne', 'Brú na Bóinne'
    # Remove the "### The Two-Way" / "### Stonehenge..." related article insets
    $c = $c -replace "### The Two-Way\r?\n\r?\n### Stonehenge Has A New.*?\r?\n\r?\n", ""
    $c = $c -replace "### The Two-Way\r?\n\r?\n### Shadow Stonehenge.*?\r?\n\r?\n### Party.*?\r?\n\r?\n### Party Like.*?\r?\n\r?\n", ""
    $c = $c -replace "\[!\[Stonehenge.*?\]\(https://media\.npr\.org.*?\)\]\(https://www\.npr\.org.*?\)\r?\n\r?\n### The Two-Way\r?\n\r?\n### Stonehenge Has A New.*?\r?\n\r?\n", ""
    $c = $c -replace "\[!\[Party.*?\]\(.*?\)\]\(https://www\.npr\.org.*?\)\r?\n\r?\n### The Salt\r?\n\r?\n### Party Like.*?\r?\n\r?\n", ""
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# Losing my religion for equality
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Losing my religion*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Social Issues]]"
    # Remove newsletter signup link at start of body
    $c = $c -replace "- \[\*\*Be the first to know\*\*\. Sign up for our Breaking News alert\]\(.*?\)\r?\n\r?\n", ""
    # Remove the two related article links at end
    $c = $c -replace "\r?\n\r?\n\[Clementine Ford: Jimmy Carter was right\]\(.*?\)\r?\n\r?\n\[Carter's message.*?\]\(.*?\)\r?\n\r?\n", "`n`n"
    # Remove "OBSERVER" line and byline
    $c = $c -replace "\r?\nOBSERVER\r?\n\r?\nJimmy Carter was president of the United States from 1977 to 1981\.\r?\n", ""
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# Microfiction #6: The Good People - Jim Butcher
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Microfiction*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Reading & Literature]]"
    # Fix frontmatter tags
    $c = $c -replace "tags:\r?\n  - onenote-import", "tags:`n  - Fiction`n  - DresdenFiles`n  - JimButcher`n  - ShortStory"
    # Remove "Clipped from: [url]" line
    $c = $c -replace "(?m)^Clipped from: \[https://www\.jim-butcher\.com/the-good-people\]\(.*?\)\r?\n", ""
    # Clean up encoding artifacts (replacement chars showing as unusual Unicode)
    # The file has some soft-hyphen/em-dash artifacts: " " (non-breaking space or special char)
    # These appear as spaces in the text - they're OK to leave as-is
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# The Best Raised Garden Bed
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Raised Garden Bed*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Science & Nature]]"
    # Fix malformed tag
    $c = $c -replace '"RaisedBed\. Vegetables"', '"RaisedGardenBed"`n  - "Vegetables"'
    # Remove cookbook promo at start of body
    $c = $c -replace "My new cookbook.*?\[`\*\*Order Now\*\*`\]\(.*?\)\r?\n\r?\n", ""
    $c = $c -replace "My new cookbook, \*Plant-Based on a Budget Quick & Easy\*, is here: \[`\*\*Order Now\*\*`\]\(https://plantbasedonabudgetcookbook\.com/\)\r?\n\r?\n", ""
    # Simpler pattern for cookbook line
    $bookIdx = $c.IndexOf("My new cookbook,")
    $asanIdx = $c.IndexOf("As an Amazon Associate")
    if ($bookIdx -ge 0 -and $asanIdx -ge 0 -and $bookIdx -lt $asanIdx) {
        $c = $c.Substring(0, $bookIdx) + $c.Substring($asanIdx)
    }
    # Remove Amazon Associate line
    $c = $c -replace "As an Amazon Associate I earn from qualifying purchases\.\r?\n\r?\n", ""
    # Remove "Want to save this recipe?" email signup block
    $recipeIdx = $c.IndexOf("### Want to save this recipe?")
    $afterRecipeMarker = "In the beginning, I"
    if ($recipeIdx -ge 0) {
        $afterIdx = $c.IndexOf($afterRecipeMarker, $recipeIdx)
        if ($afterIdx -ge 0) {
            $c = $c.Substring(0, $recipeIdx) + $c.Substring($afterIdx)
        }
    }
    # Remove affiliate discount link text
    $c = $c -replace " After doing research, I confidently chose \[Vego Garden\]\(.*?\) raised beds\. Are you considering Vego Garden, too\? Read about the benefits and \[.*?\]\(.*?\)\*\*\.\*\*", " After doing research, I chose Vego Garden raised beds for their eco-friendly materials."
    # Remove related articles at the very end
    $gardeningIdx = $c.LastIndexOf("`nGardening`n`n### ")
    if ($gardeningIdx -ge 0) {
        $c = $c.Substring(0, $gardeningIdx).TrimEnd() + "`n"
    }
    # Remove the "Do you have a backyard garden? Share..." social promo
    $c = $c -replace "\r?\nDo you have a backyard garden\?.*?promo code\]\(.*?\)\.\r?\n", ""
    # Remove broken SVG image links
    $c = $c -replace "!\[multiple garden beds.*?\]\(https://plantbasedonabudget\.com/.*?svg.*?\)\r?\n\r?\nmultiple garden beds.*?\r?\n\r?\n", ""
    $c = $c -replace "!\[garden bed with.*?\]\(https://plantbasedonabudget\.com/.*?svg.*?\)\r?\n\r?\ngarden bed with.*?\r?\n\r?\n", ""
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# The Dresden Files
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -eq "The Dresden Files.md" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Reading & Literature]]"
    # Remove the broken image (Ad.jpg is blocked by ad blockers)
    $c = $c -replace "!\[Rendition of 's business card\]\(https://dresdenfiles\.fandom\.com/wiki/Ad\.jpg\)\r?\n\r?\nRendition of Harry Dresden 's business card\r?\n\r?\n", ""
    # Remove References and External links sections (mostly navigation)
    # They contain useful links so I'll keep them
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# This is What a Normal Expense Ratio Fee Looks Like
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Expense Ratio*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Finance & Investment]]"
    # Remove "Add as a preferred source on Google" link (but keep the image)
    $c = $c -replace "\[Add as a preferred source on Google\]\(https://www\.google\.com/preferences/source\?q=lifehacker\.com\) ", ""
    # Remove "10\n\nWhat do you think so far?" counter
    $c = $c -replace "\r?\n10\r?\n\r?\nWhat do you think so far\?\r?\n\r?\n", "`n`n"
    # Remove "More by Lisa" and sidebar articles at bottom
    $moreByIdx = $c.IndexOf("More by Lisa")
    if ($moreByIdx -ge 0) {
        $c = $c.Substring(0, $moreByIdx).TrimEnd() + "`n"
    }
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# Use the Mobile Passport App
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Mobile Passport*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Travel & Exploration]]"
    # Fix tag: "MobilPassport" → "MobilePassport"
    $c = $c -replace '"MobilPassport"', '"MobilePassport"'
    # Remove "Add as a preferred source on Google" link
    $c = $c -replace "\[Add as a preferred source on Google\]\(https://www\.google\.com/preferences/source\?q=lifehacker\.com\)\r?\n\r?\n---\r?\n\r?\n", ""
    # Remove "28\n\nWhat do you think so far?" counter
    $c = $c -replace "\r?\n28\r?\n\r?\nWhat do you think so far\?\r?\n\r?\n", "`n`n"
    # Fix San Jose encoding
    $c = $c -replace "San Jos[^\s]+ International", "San Jose International"
    # Remove "More by Virginia" section
    $moreByIdx = $c.IndexOf("More by Virginia")
    if ($moreByIdx -ge 0) {
        $c = $c.Substring(0, $moreByIdx).TrimEnd() + "`n"
    }
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# You Need to Make a 'When I Die' File-Before It's Too Late
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*When I Die*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Home & Practical Life]]"
    # Remove "ADD TIME ON GOOGLE" link
    $c = $c -replace "\[ADD TIME ON GOOGLE\]\(.*?\)\r?\n\r?\n", ""
    # Remove "Advertisement" markers
    $c = $c -replace "\r?\nAdvertisement\r?\n\r?\n", "`n`n"
    # Fix bullet points that show as question marks (encoding issue)
    $c = $c -replace "(?m)^\? An advance directive", "- An advance directive"
    $c = $c -replace "(?m)^\? A will and living trust", "- A will and living trust"
    $c = $c -replace "(?m)^\? Marriage or divorce certificate", "- Marriage or divorce certificate"
    $c = $c -replace "(?m)^\? Passwords for phone", "- Passwords for phone"
    $c = $c -replace "(?m)^\? Instructions for your funeral", "- Instructions for your funeral"
    $c = $c -replace "(?m)^\? An ethical will", "- An ethical will"
    $c = $c -replace "(?m)^\? Letters to loved ones", "- Letters to loved ones"
    # Fix the by-line (currently "by and" since scraped poorly)
    $c = $c -replace "by and\r?\n\r?\n", "by Shoshana Berger and BJ Miller`n`n"
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

# ------------------------------------------------------------------
# Can You Say Hero (smart quotes in filename)
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Hero*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Replace the entire frontmatter with cleaned version
    $oldFM = @"
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
    $newFM = @"
---
nav: "[[00 - Home Dashboard/MOC - Reading & Literature]]"
title: "Can You Say Hero? | Esquire | November 1998"
source: "https://classic.esquire.com/article/1998/11/1/can-you-say-hero"
author:
  - "[[Tom Junod]]"
published: 1998-11-01
created: 2026-02-26
description: "Fred Rogers has been doing the same small good thing for a very long time — a profile of Mister Rogers by Tom Junod, Esquire 1998"
tags:
  - TV
  - MrRogers
  - Children
  - Kindness
  - Esquire
  - Profile
---
"@
    if ($c.Contains($oldFM)) {
        $c = $c.Replace($oldFM, $newFM)
        WriteUTF8 $file.FullName $c
        Write-Host "Updated: $($file.Name)"
    } else {
        # Try simpler approach - just add nav at start
        $c = AddNav $c "[[00 - Home Dashboard/MOC - Reading & Literature]]"
        WriteUTF8 $file.FullName $c
        Write-Host "Updated (nav only): $($file.Name)"
    }
}

# ------------------------------------------------------------------
# Discover Kolams
# ------------------------------------------------------------------
$file = Get-ChildItem -LiteralPath $clippings | Where-Object { $_.Name -like "*Kolam*" } | Select-Object -First 1
if ($file) {
    $c = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -Raw
    # Add nav
    $c = AddNav $c "[[00 - Home Dashboard/MOC - Science & Nature]]"
    # Remove social sharing line at start of body: "in | May 20th, 2019 [Leave a Comment]..."
    $c = $c -replace "(?m)^in \| May 20th, 2019 \[Leave a Comment\].*\r?\n\r?\n", ""
    # Remove social sharing buttons block (Bluesky, Facebook, etc.) at start of body
    $c = $c -replace "\[Bluesky\]\(https://www\.openculture\.com/#bluesky[^)]+\) \[Facebook\]\(https://www\.openculture\.com/#facebook[^)]+\).*?\[Share\]\(https://www\.addtoany\.com.*?\)\r?\n\r?\n", ""
    # Remove the second social sharing block and everything after (Support Open Culture, newsletter, etc.)
    $secondShareIdx = $c.LastIndexOf("[Bluesky](https://www.openculture.com/#bluesky")
    if ($secondShareIdx -ge 0) {
        $c = $c.Substring(0, $secondShareIdx).TrimEnd() + "`n"
    }
    # Fix hyphenated words throughout (remove inter-syllable hyphens)
    # Pattern: letter-hyphen-letter where hyphen is at end of a syllable (not a real compound word)
    # We use a regex to remove hyphens between lowercase letters
    $c = [regex]::Replace($c, '([a-z])-([a-z])', { param($m) $m.Groups[1].Value + $m.Groups[2].Value })
    # Fix specific words that got incorrectly joined (legitimate compounds/proper hyphenation)
    # None needed for this text
    # Also fix the capitalized word hyphenation at sentence starts
    $c = [regex]::Replace($c, '([A-Z][a-z]+)-([a-z])', { param($m) $m.Groups[1].Value + $m.Groups[2].Value })
    # Fix "k olam" back to "kolam" (there was a space inserted)
    $c = $c -replace '\bk olam\b', 'kolam'
    WriteUTF8 $file.FullName $c
    Write-Host "Updated: $($file.Name)"
}

Write-Host "`nAll files processed."
