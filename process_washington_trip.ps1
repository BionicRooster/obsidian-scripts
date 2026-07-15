# process_washington_trip.ps1
# Move all Travel+Megaflood/Washington notes to 2024 Columbia River Trip project folder
# Adds 2024-WashingtonTrip tag, orders Clipping as penultimate, onenote-import as last

# Destination folder
$dest = "C:\Users\awt\Sync\Obsidian\02 - Working Projects\2024 Columbia River Trip"

# Full list of files to process
$sourceFiles = @(
    # 10 - Clippings files (Travel + Washington/Megaflood tagged)
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Day 3 Driving.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Day 5 driving.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Kalama Gap.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Mocks Crest to Overlook Park   (Portland).md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Reed Island  & Steigerwald Wildlife Refuge.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Pillars of Hercules.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Cape Horn.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Lahar deposits plastered against ancient Columbia River deposits.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Mosier Erratic Overlook.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Coyote Wall.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Memaloose Island.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Pendant Flood Bar.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Columbia Gorge Interpretive Center.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\The Reach Museum.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Columbia Hills State Park.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\The Great Gravel Bar of Moses Coulee National Natural Landmark.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Grand Coulee Dam Visitor Center.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Let Your Feet, and Your Imagination Roam at Rowena Crest and Tom McCall Preserve 1.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Frenchman Coulee.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Multnomah Falls and Lodge.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Crown Point National Natural Landmark.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Columbia Gorge Discovery Center & Museum.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Let Your Feet, and Your Imagination Roam at Rowena Crest and Tom McCall Preserve.md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Grand Coulee National Natural Landmark (U.S. National Park Service).md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Sun Lakes-Dry Falls State Park (U.S. National Park Service).md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Glacial Lake Missoula National Natural Landmark (Camas Prairie Ripples) (U.S. National Park Service).md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\The Great Gravel Bar of Moses Coulee National Natural Landmark (U.S. National Park Service).md",
    "C:\Users\awt\Sync\Obsidian\10 - Clippings\Visit Grand Coulee Dam.md",
    # 01\Travel files (inline hashtags, from OneNote import)
    "C:\Users\awt\Sync\Obsidian\01\Travel\Lyle - Floods foreset beds.md",
    "C:\Users\awt\Sync\Obsidian\01\Travel\Wallula Junction rhythmites.md",
    "C:\Users\awt\Sync\Obsidian\01\Travel\Lake Lewis highest abandoned spillway.md",
    "C:\Users\awt\Sync\Obsidian\01\Travel\Grand Coulee Dam Visitor Center, X267+57, WA-155, Coulee Dam, WA 99116.md",
    "C:\Users\awt\Sync\Obsidian\01\Travel\Devil's Punchbowl.md",
    "C:\Users\awt\Sync\Obsidian\01\Travel\Granite Erratic Atop Steamboat Rock.md",
    "C:\Users\awt\Sync\Obsidian\01\Travel\Hogback Islands of Alkali Lake.md",
    "C:\Users\awt\Sync\Obsidian\01\Travel\The Great Blade.md"
)

# Tags to extract from inline body if not already in YAML
# These known tags come from the OneNote import hashtag format
$knownInlineTags = @("Washington", "Geology", "Travel", "Megaflood", "Driving")

# Ensure destination folder exists
if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest | Out-Null
    Write-Host "Created destination folder: $dest"
}

$results = @()  # Collect summary of operations

