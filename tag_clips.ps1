# Script to add tags to clippings files
# Each entry: filename, array of tags (clippings always last if present)

$base = 'D:\Obsidian\Main\10 - Clippings'

# Define tags for each file
$tagMap = @{
    "'Anything that can be built can be taken down'.md" = @('conservation', 'environment', 'NativeAmerican', 'activism', 'river', 'clippings')
    "21 Rules That Men Have. Number 7 Is So True.md" = @('humor', 'funny', 'clippings')
    "A Brief History of Children Sent Through the Mail.md" = @('history', 'USPS', 'America', 'clippings')
    "A Living Story of 174 Years of Constructive Resilience.md" = @('BAHAI', 'persecution', 'Iran', 'history', 'clippings')
    "A Round History of Square Recorders.md" = @('recorder', 'MusicalInstruments', 'music', 'history', 'clippings')
    "Andy's Ocarina Recommendations.md" = @('MusicalInstruments', 'music', 'clippings')
    "Archaeologists Discover They Have Been Excavating Lost Assyrian City.md" = @('archaeology', 'Mesopotamia', 'history', 'clippings')
    "Archaeologists Found the Long-Buried Remains of a 2,500-Year-Old Roman Society.md" = @('archaeology', 'Rome', 'history', 'clippings')
    "Book Summary Request.md" = @('book', 'Psychology', 'cognition', 'clippings')
    "Chasing Quicksilver History in Beautiful Big Bend.md" = @('Big-Bend', 'history', 'Travel', 'geology', 'clippings')
    "Check the Integrity.md" = @('Linux', 'Software', 'Computers', 'clippings')
    "Checkout.md" = @('Software', 'SoftwareLicense', 'receipt', 'clippings')
    "Collect general trib.md" = @('LGL', 'FOL', 'fundraising', 'Forms', 'clippings')
    "Device Listing  My A.md" = @('TiVo', 'TV', 'Entertainment', 'clippings')
    "Did Neanderthals Die Out Because of the Paleo Diet.md" = @('archaeology', 'Paleontology', 'diet', 'science', 'clippings')
    "Differences in recorders.md" = @('recorder', 'MusicalInstruments', 'music', 'clippings')
    "Digi-Comp II First Edition Evil Mad Scientist.md" = @('DigicompII', 'retro-computer', 'maker', 'Computers', 'clippings')
    "firefox always show.md" = @('Firefox', 'web', 'tech', 'clippings')
    "Fruit Walls Urban Farming in the 1600s.md" = @('gardening', 'farming', 'history', 'solar', 'clippings')
    "Heavy Sleepers' Alarm Clock.md" = @('maker', 'electronics', 'Arduino', 'clippings')
    "How to Choose New Countertops, Cabinets, and Floors.md" = @('home', 'kitchen', 'construction', 'clippings')
    "How to find easement.md" = @('RealEstate', 'georgetown', 'law', 'clippings')
    "How to play all the.md" = @('recorder', 'MusicalInstruments', 'music', 'clippings')
    "If You're Tired of F.md" = @('Trailer', 'rv', 'Travel', 'clippings')
    "Intel's revolutionary 4004 Chip.md" = @('Computers', 'hardware', 'history', 'electronics', 'clippings')
    "LUCY is a magical drawing tool based on the classic camera lucida.md" = @('art', 'Tools', 'optics', 'clippings')
    "Mermaid Chart.md" = @('Software', 'Code', 'Graphics', 'clippings')
    "Obituary - John Henry White.md" = @('Genealogy', 'FamilyTree', 'death', 'clippings')
    "Pace Layers - Six layers of robust and adaptable civilizations.md" = @('Sketchplanations', 'culture', 'thinking', 'clippings')
    "Perplexity.md" = @('Perplexity', 'AI', 'Automation', 'Google', 'clippings')
    "Podium vs Lectern.md" = @('language', 'Education', 'clippings')
    "Rethinking Neanderthals.md" = @('archaeology', 'Paleontology', 'science', 'clippings')
    "Scientists Found the Temperature That Makes Cookies Turn Out Better.md" = @('baking', 'cooking', 'science', 'food', 'clippings')
    "Seeking A Life That Is Spiritual But Not Religious - Utne.md" = @('spirituality', 'religion', 'meditation', 'clippings')
    "Set Up a Fully Automated Media Center.md" = @('Homelab', 'Automation', 'Entertainment', 'Software', 'clippings')
    "Setting Early American Sites on Fire.md" = @('archaeology', 'NativeAmerican', 'science', 'clippings')
    "SMART Goals.md" = @('Sketchplanations', 'productivity', 'planning', 'clippings')
    "So You Want My Job Luthier (Guitar Maker).md" = @('MusicalInstruments', 'career', 'maker', 'craft', 'clippings')
    "StackSkills.md" = @('Education', 'Learning', 'tech', 'clippings')
    "Statement by the Republic of Slovenia.md" = @('BAHAI', 'international', 'peace', 'persecution', 'clippings')
    "Submarine finds anomalous structures in Antarctica.md" = @('science', 'geology', 'Discovery', 'clippings')
    "The Aliens Are Silent Because They Are Extinct.md" = @('Astronomy', 'space', 'science', 'biology', 'clippings')
    "The College Student Who Decoded the Data Hidden in Inca Knots.md" = @('archaeology', 'history', 'Data', 'anthropology', 'clippings')
    "The First Commons Country - Utne Magazine.md" = @('Economy', 'government', 'Sustainability', 'clippings')
    "The Instant Mongolian Home.md" = @('yurt', 'culture', 'homesteading', 'clippings')
    "The Post-American Internet 39C3, Hamburg, Dec 28.md" = @('internet', 'privacy', 'Censorship', 'tech', 'clippings')
    "The Singularity.md" = @('America', 'buildings', 'culture', 'clippings')
    "Trailer homesteading in the Mojave.md" = @('homesteading', 'Trailer', 'desert', 'sustainable-living', 'clippings')
    "Travel With Ubikey Secure Login.md" = @('security', 'Travel', 'hardware', 'clippings')
    "TV dialogue sound 3 simple tweaks.md" = @('TV', 'acoustics', 'lifehacks', 'clippings')
    "Under the Bed Nightlight.md" = @('maker', 'electronics', 'home', 'clippings')
    "Understanding Types of Servo Motors.md" = @('maker', 'electronics', 'Robotics', 'clippings')
    "Unearthing the World of Jesus.md" = @('archaeology', 'Jesus', 'BiblicalHistory', 'history', 'clippings')
    "Use the Mobile Passport App to Breeze Through Customs.md" = @('Travel', 'lifehacks', 'phone', 'clippings')
    "Wayback Machine.md" = @('BAHAI', 'Prayer', 'web', 'clippings')
    "What are small language models 1.md" = @('AI', 'tech', 'Software', 'clippings')
    "What Killed These Marine Reptiles.md" = @('Paleontology', 'fossils', 'science', 'clippings')
    "Yukagir mammoth.md" = @('Paleontology', 'fossils', 'archaeology', 'clippings')
    "Zapier Learn.md" = @('zapier', 'Automation', 'LGL', 'clippings')
    "A quote by Abdul'-Baha - Slave to your moods.md" = @('BAHAI', 'AbdulBaha', 'spirituality', 'clippings')
    "Writage License.md" = @('SoftwareLicense', 'MicrosoftWord', 'receipt', 'clippings')
    "Winxvideo AI receipt.md" = @('receipt', 'Software', 'video', 'clippings')
    "What's it like to live in a yurt in Northern Montana.md" = @('yurt', 'homesteading', 'sustainable-living', 'clippings')
    "Winegard Elite 7550.md" = @('TV', 'hardware', 'home')
    "Making the `$25k Odaiko Drum on a Budget.md" = @('music', 'MusicalInstruments', 'maker', 'craft', 'clippings')
}

