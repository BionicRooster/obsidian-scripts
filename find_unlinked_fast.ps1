# Fast script to find unlinked connections in Obsidian vault
# Focuses on high-value note titles (People, MOCs, Permanent Notes, key topics)

# Parameters
$vaultPath = "D:\Obsidian\Main"  # Path to Obsidian vault
$outputFile = "C:\Users\awt\PowerShell\unlinked_connections.json"  # Output file for results

# Get all markdown files
$allFiles = Get-ChildItem -Path $vaultPath -Filter "*.md" -Recurse

# Build hashtable of all note basenames to paths
$allNotes = @{}  # Maps note basename to full path
foreach ($file in $allFiles) {
    $allNotes[$file.BaseName] = $file.FullName
}

# Define high-value titles to search for (manually curated list of likely link targets)
$highValueTitles = @(
    # People
    "'Abdu'l-Bahá",
    "Bahá'u'lláh",
    "The Bab",
    "Shoghi Effendi",
    "Wayne Talbot",
    "Diane Sandlin",
    # Bahá'í Topics
    "Bahá'í",
    "Pilgrimage",
    "Ridván",
    "Ayyam-i-Ha",
    # Key Concepts
    "NLP",
    "Genetic Genealogy",
    "Zettelkasten",
    "PARA Method",
    # Technologies
    "ChatGPT",
    "Obsidian",
    "Arduino",
    "Raspberry Pi",
    # Health Topics
    "Vegan",
    "WFPB Diet",
    # Other meaningful topics from the vault
    "Dunning–Kruger effect",
    "Identifiable Victim Effect",
    "Inattentional Blindness",
    "Buddhism",
    "Christianity",
    "Judaism",
    "Tibetan Buddhism",
    "Archaeology",
    "Micrometeorite",
    "Land Navigation Manual",
    "National Parks"
)

Write-Host "Searching for unlinked mentions of $($highValueTitles.Count) high-value titles..."

# Results collection
$results = @()  # Array to hold found connections

foreach ($title in $highValueTitles) {
    # Skip if this note doesn't exist
    if (-not $allNotes.ContainsKey($title)) {
        Write-Host "Note not found: $title"
        continue
    }

    Write-Host "Searching for: $title"

    # Escape for regex
    $escapedTitle = [regex]::Escape($title)

    # Search all files for this title
    foreach ($file in $allFiles) {
        # Skip self-reference
        if ($file.BaseName -eq $title) { continue }

        # Read content
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        # Check if title appears in content
        if ($content -match "\b$escapedTitle\b") {
            # Check if it's NOT already linked
            $isLinked = $content -match "\[\[$escapedTitle\]\]|\[\[$escapedTitle\||\|$escapedTitle\]\]"

            if (-not $isLinked) {
                # Get context
                $match = [regex]::Match($content, ".{0,40}\b$escapedTitle\b.{0,40}", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                $context = if ($match.Success) { ($match.Value -replace "`r`n|`n", " ").Trim() } else { "" }

                # Add to results
                $results += [PSCustomObject]@{
                    Source = $file.BaseName
                    Target = $title
                    SourcePath = $file.FullName
                    TargetPath = $allNotes[$title]
                    Context = $context
                }
            }
        }
    }
}

Write-Host "`nFound $($results.Count) potential connections"

# Save to JSON for easier processing
$results | ConvertTo-Json -Depth 3 | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Results saved to $outputFile"

# Display first 50 results
Write-Host "`n=== First 50 Unlinked Connections ===`n"
$results | Select-Object -First 50 | ForEach-Object {
    Write-Host "[$($_.Source)] mentions [$($_.Target)]"
    Write-Host "  Context: $($_.Context)"
    Write-Host ""
}