foreach ($filePath in $sourceFiles) {
    # Verify the source file exists
    if (-not (Test-Path $filePath)) {
        Write-Warning "File not found, skipping: $filePath"
        continue
    }

    $fileName = [System.IO.Path]::GetFileName($filePath)
    Write-Host "Processing: $fileName"

    # Read file with UTF-8 encoding (no BOM re-encoding)
    $rawContent = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

    # Detect YAML frontmatter block (starts with ---, ends with next ---)
    if ($rawContent -notmatch '(?s)^---\r?\n(.+?)\r?\n---\r?\n?') {
        Write-Warning "No YAML frontmatter found in: $fileName"
        continue
    }

    # Split content into YAML block and body
    $fullMatch = $Matches[0]         # Full frontmatter including delimiters
    $yamlBlock = $Matches[1]         # YAML content only (between --- lines)
    $bodyStart = $fullMatch.Length
    $body = $rawContent.Substring($bodyStart)  # Everything after closing ---

    # --- Extract existing tags from YAML ---
    $existingTags = [System.Collections.Generic.List[string]]::new()

    # Match the tags: block (handles both quoted and unquoted formats)
    if ($yamlBlock -match '(?s)tags:\r?\n((?:[ \t]+-[ \t]+.+\r?\n?)+)') {
        $tagSection = $Matches[1]
        # Parse each tag line: "  - Tag" or "  - "Tag""
        $tagLines = $tagSection -split '\r?\n' | Where-Object { $_ -match '^\s+-\s+' }
        foreach ($line in $tagLines) {
            if ($line -match '^\s+-\s+["\x27]?(.+?)["\x27]?\s*$') {
                $tagValue = $Matches[1].Trim().Trim('"').Trim("'")
                if ($tagValue -ne '') {
                    $existingTags.Add($tagValue)
                }
            }
        }
    }

    # --- Extract inline hashtag-based tags from body ---
    # Pattern 1: #TagName (standard hashtag format in body)
    $inlineMatches = [regex]::Matches($body, '#([A-Za-z][A-Za-z0-9_-]+)')
    foreach ($m in $inlineMatches) {
        $t = $m.Groups[1].Value
        # Only add known travel-related tags that aren't already in YAML
        if ($knownInlineTags -contains $t -and -not $existingTags.Contains($t)) {
            $existingTags.Add($t)
        }
    }

    # Pattern 2: "Tag1, Tag2, Tag3" comma-separated unlinked tags in body
    # (seen in Pendant Flood Bar: "Washington, Geology, Travel, Megaflood")
    $commaTagMatches = [regex]::Matches($body, '\b(Washington|Geology|Travel|Megaflood|Driving)\b')
    foreach ($m in $commaTagMatches) {
        $t = $m.Groups[1].Value
        if (-not $existingTags.Contains($t)) {
            $existingTags.Add($t)
        }
    }

    # --- Build the new ordered tag list ---
    # 1. Track whether onenote-import was present
    $hasOnenoteImport = $existingTags.Contains("onenote-import")

    # 2. Remove tags that will be repositioned or are new
    $specialTags = @("onenote-import", "Clipping", "2024-WashingtonTrip")
    $baseTags = $existingTags | Where-Object { $specialTags -notcontains $_ }

    # 3. Build final ordered list:
    #    [base tags] + 2024-WashingtonTrip + Clipping + [onenote-import if existed]
    $finalTags = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $baseTags) { $finalTags.Add($t) }
    $finalTags.Add("2024-WashingtonTrip")   # Add new project tag
    $finalTags.Add("Clipping")              # Penultimate
    if ($hasOnenoteImport) {
        $finalTags.Add("onenote-import")    # Last (only if originally present)
    }

    # --- Build new YAML tags block string ---
    $newTagsLines = "tags:`n"
    foreach ($t in $finalTags) {
        $newTagsLines += "  - $t`n"
    }
    # Remove trailing newline to avoid double-spacing
    $newTagsLines = $newTagsLines.TrimEnd("`n")

    # --- Replace the tags section in the YAML block ---
    # Handle case where tags: block exists
    if ($yamlBlock -match '(?s)(tags:\r?\n(?:[ \t]+-[ \t]+.+\r?\n?)+)') {
        $oldTagsBlock = $Matches[1]
        $newYamlBlock = $yamlBlock.Replace($oldTagsBlock, $newTagsLines + "`n")
    }
    # Handle case where tags: key exists but with inline value (tags: [a, b])
    elseif ($yamlBlock -match 'tags:\s*\[.+\]') {
        $newYamlBlock = $yamlBlock -replace 'tags:\s*\[.+\]', $newTagsLines
    }
    # Handle case where tags: block is missing entirely — add it
    else {
        $newYamlBlock = $yamlBlock + "`n" + $newTagsLines
    }

    # --- Reconstruct the full file content with updated YAML ---
    $newContent = "---`n" + $newYamlBlock + "`n---`n" + $body

    # --- Write updated content to destination folder ---
    $destPath = Join-Path $dest $fileName

    # Warn if file already exists at destination (e.g., duplicate name)
    if (Test-Path $destPath) {
        Write-Warning "File already exists at destination, overwriting: $fileName"
    }

    # Write with UTF-8 (no BOM) to preserve Obsidian encoding
    [System.IO.File]::WriteAllText($destPath, $newContent, (New-Object System.Text.UTF8Encoding $false))

    # Delete source file after successful write
    Remove-Item -Path $filePath -Force

    $results += [PSCustomObject]@{
        File        = $fileName
        Source      = $filePath -replace [regex]::Escape("C:\Users\awt\Sync\Obsidian\"), ""
        Tags        = ($finalTags -join ", ")
    }

    Write-Host "  -> Moved to $dest" -ForegroundColor Green
}

# --- Summary output ---
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Processed $($results.Count) files" -ForegroundColor Cyan
$results | Format-Table -AutoSize