# Files to skip (empty or not found)
$skip = @(
    "Dunning-Kruger effect - Wikipedia.md",  # essentially empty - only Related Notes links
    "All in One - System Rescue Toolkit Lite.md"  # will handle specially
)

# Special handling for files that couldn't be found by exact name - use glob
$specialFiles = @{
    "All in One*" = @('Computers', 'Software', 'Tools', 'repair', 'clippings')
    "Dunning*" = $null  # skip - empty
    "7,000*" = @('archaeology', 'Ancient', 'geology', 'science', 'clippings')
    "Secret Tunnel*" = @('archaeology', 'Ancient', 'history', 'clippings')
}

function Update-FileTags {
    param(
        [string]$FilePath,
        [string[]]$Tags
    )

    # Read file as bytes to preserve encoding
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    $content = [System.Text.Encoding]::UTF8.GetString($bytes)

    # Remove BOM if present
    if ($content.StartsWith([char]0xFEFF)) {
        $content = $content.Substring(1)
    }

    # Build tags YAML block
    $tagsBlock = "tags:`n"
    foreach ($t in $Tags) {
        $tagsBlock += "  - $t`n"
    }

    # Check if file has frontmatter
    if ($content.StartsWith("---")) {
        # Find end of frontmatter
        $endIdx = $content.IndexOf("`n---", 3)
        if ($endIdx -gt 0) {
            $frontmatter = $content.Substring(0, $endIdx)
            $rest = $content.Substring($endIdx)

            # Remove existing tags block from frontmatter
            # Match tags: followed by lines starting with "  - "
            $fmLines = $frontmatter -split "`n"
            $newFmLines = @()
            $inTags = $false
            $tagsInserted = $false

            foreach ($line in $fmLines) {
                if ($line -match '^\s*tags:\s*$' -or $line -match '^\s*tags:\s*$') {
                    $inTags = $true
                    # Insert our new tags block here
                    if (-not $tagsInserted) {
                        $newFmLines += $tagsBlock.TrimEnd("`n") -split "`n"
                        $tagsInserted = $true
                    }
                    continue
                }
                if ($inTags) {
                    if ($line -match '^\s+-\s') {
                        continue  # skip old tag entries
                    } else {
                        $inTags = $false
                    }
                }
                $newFmLines += $line
            }

            # If no tags key was found, add before end of frontmatter
            if (-not $tagsInserted) {
                $newFmLines += ($tagsBlock.TrimEnd("`n") -split "`n")
            }

            $newContent = ($newFmLines -join "`n") + $rest
        } else {
            # Malformed frontmatter, just prepend
            $newContent = "---`n$tagsBlock---`n$content"
        }
    } else {
        # No frontmatter at all - add one
        $newContent = "---`n$tagsBlock---`n$content"
    }

    # Write back as UTF-8 without BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($FilePath, $newContent, $utf8NoBom)
    Write-Host "TAGGED: $(Split-Path $FilePath -Leaf) -> $($Tags -join ', ')"
}

# Process regular files
foreach ($fname in $tagMap.Keys) {
    $path = Join-Path $base $fname
    $found = $null

    # Try to find the file
    if (Test-Path -LiteralPath $path -ErrorAction SilentlyContinue) {
        $found = $path
    } else {
        # Try glob with first 15 chars
        $prefix = $fname.Substring(0, [Math]::Min(15, $fname.Length))
        $matches = Get-ChildItem -Path "$base\$prefix*" -ErrorAction SilentlyContinue
        if ($matches) {
            $found = $matches[0].FullName
        }
    }

    if ($found -and (Test-Path $found)) {
        $tags = $tagMap[$fname]
        Update-FileTags -FilePath $found -Tags $tags
    } else {
        Write-Host "NOT FOUND: $fname"
    }
}

# Process special files (glob-based)
foreach ($pattern in $specialFiles.Keys) {
    $tags = $specialFiles[$pattern]
    if ($null -eq $tags) { continue }  # skip nulls

    $matches = Get-ChildItem -Path "$base\$pattern" -ErrorAction SilentlyContinue
    foreach ($m in $matches) {
        Update-FileTags -FilePath $m.FullName -Tags $tags
    }
}

Write-Host "`nDone!"
