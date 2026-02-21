# Script to check and add recipe tags to files linked in MOC - Recipes
# UTF-8 encoding is preserved throughout

# Define the files to check from the MOC
$files = @(
    'Vegan Black Bean Sou',
    'PersonalWeb - Black Bean Stew',
    'PersonalWeb - Enchilada Bean Soup',
    'Lentil Soup',
    'Red Lentil Soup in a',
    'Italian vegetable so',
    'PersonalWeb - Green Gumbo',
    'PersonalWeb - Mushroom Barley Stew',
    'Asian noodle soup wi',
    'This Creamy Instant',
    'Chickpea and Spinach',
    'eggplant and tomato',
    'Ethiopian Lentil and Vegetable Stew',
    'Curried Apple Daal S',
    'Tomato and Red Pepper Soup Recipe',
    'Healthy Chocolate Frosting Recipe',
    'Baking Pan Conversio',
    'Easy Carrot Ginger Dressing',
    'Vegan Black Bean Soup - Panera Bread Copycat',
    'Dreena''s No-fu Love',
    'Lo mein A healthy ma',
    'Southwestern Black B',
    'Vegan Barbecue Meatballs',
    'Spaghetti with White',
    'Gnocchi with Basil and Sun Dried Tomatoes',
    'Holly''s Rice and Bea',
    'red beans and rice',
    'Risotto Primavera',
    'Tom''s "Fried" Rice',
    'Spicy cauliflower ''s',
    'Curried Millet Cakes with Red Pepper Coriander Sauce & Mujadara',
    'tagine of red lentil',
    'Lentil Dal with Spin',
    'Vegetable Bean Medle',
    'Vegan Corned Beef an',
    'Vegan',
    'lettuce cups with so',
    'Vegan Crack Chilli T',
    'Chickpea Quinoa Burger',
    'Tomato Pie',
    'Veggie Kebabs',
    'Engine 2 Hummus Burg',
    'Easy Quinoa Tabboule',
    'quinoa and toasted p',
    'Rainbow Salad',
    'Recipe',
    'PersonalWeb - Potato Cakes',
    'Moroccan Mint Cousco',
    'Half-Shekel Carrot C',
    'SPICED AND HERBED MI',
    'Recipe Millet Salsa',
    'Aztec Corn Salad Recipe',
    'Fat-Free Whole Wheat',
    'Romano''s Macaroni Gr',
    'Yucca Focaccia',
    'Homemade Corn Tortil',
    'Sweet Potato Cassava',
    'Spiced Pumpkin Bread',
    'Spiced Pumpkin Oat M',
    'Strawberry Muffins',
    'Loosey-goosey Muffin',
    'Stevia Chocolate Chi',
    'Stevia Oatmeal Apple',
    'Fudgy Vegan Brownies',
    'Sweet Potato Brownie',
    'Silky Vegan Chocolate',
    'Sugar-Free Apple Pie',
    'Gingerbread Upside D',
    'Canadian War Cake or',
    'Wartime cake or eggless Cake',
    'PersonalWeb - Blackberry Bars',
    'Agave Graham Cracker',
    'Sugar-Free Vegan Pea',
    'PersonalWeb - Baked Apples',
    'Warm apple compote',
    'Aunt Hatties Caramel',
    'Sweet Spiced Pecans',
    'Chocolate Hazelnut G',
    'Adonis Cake Cake',
    'Apple Cake in a Croc',
    'Low-Fat Cucumber Cake',
    'World War 1 Cake',
    'More kissing, less k',
    'Rava Idli Recipe',
    'Classic Sauerkraut Recipe',
    '24-hour Kimchi Recipe',
    'Easy Cheesy Oat and',
    'Pinto Queso Dip with',
    'Spicy Queso Sause wi',
    'Smoked Vegetable Che',
    'PersonalWeb - Apple Chutney',
    'Hot pepper Jelly and',
    'Onion Marmalade',
    'Refrigerator Dills',
    'Ras el Hanout   Spice',
    'Pickled Onions',
    'Cajun Seasoning Recipe',
    'Easy Carrot Ginger D',
    'Cinnamon Orange Spic',
    'Indigenous South African Tea',
    '3 Expert Tips on How to Cook Without Oil',
    'Ginger, Turmeric, an',
    'Banana or Mango Lass',
    'Sweet potato lentil',
    'Sweet Potato-Cassava',
    'Sweet potato (and ma',
    'Sweet Potato and Chi',
    'Sweet Tomato Chutney'
)

