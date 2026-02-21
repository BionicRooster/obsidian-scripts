# Script to check and add Health tag to MOC-linked files
# Location: D:\Obsidian\Main
# Preserves UTF-8 encoding

# File names from MOC - Health & Nutrition
$filesToCheck = @(
    'The foods that make',
    'Vegan Black Bean Soup - Panera Bread Copycat',
    'VEGETARIAN BLACK BEAN CHILI',
    'Low Fat, Whole Grain',
    'My Journey from Junk-Food Vegan to Whole-Food, Plant-Based',
    'Why plant protein is HEALTHIER',
    'Vegan Cruises + Tips',
    'Vegan Date Spice Muffins or Bread',
    'What are Lentils',
    'Is Vitamin D the The Wonder Vitamin',
    'Rava Idli Recipe',
    'Vitamin D Supplement Information',
    '3 Expert Tips on How to Cook Without Oil',
    'Can We Eat to Starve Cancer',
    'Prostate healthy tip',
    'Anemia in Vegan Men',
    'The McDougall Newsle',
    'Q&A with Dr. Esselstyn',
    'Campbell-Campbell-The China Study Revised and Expanded Edition',
    'Campbell-Jacobson-Whole Rethinking the Science of Nutrition',
    'Campbell_et_al-The China Study',
    'M.D-Prevent and Reverse Heart Disease',
    'MD-MD-Keep It Simple, Keep It Whole',
    'Nestor-Breath',
    'Pos-T-Vac Mach Tension Rings',
    'How India''s air poll',
    'Powdered Booze Could',
    'You Need to Make a ''',
    'Infant Respiratory D',
    'Vik Veer - Which Imp',
    'The affordable tea t',
    'My Patient Didn''t Ju',
    'medical',
    'Child diabetes blame',
    '2003-10-21',
    'What Is Odontology W',
    'What''s really behind',
    'chronic obstructive pulmonary disease and premature birth',
    'Man Saves Wife''s Sight by 3D Printing Her Tumor',
    'Medical Info 1',
    'How Microbes Contribute To Heart Disease',
    'Hibiclels Uses, Side',
    'The Boil',
    'my knee',
    'Cataract lens transmissability',
    'Sugar Substitutes',
    'bronchopulmonary dys',
    'Your Sniffles Could',
    'New Alzheimer''s treatment',
    'Young adults born pr',
    'Eight Hip Stretches',
    'How to Have a ''Brain',
    'Is It a Cold or the',
    'How Tuberculosis Sha',
    'Humana Surgery',
    'Cataract replacement lens choices',
    'Post Covid Cough',
    'The Selling of ADHD',
    'As a BRAIN Doctor, I',
    'Inemuri, the Japanese Art of Taking Power Naps',
    'How to boost your ca',
    'Dyslexia May Be the Brain Struggling to Adapt',
    'Alcon Panoptix Pro Lens',
    'What Your Nails Can Tell You About Your Health',
    'How to sleep for 5 s',
    'Anterior cervical discectomy and fusion (ACDF) surgery',
    'Impaired lung function and health status',
    'Allergy Cure',
    'Dr Frachtman Pill Ca',
    'My Knee',
    'Coronavirus chart 1',
    'Coronavirus chart',
    'CORONA Common Sense',
    'How the coronavirus',
    'Coronavirus Chart',
    'Stopping Pandemics',
    'The Health Benefits',
    'How to Tell if Your ',
    'The Health Benefits of Walking',
    'Walking is a Basic H',
    'The Health Benefits ',
    'Study confirms a physical correlate to PTSD brown dust in the brain',
    'The Carnivore Goes to Plant-Stock',
    'Why I Abandoned Traditional Cardiology to Become the Healthy Heart Doc',
    'So, What is a Plant-',
    'The Engine 2 Diet  Hummus Burgers',
    'Ami''s Farms to Forks experience'
)

# Initialize counters
$counters = @{
    'Added' = 0
    'AlreadyHad' = 0
    'NotFound' = 0
    'Skipped' = 0
}

# Vault root directory
$vaultRoot = 'D:\Obsidian\Main'

# Process each file
foreach ($fileName in $filesToCheck) {
    # Search for the file in the vault
    $foundFiles = Get-ChildItem -Path $vaultRoot -Filter "$fileName.md" -Recurse -ErrorAction SilentlyContinue

    # Check if file was found
    if ($null -eq $foundFiles -or $foundFiles.Count -eq 0) {
        Write-Host "NOT FOUND: $fileName"
        $counters['NotFound']++
        continue
    }

    # Get the first match if multiple found
    $filePath = $foundFiles[0].FullName

    # Skip if file is in Kindle Clippings folder
    if ($filePath -like '*09 - Kindle Clippings*') {
        Write-Host "SKIPPED: $fileName (Kindle Clippings)"
        $counters['Skipped']++
        continue
    }

    # Skip MOC files
    if ($fileName -like 'MOC*') {
        Write-Host "SKIPPED: $fileName (MOC file)"
        $counters['Skipped']++
        continue
    }

    # Read file with UTF-8 encoding
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

    # Split content to examine first part for frontmatter
    $lines = $content -split "`n"

    # Check if file already has Health tag (in YAML or inline)
    $hasHealthTag = $content -match '(^tags:\s*\[.*?Health.*?\]|#Health)'

    if ($hasHealthTag) {
        Write-Host "ALREADY HAD: $fileName"
        $counters['AlreadyHad']++
        continue
    }

    # Check if file has YAML frontmatter
    $hasFrontmatter = $lines[0] -eq '---'

    if ($hasFrontmatter) {
        # Find end of frontmatter
        $frontmatterEnd = -1
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -eq '---') {
                $frontmatterEnd = $i
                break
            }
        }

        if ($frontmatterEnd -gt 0) {
            # Check if tags exist in frontmatter
            $tagsLineIndex = -1
            for ($i = 1; $i -lt $frontmatterEnd; $i++) {
                if ($lines[$i] -like 'tags:*') {
                    $tagsLineIndex = $i
                    break
                }
            }

            if ($tagsLineIndex -ge 0) {
                # Append Health to existing tags array
                $lines[$tagsLineIndex] = $lines[$tagsLineIndex] -replace '\]', ', Health]'
            } else {
                # Add new tags line before closing ---
                [array]::Reverse($lines, $frontmatterEnd, $lines.Count - $frontmatterEnd)
                $lines = $lines[0..$($frontmatterEnd - 1)] + "tags: [Health]" + $lines[$frontmatterEnd..$($lines.Count - 1)]
                [array]::Reverse($lines, $frontmatterEnd, $lines.Count - $frontmatterEnd + 1)
            }
        }
    } else {
        # No frontmatter, add one at the beginning
        $newFrontmatter = @(
            '---'
            'tags: [Health]'
            '---'
            ''
        )
        $lines = $newFrontmatter + $lines
    }

    # Write back with UTF-8 encoding
    $newContent = $lines -join "`n"
    [System.IO.File]::WriteAllText($filePath, $newContent, [System.Text.Encoding]::UTF8)

    Write-Host "ADDED: $fileName"
    $counters['Added']++
}

# Display summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Added Health tag: $($counters['Added'])" -ForegroundColor Green
Write-Host "Already had tag: $($counters['AlreadyHad'])" -ForegroundColor Blue
Write-Host "Not found: $($counters['NotFound'])" -ForegroundColor Yellow
Write-Host "Skipped: $($counters['Skipped'])" -ForegroundColor Magenta
Write-Host "TOTAL: $($counters['Added'] + $counters['AlreadyHad'] + $counters['NotFound'] + $counters['Skipped'])"
