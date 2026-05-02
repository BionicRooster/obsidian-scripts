# update_recipes_moc.ps1
# Adds missing wikilinks to MOC - Recipes.md and adds nav properties to recipe files
# Uses UTF-8 encoding throughout

$ErrorActionPreference = 'Continue'

# Encoding objects - UTF-8 without BOM for reading, UTF-8 for writing
$utf8 = [System.Text.Encoding]::UTF8
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# Path to the MOC file
$mocPath = 'D:\Obsidian\Main\00 - Home Dashboard\MOC - Recipes.md'

# Read MOC content
$mocContent = [System.IO.File]::ReadAllText($mocPath, $utf8)

# Counter for links added
$linksAdded = 0

# Helper: check if a string is already present in the MOC content (case-insensitive)
function ContainsLink($content, $linkText) {
    # Strip the [[ and ]] for a looser check
    $inner = $linkText -replace '^\[\[', '' -replace '\]\]$', ''
    return $content -imatch [regex]::Escape($inner)
}

# Helper: add a wikilink bullet after a section header
# Appends $linkLine (e.g., "- [[Foo]]") as a new line within the section
function AddToSection($content, $sectionHeader, $linkLine) {
    # Find the section and insert after the last bullet in it
    # Strategy: find the section header, then find the next section header or end
    # Insert the new line just before the next ## or end-of-section blank+##

    # Build regex to find the section block
    $escapedHeader = [regex]::Escape($sectionHeader)

    # Find position of section header
    $headerIdx = $content.IndexOf($sectionHeader)
    if ($headerIdx -lt 0) {
        Write-Host "  WARNING: Section '$sectionHeader' not found in MOC"
        return $content
    }

    # Find where this section ends: next ## heading or end of file
    $afterHeader = $content.Substring($headerIdx + $sectionHeader.Length)

    # Look for next section starting with ## (but not ###)
    $nextSectionMatch = [regex]::Match($afterHeader, '(?m)^## ')

    if ($nextSectionMatch.Success) {
        # Insert before the next section header
        $insertPos = $headerIdx + $sectionHeader.Length + $nextSectionMatch.Index
        # Walk back to find a good insertion point (before blank lines before next section)
        # Insert after the last non-empty line in this section
        $sectionBlock = $content.Substring($headerIdx, $nextSectionMatch.Index + $sectionHeader.Length)
        # Find last line with content (a bullet)
        $lines = $sectionBlock -split "`n"
        $lastBulletIdx = -1
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            if ($lines[$i].TrimEnd() -ne '' -and $lines[$i].TrimEnd() -ne $sectionHeader.TrimEnd()) {
                $lastBulletIdx = $i
                break
            }
        }
        if ($lastBulletIdx -ge 0) {
            # Reconstruct: join up to and including lastBulletIdx, add new line, then rest
            $before = ($lines[0..$lastBulletIdx] -join "`n")
            $after = ($lines[($lastBulletIdx + 1)..($lines.Count - 1)] -join "`n")
            $newSection = $before + "`n" + $linkLine + "`n" + $after
            return $content.Substring(0, $headerIdx) + $newSection + $content.Substring($headerIdx + $sectionHeader.Length + $nextSectionMatch.Index)
        }
    }

    # Fallback: just append after header line
    $insertPos = $headerIdx + $sectionHeader.Length
    return $content.Substring(0, $insertPos) + "`n" + $linkLine + $content.Substring($insertPos)
}

