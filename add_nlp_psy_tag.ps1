# Script to add NLP_Psy tag to all files linked in MOC - NLP & Psychology
# Excludes: 09 - Kindle Clippings, MOC files, and contact/person files

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

# Initialize counters
$added = 0
$alreadyHad = 0
$notFound = 0
$skipped = 0
$processedFiles = @()

Write-Output "Processing $($uniqueFiles.Count) unique files..."
Write-Output ""

foreach ($fileName in $uniqueFiles) {
    # Search for file in vault
    $foundFiles = Get-ChildItem -Path 'D:\Obsidian\Main' -File -Filter "$fileName*" -Recurse | Where-Object { $_.Extension -eq '.md' }

    if ($foundFiles.Count -eq 0) {
        # Try exact match
        $foundFiles = Get-ChildItem -Path 'D:\Obsidian\Main' -File -Filter "$fileName.md" -Recurse
    }

    if ($foundFiles.Count -eq 0) {
        Write-Output "NOT FOUND: $fileName"
        $notFound++
        continue
    }

    # Process first match (handle multiple matches)
    $filePath = $foundFiles[0].FullName

    # Check exclusions
    if ($filePath -like '*09 - Kindle Clippings*') {
        Write-Output "SKIPPED (Kindle Clippings): $fileName"
        $skipped++
        continue
    }

    if ($fileName -like 'MOC*') {
        Write-Output "SKIPPED (MOC file): $fileName"
        $skipped++
        continue
    }

    # Read file with UTF-8 encoding
    try {
        $content = Get-Content -Path $filePath -Encoding UTF8 -Raw
    } catch {
        Write-Output "ERROR reading $fileName : $_"
        continue
    }

    # Check if file already has the tag (case-insensitive)
    if ($content -match '(---\s*.*?---.*?tags:\s*\[.*?NLP_Psy.*?\]|#NLP_Psy)' -or $content -match 'NLP_Psy') {
        Write-Output "ALREADY HAS TAG: $fileName"
        $alreadyHad++
        continue
    }

    # Add the tag
    if ($content -match '---\s') {
        # Has YAML frontmatter
        if ($content -match 'tags:\s*\[([^\]]*)\]') {
            # Has tags array, add NLP_Psy
            $content = $content -replace '(tags:\s*\[)([^\]]*)\]', '$1$2, NLP_Psy]'
        } else {
            # No tags array, add one
            $content = $content -replace '(---\s*\n)', "`$1tags: [NLP_Psy]`n"
        }
    } else {
        # No frontmatter, add one
        $content = "---`ntags: [NLP_Psy]`n---`n$content"
    }

    # Write back with UTF-8 encoding
    try {
        Set-Content -Path $filePath -Value $content -Encoding UTF8
        Write-Output "ADDED TAG: $fileName"
        $added++
    } catch {
        Write-Output "ERROR writing $fileName : $_"
    }
}

Write-Output ""
Write-Output "========== SUMMARY =========="
Write-Output "Added NLP_Psy tag: $added"
Write-Output "Already had tag: $alreadyHad"
Write-Output "Not found: $notFound"
Write-Output "Skipped: $skipped"
Write-Output "Total processed: $($added + $alreadyHad)"
Write-Output "==========================="
