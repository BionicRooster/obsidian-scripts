# Classify recent notes - move from Clippings, add nav, link to MOCs
$ErrorActionPreference = 'Stop'

$clippingsDir = 'C:\Users\awt\Sync\Obsidian\10 - Clippings'
$techDir = 'C:\Users\awt\Sync\Obsidian\01\Technology'
$socialDir = 'C:\Users\awt\Sync\Obsidian\01\Social'
$bahaiDir = "C:\Users\awt\Sync\Obsidian\01\Baha'i"
$dashDir = 'C:\Users\awt\Sync\Obsidian\00 - Home Dashboard'
$vaultRoot = 'C:\Users\awt\Sync\Obsidian'

# Helper: add nav property to frontmatter of a file
function Add-NavProperty {
    param([string]$FilePath, [string]$NavValue)
    $content = Get-Content $FilePath -Encoding UTF8 -Raw
    # Only add if nav not already present
    if ($content -notmatch 'nav:') {
        # Insert nav after first ---
        $content = $content -replace '(^---\r?\n)', "`$1nav: `"$NavValue`"`n"
        Set-Content $FilePath -Value $content -Encoding UTF8 -NoNewline
        Write-Output "  Added nav to: $(Split-Path $FilePath -Leaf)"
    } else {
        Write-Output "  Nav already present in: $(Split-Path $FilePath -Leaf)"
    }
}

# Helper: add wikilink to a MOC section
function Add-LinkToMOC {
    param([string]$MOCPath, [string]$SectionHeader, [string]$LinkText)
    $lines = Get-Content $MOCPath -Encoding UTF8
    $inserted = $false
    $newLines = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $newLines += $lines[$i]
        # Find the line containing the section header (may be embedded at end of another item)
        if ($lines[$i] -like "*$SectionHeader*" -and -not $inserted) {
            $newLines += "- [[$LinkText]]"
            $inserted = $true
        }
    }
    if ($inserted) {
        Set-Content $MOCPath -Value $newLines -Encoding UTF8
        Write-Output "  Linked [[$LinkText]] to $SectionHeader in $(Split-Path $MOCPath -Leaf)"
    } else {
        Write-Output "  WARNING: Section '$SectionHeader' not found in $(Split-Path $MOCPath -Leaf)"
    }
}

# Get MOC paths
$techMOC = Join-Path $dashDir 'MOC - Technology & Computers.md'
$socialMOC = Join-Path $dashDir 'MOC - Social Issues.md'
$bahaiMOC = Get-ChildItem $dashDir | Where-Object { $_.Name -like 'MOC - Bah*Faith*' } | Select-Object -First 1

Write-Output "=== Processing: SSD Getting Slower and How to Fix It ==="
$ssdSrc = Join-Path $clippingsDir 'SSD Getting Slower and How to Fix It.md'
$ssdDst = Join-Path $techDir 'SSD Getting Slower and How to Fix It.md'
Add-NavProperty -FilePath $ssdSrc -NavValue '[[MOC - Technology & Computers]]'
Move-Item $ssdSrc $ssdDst -Force
Write-Output "  Moved to 01\Technology"
Add-LinkToMOC -MOCPath $techMOC -SectionHeader '## Troubleshooting & Guides' -LinkText 'SSD Getting Slower and How to Fix It'

Write-Output ""
Write-Output "=== Processing: No Duh! ==="
$noduhSrc = Join-Path $clippingsDir 'No Duh!.md'
$noduhDst = Join-Path $socialDir 'No Duh!.md'
Add-NavProperty -FilePath $noduhSrc -NavValue '[[MOC - Social Issues]]'
Move-Item $noduhSrc $noduhDst -Force
Write-Output "  Moved to 01\Social"
Add-LinkToMOC -MOCPath $socialMOC -SectionHeader '## Justice & Politics' -LinkText 'No Duh!'

Write-Output ""
Write-Output "=== Processing: We Are in a Digital Version of the Enclosures ==="
$encFiles = Get-ChildItem $clippingsDir | Where-Object { $_.Name -like '*Digital Version*Enclosures*' }
if ($encFiles) {
    $encSrc = $encFiles[0].FullName
    $encDst = Join-Path $techDir $encFiles[0].Name
    Add-NavProperty -FilePath $encSrc -NavValue '[[MOC - Technology & Computers]]'
    Move-Item $encSrc $encDst -Force
    Write-Output "  Moved to 01\Technology"
    Add-LinkToMOC -MOCPath $techMOC -SectionHeader '## AI & Machine Learning' -LinkText 'We Are in a Digital Version of the Enclosures - Like the Landowners, Big Tech Has Power Without Responsibility'
} else {
    Write-Output "  WARNING: Enclosures file not found"
}

Write-Output ""
Write-Output "=== Processing: All Religions Are One Baha'u'llah ==="
$bahaiFiles = Get-ChildItem $clippingsDir | Where-Object { $_.Name -like '*All Religions Are One*' }
if ($bahaiFiles) {
    $bahaiSrc = $bahaiFiles[0].FullName
    $bahaiDst = Join-Path $bahaiDir $bahaiFiles[0].Name
    Add-NavProperty -FilePath $bahaiSrc -NavValue "[[MOC - Bahá'í Faith]]"
    Move-Item $bahaiSrc $bahaiDst -Force
    Write-Output "  Moved to 01\Baha'i"
    if ($bahaiMOC) {
        Add-LinkToMOC -MOCPath $bahaiMOC.FullName -SectionHeader '## Core Teachings' -LinkText "All Religions Are One Baha'u'llah"
    } else {
        Write-Output "  WARNING: Baha'i MOC not found"
    }
} else {
    Write-Output "  WARNING: Baha'u'llah file not found"
}

Write-Output ""
Write-Output "=== Processing: DIGI-COMP ESR (vault root - no move) ==="
$digiFile = Join-Path $vaultRoot 'DIGI-COMP ESR and Evil Mad Scientist Items on eBay.md'
if (Test-Path $digiFile) {
    Add-NavProperty -FilePath $digiFile -NavValue '[[MOC - Technology & Computers]]'
    Add-LinkToMOC -MOCPath $techMOC -SectionHeader '## Maker Projects' -LinkText 'DIGI-COMP ESR and Evil Mad Scientist Items on eBay'
} else {
    Write-Output "  WARNING: DIGI-COMP file not found"
}

Write-Output ""
Write-Output "=== Done! ==="