# Define the vault root
$vaultRoot = 'D:\Obsidian\Main'

# Define exclusion patterns
$exclusions = @('09 - Kindle Clippings', 'MOC', 'Contact', 'Person')

# Counters for results
$counters = @{
    'added' = 0
    'already_had' = 0
    'not_found' = 0
    'skipped' = 0
}

Write-Host "Starting recipe tag check..." -ForegroundColor Green
Write-Host "Total files to check: $($files.Count)" -ForegroundColor Green
Write-Host ""

# Process each file
foreach ($fileName in $files) {
    # Search for the file in the vault
    $searchPattern = "$fileName*"
    $foundFiles = @()

    # Get all markdown files matching the pattern
    Get-ChildItem -Path $vaultRoot -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
        $_.BaseName -like $searchPattern
    } | ForEach-Object {
        # Check if it should be excluded
        $filePath = $_.FullName
        $skip = $false

        foreach ($exclusion in $exclusions) {
            if ($filePath -like "*$exclusion*") {
                $skip = $true
                break
            }
        }

        if (-not $skip) {
            $foundFiles += $_
        }
    }

    if ($foundFiles.Count -eq 0) {
        Write-Host "NOT FOUND: $fileName" -ForegroundColor Red
        $counters['not_found']++
    } elseif ($foundFiles.Count -eq 1) {
        $file = $foundFiles[0]

        # Check if file is in exclusion folder
        $filePath = $file.FullName
        $skip = $false
        foreach ($exclusion in $exclusions) {
            if ($filePath -like "*$exclusion*") {
                $skip = $true
                break
            }
        }

        if ($skip) {
            Write-Host "SKIPPED: $($file.BaseName) (in excluded folder)" -ForegroundColor Yellow
            $counters['skipped']++
            continue
        }

        # Read file with UTF-8 encoding
        $content = Get-Content -Path $filePath -Encoding UTF8 -Raw

        # Check if file already has recipe tag (YAML front matter or inline)
        $hasRecipeTag = $false

        # Check for YAML front matter with recipe tag
        if ($content -match "^---[\s\S]*?^---" -and $content -match "tags:[\s\S]*?recipe") {
            $hasRecipeTag = $true
        }

        # Check for inline #recipe tag
        if ($content -like "*#recipe*") {
            $hasRecipeTag = $true
        }

        if ($hasRecipeTag) {
            Write-Host "ALREADY HAD TAG: $($file.BaseName)" -ForegroundColor Green
            $counters['already_had']++
        } else {
            # Add recipe tag
            # Check if file starts with YAML front matter
            if ($content -match "^---") {
                # Try to add to YAML tags
                if ($content -match "^---\ntags: ") {
                    # Append to existing tags line
                    $newContent = $content -replace "(^---\ntags: [^\n]*)", "`$1 #recipe"
                } else {
                    # Add tags line after the opening ---
                    $newContent = $content -replace "^(---\n)", "`$1tags: #recipe`n"
                }
            } else {
                # No YAML, add inline tag at the end with newline
                if ($content.EndsWith("`n")) {
                    $newContent = $content + "#recipe`n"
                } else {
                    $newContent = $content + "`n#recipe`n"
                }
            }

            # Write file with UTF-8 encoding
            Set-Content -Path $filePath -Value $newContent -Encoding UTF8
            Write-Host "ADDED TAG: $($file.BaseName)" -ForegroundColor Cyan
            $counters['added']++
        }
    } else {
        Write-Host "MULTIPLE MATCHES FOUND: $fileName ($($foundFiles.Count) files)" -ForegroundColor Yellow
        foreach ($file in $foundFiles) {
            Write-Host "  - $($file.FullName)" -ForegroundColor Yellow
        }
        $counters['skipped'] += $foundFiles.Count
    }
}

Write-Host ""
Write-Host "========== SUMMARY ==========" -ForegroundColor Green
Write-Host "Added recipe tag: $($counters['added'])" -ForegroundColor Cyan
Write-Host "Already had tag: $($counters['already_had'])" -ForegroundColor Green
Write-Host "Not found: $($counters['not_found'])" -ForegroundColor Red
Write-Host "Skipped: $($counters['skipped'])" -ForegroundColor Yellow
Write-Host "============================" -ForegroundColor Green
