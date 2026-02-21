# Show which files are missing the NLP_Psy tag

# Array of all unique files from the MOC
$files = @(
    'Discussion of NLP -1',
    'Discussion of Missio',
    'Prove the Theorem -1',
    'Metamodel III 1',
    'NLP Presupposition-1',
    'Presuppositions of NLP',
    'Childhood Developmental Stages',
    'NLP for Programmer-1',
    'Making changes NLP',
    'NLP for Programmers',
    'NLP thoughts 1234579',
    'NLP Meta Programs, b',
    'Six Step Reframe w-1',
    'Metamodel III 4',
    'Metamodel III 3',
    '20 primary technique',
    'NLP Intervention and',
    'NLP CompuServe Directory',
    'NLP Techniques',
    'Yes Sayers, No Sayer',
    'NLP Presuppositions',
    'Product or Discipline',
    'Product of Discipline',
    'TRANSCRIPT OF A COMP',
    'Major Presupposition',
    'Six Themes of NLP',
    'Six Step Reframe',
    'Six Step Reframe wit',
    'Reframing Patterns o',
    'Prove the Theorem Pt',
    'Fast Phobia Cure',
    'Fast Phobia Cure V2',
    'Fast Phobia Cure V3',
    'Change Personal History',
    'Time Line Therapy',
    'Cellular Change',
    'Circle of Excellence',
    'Anchor Point  and Mu',
    'Rapport with Self',
    'Alignment of Logical',
    'Wired Logical Levels',
    'Moving Through Logic',
    'Advanced Language Pa',
    'Embedded Commands in',
    'Making changes using',
    'Discussion of NLP Me',
    'Visual Reading Strategy',
    'Procrastination Stra',
    'Quick Profiling',
    'Well Formed Outcomes',
    'Outcome Specificatio',
    'Specific Ecology Che',
    'ROET Chart',
    'SCORE in Business',
    'Paradoxical Persuasi',
    'Eliciting Beliefs',
    'TransDerivational Se',
    'The Advantages of Dyslexia',
    'The Advantages of Dy',
    'Thinking, Fast and S',
    'Kahneman-Thinking Fast and Slow',
    'Native Knowledge Wha',
    'My Color Blindness 1',
    'Education 3.0',
    'Dunning–Kruger effect - Wikipedia',
    'Ahrens-How to Take S',
    'Thinking, Fast and Slow',
    'Cocktail Party Effect',
    'Inattentional Blindness An Overview',
    'Misdirected Attentio',
    'Identifiable Victim',
    'What''s Wired In',
    'The Power of Free',
    'Jigsaw Puzzles Can I',
    '5 Strategies to Demystify the Learning Process for Struggling Students',
    'Bloom''s Taxonomy of',
    'Meta Model Patterns',
    'Embeded Commands in',
    'NLP Flow',
    'Prove the Theorem P3',
    'Prove the Theorem -2',
    'Prove the Theorem -3',
    'Prove the Theorem -4',
    'NLP FAQ 1992',
    'NLP Letter',
    'NLP Training Week 7',
    'NLP World',
    'NLP World Pt 2',
    'ANDREW MORENO CHALLE',
    'Progress Reports 1 a',
    'Ramblings 3',
    'Ramblings 5',
    'Ramblings 5 Afterwor',
    'Ramblings 5 Aferword',
    'Quiz Time',
    'Multiple time series',
    'Kahneman-Thinking, Fast and Slow',
    'Behavioral Science P',
    'An Autistic Mind An Autistic Mind Opens Mine',
    'Changing These 4 Bel',
    'The Johnson Treatment'
)

# Get unique files
$uniqueFiles = $files | Sort-Object | Get-Unique

# Initialize lists
$missingList = @()
$foundMissing = 0

Write-Output "Checking for files missing NLP_Psy tag..."
Write-Output ""

foreach ($fileName in $uniqueFiles) {
    # Search for file in vault
    $foundFiles = $null
    try {
        $foundFiles = @(Get-ChildItem -Path 'D:\Obsidian\Main' -File -Filter "$fileName*" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.md' })
    } catch {
        # Ignore errors
    }

    if ($foundFiles.Count -eq 0) {
        continue
    }

    # Process first match
    $filePath = $foundFiles[0].FullName

    # Skip exclusions
    if ($filePath -like '*09 - Kindle Clippings*') {
        continue
    }

    if ($fileName -like 'MOC*') {
        continue
    }

    # Read file with UTF-8 encoding (just first 20 lines for speed)
    try {
        $firstLines = @(Get-Content -Path $filePath -Encoding UTF8 -TotalCount 20)
    } catch {
        continue
    }

    # Check if has NLP_Psy tag
    $hasTag = $false
    foreach ($line in $firstLines) {
        if ($line -match 'NLP_Psy' -or $line -match '#NLP_Psy') {
            $hasTag = $true
            break
        }
    }

    if (-not $hasTag) {
        $missingList += $fileName
        $foundMissing++
        Write-Output "MISSING: $fileName"
        Write-Output "  Path: $filePath"
    }
}

Write-Output ""
Write-Output "========== MISSING TAG SUMMARY =========="
Write-Output "Total missing NLP_Psy tag: $foundMissing"
Write-Output "=========================================="