# Define the links to add per section
# Format: section header => array of wikilink strings
$toAdd = @{
    '## Soups & Stews' = @(
        '[[Asian Noodle Soup with Mini Portabellas]]',
        '[[Broccoli Curry Udon]]',
        '[[Chipotle Sweet Potato and Black Bean Chili]]',
        '[[Curried Apple Daal Stew]]',
        '[[Dal]]',
        '[[Eggplant and Tomato Stew]]',
        '[[Greek Giant Bean Soup with Spinach]]',
        '[[Green Gumbo (Gumbo Z' + "'" + 'Herbes)]]',
        '[[Italian Vegetable Soup]]',
        '[[Javanese Vegan Chicken Soup (Soto Ayam)]]',
        '[[Javanese-Inspired ?Chicken? Soup (Vegan Soto Aya m)]]',
        '[[Lemon Lentil Soup]]',
        '[[Lentil Soup Recipe]]',
        '[[Lentil Vegetable Curry]]',
        '[[Mega Veggie Vegan Chili]]',
        '[[Quinoa White Bean and Kale Stew]]',
        '[[Recipe_ Asian Noodle Soup with Mini Portabellas]]',
        '[[Recipe_ Eggplant and Tomato Stew]]',
        '[[Recipe_ Italian Vegetable Soup]]',
        '[[Recipe_ Roasted Carrot Curry Noodle Soup - Recipe]]',
        '[[Red Lentil Soup in a Flash]]',
        '[[Roasted Carrot Curry Noodle Soup]]',
        '[[Slow Cooker Butternut Squash Dal 1]]',
        '[[Slow Cooker Vegan Irish Stew]]',
        '[[Irish Eyes Are Smiling on Vegan Irish Stew (Recipe)]]'
    )
    '## Main Dishes' = @(
        '[[Air Fried Tofu Italian Style]]',
        '[[Baked Egg Rolls]]',
        '[[Baked Falafel Pita Sandwiches]]',
        '[[Baked Samosas with Chickpea Filling]]',
        '[[Baked Tofu with Cilantro Pesto - Recipe]]',
        '[[Black Bean and Onion Pilaf 1]]',
        '[[Black Bean Tacos with Persimmon Salsa and Lime Crema]]',
        '[[Brats]]',
        '[[Buttery Moong Dal]]',
        '[[Chana Dal Sundal]]',
        '[[Chana Masala]]',
        '[[Chana Masala (North Indian Chickpea Curry)]]',
        '[[Chicken and Shiitake Mushroom Lo Mein]]',
        '[[Chili Rellnos]]',
        '[[Dreena' + "'" + 's No-fu Love Loaf 1]]',
        '[[Dublin Coddle with Vegan Irish Sausage - Recipe - Recipe]]',
        '[[Dublin Coddle with Vegan Sausages]]',
        '[[Easy Red Beans and Rice 1]]',
        '[[Easy Vegan Spinach and Mushroom Lasagna]]',
        '[[Four Simple Slow-Cooker Recipes Our Family Loves [feedly]]]',
        '[[Frittata with Spinach and Leeks]]',
        '[[Ginger Veggie Stir-Fry]]',
        '[[Gobi Paratha (Indian Flatbread Stuffed with Cauliflower)]]',
        '[[Greens Quiche]]',
        '[[Grilled Portobello Mushrooms]]',
        '[[Ham and Cheese Puffs]]',
        '[[Healthy Sesame Soba Noodles with Spinach and Tofu [feedly] Recipe]]',
        '[[Indian Tofu with Spinach]]',
        '[[Irish Fauxsages (Vegan Sausages)]]',
        '[[Japanese-Style Braised Tofu with Root Vegetables, Shiitakes, Red Chard, and Quick Pickles Recipe]]',
        '[[Kale with Mushrooms and Water Chestnuts]]',
        '[[Kichri with Massour Dal]]',
        '[[Lemon Tempeh Air Fryer Sheet Pan Dinner]]',
        '[[Lo Mein]]',
        '[[Mushrooms on Sourdough Toast 1]]',
        '[[One-Pot Sicilian Couscous]]',
        '[[Quinoa-Polenta with BBQ Sauce]]',
        '[[Raise the Roof Sweet Potato Lasagna]]',
        '[[Recipe_ Lettuce Cups with Soft Tofu and Vegetables]]',
        '[[Recipe_ Millet Salsa Bowls!]]',
        '[[Recipe_ Mixed Veggie Saute with Chickpeas and Quinoa]]',
        '[[Recipe_ Red Beans and Rice]]',
        '[[Recipe_ Tagine of Red Lentils, Brown Rice, and Tomatoes]]',
        '[[Recipe_ Veggie Potato Hash with Kale]]',
        '[[Ridiculously Easy Vegetable Fried Rice]]',
        '[[Shrimp Remoulade]]',
        '[[Simple Black Bean Burger]]',
        '[[Slow Cooker Tamarind Baked Beans]]',
        '[[Spaghetti with White Bean Marinara Sauce]]',
        '[[Spicy Queso Sauce with Quinoa]]',
        '[[Spicy Vegan Fried Chicken Soy Curls]]',
        '[[Stir-Fried Black Bean Noodles in Orange Sauce Recipe - Recipe]]',
        '[[Stuffed Mushrooms]]',
        '[[Stuffed Poblanos]]',
        '[[Tofu Paratha]]',
        '[[Tofu Paratha Recipe - Holy Cow! Vegan Recipes]]',
        '[[Tofu Scramble and Collard Greens]]',
        '[[Vegan Asparagus and Mushroom Pasta]]',
        '[[Vegan Butter Chicken]]',
        '[[Vegan Butternut Squash Curry]]',
        '[[Vegan Corned Beef and Cabbage]]',
        '[[Vegan Dal Makhani]]',
        '[[Vegan Roasted Cauliflower Mac and Cheese]]',
        '[[Vegan Sloppy Giuseppes]]',
        '[[Vegetable Korma]]',
        '[[Zuccini and Quinoa Lassagna Recipe]]'
    )
    '## Sides & Salads' = @(
        '[[Broccoli and Onion Pakora]]',
        '[[Crispy Fat-Free Spanish Potatoes 1]]',
        '[[Easy Quinoa Tabbouleh Salad]]',
        '[[Eggless Egg and Garden Veggie Salad]]',
        '[[Marinated Green Beans]]',
        '[[Oven-Roasted Corn on the Cob]]',
        '[[Recipe - Half-Shekel Carrot Coins]]',
        '[[Recipe Kale Salad - Recipe]]',
        '[[Recipe_ Quinoa and Toasted Peanut Salad]]',
        '[[Red Rice and Quinoa Stuffing With Mushrooms and Kale]]',
        '[[Roasted Asparagus with Pine Nuts]]',
        '[[Roasted Butternut Squash with Indian Spices]]',
        '[[Sweet Potato Grits]]',
        '[[Sweet Potato Latkes]]',
        '[[What the Kale Salad]]',
        '[[Wild Rice and Brown Rice Stuffing With Apples, Pecans and Cranberries]]'
    )
    '## Breads & Baked Goods' = @(
        '[[1_15 Buns Recipe]]',
        '[[Boston Brownbread Muffins]]',
        '[[Easy, Healthy, Vegan Soda Bread for St. Paddy?s Da y]]',
        '[[English Muffins (No Oil)]]',
        '[[Garbanzo Bread (or Buns) Recipe]]',
        '[[Homemade Corn Tortillas]]',
        '[[Honey Spice Bread]]',
        '[[Loosey-Goosey Muffins]]',
        '[[Loosey-Goosey Mufins 1]]',
        '[[Rice Cooker Pancakes]]',
        '[[Romano' + "'" + 's Macaroni Grill Focaccia]]',
        '[[Spiced Pumpkin Oat Muffins]]',
        '[[Sweet Potato (and Marshmallow) Biscuits]]',
        '[[Sweet Potato Cassava Tortillas]]',
        '[[Vegan Irish Soda Bread]]',
        '[[Vegan Irish Soda Bread (Whole Wheat)]]',
        '[[Zucchini and Carrot Muffins]]',
        '[[Recipe_ Throwback Oatmeal Muffins]]'
    )
    '## Desserts & Sweets' = @(
        '[[Carob Pie]]',
        '[[Chocolate Espresso Truffle Pie Recipe]]',
        '[[Cinnamon Apple Bread Pudding]]',
        '[[Cookies]]',
        '[[Gingerbread Upside Down Cake]]',
        '[[Low Carb Almond Pie Crust]]',
        '[[Pumpkin Cheesecake Pie]]',
        '[[Recipe Carob Pie - Recipe]]',
        '[[Vegan Carrot Halwa (Gajar ka Halwa)]]'
    )
    '## Sauces, Dips & Condiments' = @(
        '[[FW_ Hot Sauce Recipe]]',
        '[[Green Tea Dip and Spread]]',
        '[[Homemade Horseradish]]',
        '[[Hot Pepper Jelly and Cranberry Chutney Recipe]]',
        '[[Moroccan Carrot Dip]]',
        '[[Ridiculously Easy Jalapeno Pickles]]',
        '[[Salt-Free Spice Blends]]',
        '[[Sesame Ami Soy-Roasted]]',
        '[[Sweet Tomato Chutney Recipe]]',
        '[[Vegan Spinach Artichoke Dip]]',
        '[[Warm Pineapple Salsa]]'
    )
    '## Beverages' = @(
        '[[Banana or Mango Lassi]]',
        '[[Fat Free Soy Milk]]',
        '[[Ginger, Turmeric, and Lemon Tea]]'
    )
    '## Reference' = @(
        '[[How to Free Yourself from Recipes with a Few Golden Cooking Ratios]]',
        '[[Rancho Gordo News_ A Most Unusual (and Delicious) Bean Dish, Plus A New Video]]',
        '[[Starwest February-March 2010 Newsletter]]',
        '[[Starwest Holiday ' + "'" + '09 Newsletter with Savings!]]',
        '[[Starwest June-July 2011 Newsletter]]',
        '[[The Diabetic Newsletter - November 27, 2006 - DiabeticGourmet.com]]',
        '[[The Diabetic Newsletter - September 19, 2005 - TheDiabeticNews.com]]',
        '[[This Baking Chart Helps You Convert Between Pan Sizes]]',
        '[[Vegan Planet]]',
        '[[What is Curry]]',
        '[[Fw_ Turkey Recipe for You ...]]',
        '[[Recipe_ Mega-Awesome Fruit Bowl Snack]]',
        '[[Showing Up for Yourself Plus a Surprisingly Simple Recipe]]'
    )
}

