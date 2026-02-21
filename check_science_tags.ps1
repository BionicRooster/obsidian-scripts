# Script to check and add science tags to files linked in MOC - Science & Nature
# Preserves UTF-8 encoding

$vaultPath = "D:\Obsidian\Main"
Set-Location $vaultPath

# List of files to check from MOC - Science & Nature
$files = @(
    'micrometeorites',
    'Larsen-In Search of Stardust',
    'Larsen-On the Trail of Stardust The Guide to Finding Micrometeorites',
    'Hunt for meteorites',
    'How To Find Micrometeorites',
    'How To Find micrometeorites In Your Home',
    'PDF - Astrophysics at home - Micrometeorites',
    "Protecting Arizona's Petrified Forest",
    'Devastating Ice Age Floods',
    '650-foot mega-tsunami',
    'Robinson-Ice Age Flood Tour in Full Color',
    'Soennichsen-Washingtons Channeled Scablands Guide',
    'Methane explosion cr',
    'Ancient Farmers transformed Amazon and left an enduring legacy',
    'Secret Tunnel May Finally Solve the Mysteries of Teotihuacán',
    'Tellinger-Temples of The African Gods',
    'Neanderthals Built Mysterious Stalagmite Semicircles',
    "Horse Poop Helps Unravel the mystery of Hannibal's Route",
    "The 'Nutcracker Man'",
    "Easter Island Wasn't Destroyed by War",
    'As the Arctic Erodes, Archaeologists Are Racing to Protect Ancient Treasures',
    'Archaeologists Dig Up An 800-Year-Old Native American Pot',
    'Ancient Romans Used Lead In Their Ink',
    'Why archaeologists are arguing about sweet potatoes',
    'High-tech lidar help',
    'A Space Archaeologist',
    'Native Knowledge Wha',
    'Advantages and disadvantages to planting moss',
    'Low allergy mossess',
    'Can plants improve i',
    'Fig Tree Pruning Plan',
    'Blenheim Apricot Trees',
    'Turtle plant',
    'Native land stewardship can outdo nature',
    'Eye-opening conserva',
    'These Massive Rock F',
    'The 390 YO Tree Survived Bombing of Hiroshima',
    'A Scottish Duke Transformed This Abandoned Coal Mine',
    'Scientists declare octopi life from another world',
    'Meet A Real-Life Mar',
    'Your Genetic Journey',
    'Why humans have allergies',
    'Human Diseases May H',
    'Research Reveals Mor',
    'Discovery Of Fairy C',
    'The Real Cost Of NASA Missions',
    'Machine Learning May',
    'IBM Research Thinks'
)

# Counters
$added = 0
$alreadyHad = 0
$notFound = 0
$skipped = 0

# Process each file
foreach ($fileName in $files) {
    # Try to find the file with .md extension
    $mdFiles = Get-ChildItem -Path '.' -Recurse -Filter "$fileName.md" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notlike '*09 - Kindle Clippings*' }

    if ($mdFiles.Count -eq 0) {
        Write-Host "[NOT FOUND] $fileName"
        $notFound++
    } else {
        foreach ($mdFile in $mdFiles) {
            # Skip if it's a MOC file or contact file
            if ($mdFile.Name -like '*MOC*' -or $mdFile.Name -like '*Contact*' -or $mdFile.Name -like '*Person*') {
                Write-Host "[SKIPPED] $($mdFile.FullName)"
                $skipped++
                continue
            }

            # Read the file with UTF-8 encoding
            $content = [System.IO.File]::ReadAllText($mdFile.FullName, [System.Text.Encoding]::UTF8)

            # Check if file has science tag (YAML or inline)
            if ($content -match '(?:^tags:|tags:.*science|#science)') {
                Write-Host "[HAS TAG] $($mdFile.FullName)"
                $alreadyHad++
            } else {
                # Add the tag
                # Check if file has YAML front matter
                if ($content -match '^---') {
                    # File has YAML, add to tags line or create tags line
                    if ($content -match 'tags:') {
                        # Append to existing tags line
                        $newContent = $content -replace '(tags:[^\n]*)', "`$1 science"
                    } else {
                        # Add tags line before closing ---
                        $newContent = $content -replace '(^---\s*\n)(.*?)(\n---)', "`$1`$2`ntags: science`$3"
                    }
                } else {
                    # No YAML, add inline tag at the end
                    $newContent = $content.TrimEnd() + "`n`n#science"
                }

                # Write back with UTF-8 encoding (no BOM)
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
                [System.IO.File]::WriteAllBytes($mdFile.FullName, $bytes)
                Write-Host "[ADDED] $($mdFile.FullName)"
                $added++
            }
        }
    }
}

Write-Host ""
Write-Host "===== SUMMARY ====="
Write-Host "Added: $added"
Write-Host "Already Had: $alreadyHad"
Write-Host "Not Found: $notFound"
Write-Host "Skipped: $skipped"
