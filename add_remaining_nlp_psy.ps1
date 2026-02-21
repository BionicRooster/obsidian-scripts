# Add NLP_Psy tag to remaining files that are missing it

# List of files missing the tag
$missingFiles = @(
    'D:\Obsidian\Main\20 - Permanent Notes\Advanced Language Pa.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Cellular Change.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Change Personal History.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Childhood Developmental Stages.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Eliciting Beliefs.md',
    'D:\Obsidian\Main\04 - Indexes\Sciences\NLP\Meta Model Patterns.md',
    'D:\Obsidian\Main\04 - Indexes\Sciences\NLP\NLP Presupposition-1.md',
    'D:\Obsidian\Main\04 - Indexes\Sciences\NLP\NLP Training Week 7.md',
    'D:\Obsidian\Main\04 - Indexes\Sciences\NLP\NLP World Pt 2.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Prove the Theorem -1.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Prove the Theorem -2.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Prove the Theorem -3.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Prove the Theorem -4.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Prove the Theorem P3.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Prove the Theorem Pt.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Quick Profiling.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Rapport with Self.md',
    'D:\Obsidian\Main\20 - Permanent Notes\SCORE in Business.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Six Step Reframe w-1.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Six Step Reframe wit.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Specific Ecology Che.md',
    'D:\Obsidian\Main\20 - Permanent Notes\TRANSCRIPT OF A COMP.md',
    'D:\Obsidian\Main\20 - Permanent Notes\TransDerivational Se.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Well Formed Outcomes.md',
    'D:\Obsidian\Main\20 - Permanent Notes\What''s Wired In.md',
    'D:\Obsidian\Main\20 - Permanent Notes\Wired Logical Levels.md'
)

# Initialize counter
$added = 0

Write-Output "Adding NLP_Psy tag to remaining files..."
Write-Output ""

foreach ($filePath in $missingFiles) {
    # Check if file exists
    if (-not (Test-Path $filePath)) {
        Write-Output "NOT FOUND: $filePath"
        continue
    }

    try {
        # Read file as lines
        $lines = @(Get-Content -Path $filePath -Encoding UTF8)

        # Rebuild content
        $newLines = @()
        $frontmatterExists = $false
        $hasNLPTag = $false
        $i = 0

        # Check if starts with ---
        if ($lines.Count -gt 0 -and $lines[0] -match '^\s*---\s*$') {
            $frontmatterExists = $true
            $newLines += '---'
            $i = 1

            # Find end of frontmatter
            while ($i -lt $lines.Count) {
                $line = $lines[$i]

                if ($line -match '^\s*---\s*$') {
                    # Add tag before closing ---
                    if (-not $hasNLPTag) {
                        $newLines += 'tags: [NLP_Psy]'
                        $hasNLPTag = $true
                    }
                    $newLines += '---'
                    $i++
                    break
                } else {
                    # Skip duplicate tags
                    if ($line -match 'tags:.*NLP' -or $line -match 'NLP_Psy') {
                        $hasNLPTag = $true
                        # Don't add this line
                    } else {
                        $newLines += $line
                    }
                }
                $i++
            }
        } else {
            # No frontmatter, create one
            $newLines += '---'
            $newLines += 'tags: [NLP_Psy]'
            $newLines += '---'
            $hasNLPTag = $true
            $i = 0
        }

        # Add remaining content
        while ($i -lt $lines.Count) {
            $newLines += $lines[$i]
            $i++
        }

        # Write back
        $content = $newLines -join "`n"
        Set-Content -Path $filePath -Value $content -Encoding UTF8

        Write-Output "ADDED: $(Split-Path -Leaf $filePath)"
        $added++
    } catch {
        Write-Output "ERROR: $filePath - $_"
    }
}

Write-Output ""
Write-Output "========== SUMMARY =========="
Write-Output "Added NLP_Psy tag to: $added files"
Write-Output "==========================="