# Process each section
Write-Host "`n=== Processing MOC sections ==="

foreach ($section in $toAdd.Keys) {
    $links = $toAdd[$section]
    Write-Host "`nSection: $section"

    foreach ($link in $links) {
        # Extract the inner name for existence checking
        $inner = $link -replace '^\[\[', '' -replace '\]\]$', ''

        # Check if something very similar already exists
        if (ContainsLink $mocContent $inner) {
            Write-Host "  SKIP (exists): $link"
        } else {
            Write-Host "  ADD: $link"
            $mocContent = AddToSection $mocContent $section "- $link"
            $linksAdded++
        }
    }
}

# Write updated MOC back
[System.IO.File]::WriteAllText($mocPath, $mocContent, $utf8NoBom)
Write-Host "`n=== MOC updated: $linksAdded links added ==="

# ============================================================
# Step 3: Add nav property to recipe files
# ============================================================

$recipesFolder = 'D:\Obsidian\Main\01\Recipes'
$navValue = 'nav: "[[MOC - Recipes]]"'
$navAdded = 0
$navSkipped = 0

Write-Host "`n=== Processing nav properties for recipe files ==="

$files = Get-ChildItem $recipesFolder -Filter '*.md' | Sort-Object Name

foreach ($file in $files) {
    $filePath = $file.FullName
    $content = [System.IO.File]::ReadAllText($filePath, $utf8)

    # Check if nav property already exists
    if ($content -match '(?m)^nav:') {
        $navSkipped++
        continue
    }

    # Check if frontmatter exists (starts with ---)
    if ($content -match '(?s)^---\r?\n.*?\r?\n---') {
        # Has frontmatter - add nav after the first ---
        $newContent = $content -replace '(?m)^---(\r?\n)', "---`$1nav: `"[[MOC - Recipes]]`"`$1"
        [System.IO.File]::WriteAllText($filePath, $newContent, $utf8NoBom)
        Write-Host "  NAV added (existing FM): $($file.Name)"
        $navAdded++
    } else {
        # No frontmatter - add minimal frontmatter block at top
        $newContent = "---`nnav: `"[[MOC - Recipes]]`"`n---`n" + $content
        [System.IO.File]::WriteAllText($filePath, $newContent, $utf8NoBom)
        Write-Host "  NAV added (new FM): $($file.Name)"
        $navAdded++
    }
}

Write-Host "`n=== SUMMARY ==="
Write-Host "MOC links added: $linksAdded"
Write-Host "Nav properties added: $navAdded"
Write-Host "Nav properties skipped (already had nav): $navSkipped"
