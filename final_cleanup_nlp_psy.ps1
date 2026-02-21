# Final comprehensive cleanup for NLP_Psy tags
# This script will properly format YAML frontmatter and remove duplicates

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
$cleaned = 0
$verified = 0

Write-Output "Final cleanup of NLP_Psy tags..."
Write-Output ""

foreach ($fileName in $uniqueFiles) {
    # Search for file in vault
    $foundFiles = @()
    try {
        $foundFiles = Get-ChildItem -Path 'D:\Obsidian\Main' -File -Filter "$fileName*" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.md' }
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

    # Read file as lines to properly handle structure
    try {
        $lines = @(Get-Content -Path $filePath -Encoding UTF8)
    } catch {
        continue
    }

    # Rebuild file content
    $newLines = @()
    $inFrontmatter = $false
    $frontmatterDone = $false
    $hasFrontmatter = $false
    $hasNLPTag = $false
    $lineIndex = 0

    # First, check if file starts with ---
    if ($lines.Count -gt 0 -and $lines[0] -match '^\s*---\s*$') {
        $hasFrontmatter = $true
        $inFrontmatter = $true
        $newLines += '---'
        $lineIndex = 1

        # Process frontmatter lines
        while ($lineIndex -lt $lines.Count) {
            $line = $lines[$lineIndex]

            # End of frontmatter
            if ($line -match '^\s*---\s*$') {
                $newLines += '---'
                $frontmatterDone = $true
                $lineIndex++
                break
            }

            # Skip duplicate tag lines and empty ones in frontmatter
            if ($line -match 'tags:\s*\[NLP_Psy\]') {
                if (-not $hasNLPTag) {
                    $newLines += 'tags: [NLP_Psy]'
                    $hasNLPTag = $true
                }
            } elseif ($line -match 'tags:' -or $line -match '^\s*- NLP\s*$' -or $line -match '^\s*$') {
                # Skip these lines if we already have NLP_Psy
                if ($hasNLPTag -and ($line -match 'tags:' -or $line -match '^\s*- NLP')) {
                    # Skip duplicate tag definitions
                    continue
                } elseif ($line -match '^\s*$') {
                    # Keep empty lines in frontmatter
                    $newLines += $line
                } else {
                    $newLines += $line
                }
            } else {
                $newLines += $line
            }

            $lineIndex++
        }

        # If no NLP_Psy tag found in frontmatter, add it
        if (-not $hasNLPTag) {
            # Insert before closing ---
            $newLines[-1] = 'tags: [NLP_Psy]'
            $newLines += '---'
            $hasNLPTag = $true
        }
    } else {
        # No frontmatter, create one
        $newLines += '---'
        $newLines += 'tags: [NLP_Psy]'
        $newLines += '---'
        $hasNLPTag = $true
        $lineIndex = 0
    }

    # Add remaining body content, filtering out stray "tags:" lines
    while ($lineIndex -lt $lines.Count) {
        $line = $lines[$lineIndex]

        # Skip stray tag lines in body
        if ($line -match '^\s*tags:\s*\[NLP_Psy\]\s*$' -or
            ($line -match '^\s*---\s*$' -and $lineIndex -gt 0)) {
            # Skip
        } else {
            $newLines += $line
        }

        $lineIndex++
    }

    # Write back with UTF-8 encoding
    $newContent = $newLines -join "`n"

    # Check if content changed
    $originalContent = $lines -join "`n"
    if ($newContent -ne $originalContent) {
        Set-Content -Path $filePath -Value $newContent -Encoding UTF8
        Write-Output "CLEANED: $fileName"
        $cleaned++
    } else {
        if ($hasNLPTag) {
            $verified++
        }
    }
}

Write-Output ""
Write-Output "========== FINAL CLEANUP SUMMARY =========="
Write-Output "Cleaned up: $cleaned"
Write-Output "Already correct: $verified"
Write-Output "=========================================="
