# Classify "Identifying Necessary Transparency Moments In Agentic AI (Part 1)"
# Moves from 10 - Clippings to 01/Technology, updates tags/nav, links in MOC, adds to People Index

# --- Path constants ---
$vault       = 'D:\Obsidian\Main'
$srcPath     = "$vault\10 - Clippings\Identifying Necessary Transparency Moments In Agentic AI (Part 1).md"
$techDir     = "$vault\01\Technology"
$destPath    = "$techDir\Identifying Necessary Transparency Moments In Agentic AI (Part 1).md"
$mocPath     = "$vault\00 - Home Dashboard\MOC - Technology & Computers.md"
$indexPath   = "$vault\People Index.md"

# --- Encoding setup ---
$utf8        = [System.Text.Encoding]::UTF8

# --- Step 1: Ensure destination directory exists ---
if (-not (Test-Path $techDir)) {
    New-Item -ItemType Directory -Path $techDir | Out-Null
    Write-Host "Created directory: $techDir"
}

# --- Step 2: Read source file ---
$content = [System.IO.File]::ReadAllText($srcPath, $utf8)

# --- Step 3: Update tags in frontmatter ---
# Replace the existing tags block with an expanded set
# Current tags are quoted strings: "AI", "UI", "Human-Interfaces"
$oldTags = @'
tags:
  - "AI"
  - "UI"
  - "Human-Interfaces"
'@

$newTags = @'
tags:
  - "AI"
  - "UI"
  - "Human-Interfaces"
  - "AgenticAI"
  - "UXDesign"
  - "Transparency"
  - "DecisionNodes"
  - "TrustDesign"
  - "HumanAIInteraction"
  - "AIDesign"
'@

$content = $content.Replace($oldTags, $newTags)

# --- Step 4: Add nav property to frontmatter ---
# Insert nav after the opening --- line and before the first field
# Check if nav already exists
if ($content -notmatch 'nav:') {
    # Find the opening --- and insert nav after it
    $content = $content -replace '(?m)^(---\r?\n)', "`$1nav: ""[[MOC - Technology & Computers]]""`n"
}

# --- Step 5: Write updated content to DESTINATION ---
[System.IO.File]::WriteAllText($destPath, $content, $utf8)
Write-Host "Written to: $destPath"

# --- Step 6: Delete source file (move complete) ---
Remove-Item $srcPath
Write-Host "Removed source: $srcPath"

# --- Step 7: Add link to Technology MOC ---
# Insert after [[ICYMI_ Ice Cream Hackers...]] line (alphabetical position for "Id...")
$mocContent = [System.IO.File]::ReadAllText($mocPath, $utf8)

# The anchor line just before where "Identifying" should go
$anchor = '- [[ICYMI_ Ice Cream Hackers, When Amazon Echos Attack, And More]]'
$newLink = '- [[Identifying Necessary Transparency Moments In Agentic AI (Part 1)]]'

if ($mocContent -notmatch [regex]::Escape($newLink)) {
    $mocContent = $mocContent.Replace($anchor, "$anchor`n$newLink")
    [System.IO.File]::WriteAllText($mocPath, $mocContent, $utf8)
    Write-Host "Added link to Technology MOC"
} else {
    Write-Host "Link already exists in Technology MOC"
}

# --- Step 8: Add Victor Yocco to People Index ---
# Yocco comes after Yankelovich in the Y section
$indexContent = [System.IO.File]::ReadAllText($indexPath, $utf8)

# New entry for Yocco — insert between Yankelovich and ## Z
# Use [char]0x2014 for em dash to avoid encoding issues in PS1 files
$emDash     = [char]0x2014
$yoccoEntry = "### Yocco, Victor`n- [[Identifying Necessary Transparency Moments In Agentic AI (Part 1)]] $emDash author, UX researcher on agentic AI transparency"

if ($indexContent -notmatch 'Yocco') {
    # Anchor: the ## Z heading that immediately follows the Yankelovich entry
    $zAnchor  = "## Z"
    $replacement = "$yoccoEntry`n## Z"
    $indexContent = $indexContent.Replace($zAnchor, $replacement)
    [System.IO.File]::WriteAllText($indexPath, $indexContent, $utf8)
    Write-Host "Added Yocco, Victor to People Index"
} else {
    Write-Host "Yocco already in People Index"
}

Write-Host ""
Write-Host "=== DONE ==="
Write-Host "Moved: $srcPath -> $destPath"
Write-Host 'MOC: Technology & Computers updated'
Write-Host "People Index: Victor Yocco added"
