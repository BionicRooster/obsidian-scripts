# Fix the Reed Island file that was skipped due to filename spacing
$dest = "D:\Obsidian\Main\02 - Working Projects\2024 Columbia River Trip"

# Find the file using wildcard
$found = Get-ChildItem "D:\Obsidian\Main\10 - Clippings\" | Where-Object { $_.Name -like "Reed Island*Steigerwald*" }

if (-not $found) {
    Write-Error "Reed Island file not found!"
    exit 1
}

$filePath = $found.FullName
$fileName = $found.Name
Write-Host "Found: $filePath"

$rawContent = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

if ($rawContent -notmatch '(?s)^---\r?\n(.+?)\r?\n---\r?\n?') {
    Write-Error "No YAML found"
    exit 1
}

$fullMatch = $Matches[0]
$yamlBlock = $Matches[1]
$body = $rawContent.Substring($fullMatch.Length)

# Extract YAML tags
$existingTags = [System.Collections.Generic.List[string]]::new()
if ($yamlBlock -match '(?s)tags:\r?\n((?:[ \t]+-[ \t]+.+\r?\n?)+)') {
    $tagSection = $Matches[1]
    $tagLines = $tagSection -split '\r?\n' | Where-Object { $_ -match '^\s+-\s+' }
    foreach ($line in $tagLines) {
        if ($line -match '^\s+-\s+["\x27]?(.+?)["\x27]?\s*$') {
            $tagValue = $Matches[1].Trim().Trim('"').Trim("'")
            if ($tagValue -ne '') { $existingTags.Add($tagValue) }
        }
    }
}

# Add inline tags from body
$knownInlineTags = @("Washington", "Geology", "Travel", "Megaflood", "Driving")
$inlineMatches = [regex]::Matches($body, '#([A-Za-z][A-Za-z0-9_-]+)')
foreach ($m in $inlineMatches) {
    $t = $m.Groups[1].Value
    if ($knownInlineTags -contains $t -and -not $existingTags.Contains($t)) {
        $existingTags.Add($t)
    }
}

$hasOnenoteImport = $existingTags.Contains("onenote-import")
$specialTags = @("onenote-import", "Clipping", "2024-WashingtonTrip")
$baseTags = $existingTags | Where-Object { $specialTags -notcontains $_ }

$finalTags = [System.Collections.Generic.List[string]]::new()
foreach ($t in $baseTags) { $finalTags.Add($t) }
$finalTags.Add("2024-WashingtonTrip")
$finalTags.Add("Clipping")
if ($hasOnenoteImport) { $finalTags.Add("onenote-import") }

$newTagsLines = "tags:`n"
foreach ($t in $finalTags) { $newTagsLines += "  - $t`n" }
$newTagsLines = $newTagsLines.TrimEnd("`n")

if ($yamlBlock -match '(?s)(tags:\r?\n(?:[ \t]+-[ \t]+.+\r?\n?)+)') {
    $oldTagsBlock = $Matches[1]
    $newYamlBlock = $yamlBlock.Replace($oldTagsBlock, $newTagsLines + "`n")
} else {
    $newYamlBlock = $yamlBlock + "`n" + $newTagsLines
}

$newContent = "---`n" + $newYamlBlock + "`n---`n" + $body

$destPath = Join-Path $dest $fileName
[System.IO.File]::WriteAllText($destPath, $newContent, (New-Object System.Text.UTF8Encoding $false))
Remove-Item -Path $filePath -Force

Write-Host "Done! Final tags: $($finalTags -join ', ')" -ForegroundColor Green
