# update_links.ps1
# Update all references to "04 - Indexes" to point to new locations in "01"

$vaultPath = "D:\Obsidian\Main"

# Build a mapping of old paths to new paths
# We'll search for patterns like [[04 - Indexes/...]] and update them
$pathMappings = @{
    # Computer Sciences folder content -> Technology
    "04 - Indexes/Computer Sciences" = "01/Technology"
    "04 - Indexes\Computer Sciences" = "01/Technology"

    # Direct file mappings
    "04 - Indexes/Linux" = "01/Technology/Linux"
    "04 - Indexes\Linux" = "01/Technology/Linux"
    "04 - Indexes/Windows" = "01/Technology/Windows"
    "04 - Indexes\Windows" = "01/Technology/Windows"

    # Finance
    "04 - Indexes/Finance" = "01/Finance"
    "04 - Indexes\Finance" = "01/Finance"

    # Genealogy -> Home
    "04 - Indexes/Genealogy" = "01/Home"
    "04 - Indexes\Genealogy" = "01/Home"

    # Home related
    "04 - Indexes/Home and Hearth" = "01/Home/Home and Hearth"
    "04 - Indexes\Home and Hearth" = "01/Home/Home and Hearth"
    "04 - Indexes/Movies" = "01/Home/Movies"
    "04 - Indexes\Movies" = "01/Home/Movies"
    "04 - Indexes/Star Trek" = "01/Home/Star Trek"
    "04 - Indexes\Star Trek" = "01/Home/Star Trek"

    # Travel
    "04 - Indexes/Japan" = "01/Travel/Japan"
    "04 - Indexes\Japan" = "01/Travel/Japan"
    "04 - Indexes/Travel" = "01/Travel/Travel"
    "04 - Indexes\Travel" = "01/Travel/Travel"

    # Library -> PKM
    "04 - Indexes/Library" = "01/PKM"
    "04 - Indexes\Library" = "01/PKM"
    "04 - Indexes/04 - Indexes" = "01/PKM/04 - Indexes"
    "04 - Indexes\04 - Indexes" = "01/PKM/04 - Indexes"

    # Health
    "04 - Indexes/medical" = "01/Health/medical"
    "04 - Indexes\medical" = "01/Health/medical"
    "04 - Indexes/Vegan" = "01/Health/Vegan"
    "04 - Indexes\Vegan" = "01/Health/Vegan"
    "04 - Indexes/WFPB Diet" = "01/Health"
    "04 - Indexes\WFPB Diet" = "01/Health"

    # Science
    "04 - Indexes/Micrometeorite" = "01/Science/Micrometeorite"
    "04 - Indexes\Micrometeorite" = "01/Science/Micrometeorite"
    "04 - Indexes/Nature" = "01/Science/Nature"
    "04 - Indexes\Nature" = "01/Science/Nature"
    "04 - Indexes/Sciences" = "01/Science"
    "04 - Indexes\Sciences" = "01/Science"

    # Music
    "04 - Indexes/Music" = "01/Music"
    "04 - Indexes\Music" = "01/Music"

    # Personal Development -> NLP_Psy
    "04 - Indexes/Personal Development" = "01/NLP_Psy/Personal Development"
    "04 - Indexes\Personal Development" = "01/NLP_Psy/Personal Development"

    # Religion - Bahá'í content
    "04 - Indexes/Religion/Bahá'í" = "01/Bahá'í"
    "04 - Indexes\Religion\Bahá'í" = "01/Bahá'í"

    # Religion - General
    "04 - Indexes/Religion" = "01/Religion"
    "04 - Indexes\Religion" = "01/Religion"

    # MicrosoftAccess -> Technology
    "04 - Indexes/MicrosoftAccess" = "01/Technology"
    "04 - Indexes\MicrosoftAccess" = "01/Technology"

    # Additional mappings for remaining references
    "04 - Indexes/Hardware Index" = "01/Technology/Hardware"
    "04 - Indexes/Microsoft Access Index" = "01/Technology/MicrosoftAccess"
    "04 - Indexes/Food/Food" = "01/Health"
    "04 - Indexes/Food" = "01/Health"
    "04 - Indexes/NLP PresuppositionsDiscussion 1" = "01/NLP_Psy/NLP"
    "04 - Indexes/NLP PresuppositionsDiscussion" = "01/NLP_Psy/NLP"
    "04 - Indexes/Programming Index" = "01/Technology"
    "04 - Indexes/When the Singularity Might Occur/Hardware" = "01/Technology/Hardware"
    "04 - Indexes/When the Singularity Might Occur" = "01/Technology"

    # Generic catch-all for just "04 - Indexes" folder reference
    "[[04 - Indexes]]" = "[[01]]"
}

# Get all markdown files
$allFiles = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue

$updatedCount = 0

foreach ($file in $allFiles) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        $originalContent = $content

        # Only process if file contains "04 - Indexes"
        if ($content -match '04 - Indexes') {
            # Apply each mapping
            foreach ($mapping in $pathMappings.GetEnumerator()) {
                $content = $content.Replace($mapping.Key, $mapping.Value)
            }

            # Clean up garbled references like "04 - Indexes (166748)" - these are corrupted
            # Replace them with empty string or a generic placeholder
            $content = $content -replace '04 - Indexes \(\d+\)\s*', ''

            # If content changed, write it back
            if ($content -ne $originalContent) {
                [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
                Write-Host "Updated: $($file.Name)" -ForegroundColor Green
                $updatedCount++
            }
        }
    }
    catch {
        # Skip files with path issues
        continue
    }
}

Write-Host ""
Write-Host "Total files updated: $updatedCount" -ForegroundColor Cyan
