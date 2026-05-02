# fix_lsa_frontmatter.ps1
# Strips incorrect frontmatter and rewrites with correct UTF-8 diacriticals

# Characters
$a_acute = [char]0x00E1   # á
$i_acute = [char]0x00ED   # í
$d_dot   = [char]0x1E0D   # ḍ (for Riḍván)

# Bahá'í spelled correctly
$bahai = "Bah${a_acute}'${i_acute}"
$moc   = "[[MOC - ${bahai} Faith]]"

# Riḍván — simplified to "Ridvan" in description to avoid YAML encoding issues
$ridvan = "Ridvan"

# Administrative year ranges per BE number
$yearMap = @{
    161 = "Ridvan 2004 - Ridvan 2005"
    162 = "Ridvan 2005 - Ridvan 2006"
    163 = "Ridvan 2006 - Ridvan 2007"
    164 = "Ridvan 2007 - Ridvan 2008"
    165 = "Ridvan 2008 - Ridvan 2009"
    166 = "Ridvan 2009 - Ridvan 2010"
    167 = "Ridvan 2010 - Ridvan 2011"
    168 = "Ridvan 2011 - Ridvan 2012"
    169 = "Ridvan 2012 - Ridvan 2013"
    170 = "Ridvan 2013 - Ridvan 2014"
    171 = "Ridvan 2014 - Ridvan 2015"
    172 = "Ridvan 2015 - Ridvan 2016"
    173 = "Ridvan 2016 - Ridvan 2017"
    174 = "Ridvan 2017 - Ridvan 2018"
    175 = "Ridvan 2018 - Ridvan 2019"
    176 = "Ridvan 2019 - Ridvan 2020"
    177 = "Ridvan 2020 - Ridvan 2021"
    178 = "Ridvan 2021 - Ridvan 2022"
    179 = "Ridvan 2022 - Ridvan 2023"
    180 = "Ridvan 2023 - Ridvan 2024"
    181 = "Ridvan 2024 - Ridvan 2025"
}

$dir = 'D:\Obsidian\Main\LSA\Year in Review'
$count = 0

foreach ($beNum in 161..181) {
    $filePath = Join-Path $dir "BE${beNum}.md"
    if (-not (Test-Path $filePath)) {
        Write-Host "MISSING: BE${beNum}.md"
        continue
    }

    # Read full content with UTF-8
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

    # Strip existing frontmatter if present (lines between first --- and second ---)
    if ($content.TrimStart().StartsWith('---')) {
        # Find the closing ---
        $firstDash = $content.IndexOf('---')
        $afterFirst = $firstDash + 3
        $secondDash = $content.IndexOf('---', $afterFirst)
        if ($secondDash -ge 0) {
            # Remove frontmatter block (up to and including second ---)
            $afterFrontmatter = $content.Substring($secondDash + 3).TrimStart("`r", "`n")
            $content = $afterFrontmatter
        }
    }

    $yearRange = $yearMap[$beNum]
    $title = "LSA of the ${bahai}s of Georgetown, TX `u{2014} Year in Review BE ${beNum}"
    $desc  = "Annual Year in Review for the Local Spiritual Assembly of the ${bahai}s of Georgetown, TX `u{2014} administrative year ${yearRange}."

    # Build frontmatter lines using array for clean UTF-8
    $fm = @(
        "---",
        "title: `"${title}`"",
        "created: 2026-04-13",
        "description: `"${desc}`"",
        "tags:",
        "  - ${bahai}",
        "  - Georgetown",
        "  - LSA",
        "  - Administrative",
        "  - GeorgetownLSA",
        "  - YearInReview",
        "  - BE${beNum}",
        "nav: `"${moc}`"",
        "---",
        ""
    )

    $newContent = ($fm -join "`n") + $content

    # Write back with UTF-8 (no BOM)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($filePath, $newContent, $utf8NoBom)
    Write-Host "FIXED: BE${beNum}.md"
    $count++
}

Write-Host ""
Write-Host "Total fixed: $count files"
