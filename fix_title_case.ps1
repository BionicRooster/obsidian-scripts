# fix_title_case.ps1 - Batch rename Obsidian vault files to proper title case
# and update all wikilinks across the vault to match
#
# Usage:
#   .\fix_title_case.ps1 -DryRun          # Preview changes without renaming
#   .\fix_title_case.ps1                   # Apply renames and update links
#   .\fix_title_case.ps1 -Limit 50        # Only process first 50 files
#   .\fix_title_case.ps1 -Category "allcaps"  # Only fix ALL CAPS words
#   .\fix_title_case.ps1 -Category "lowercase" # Only fix lowercase major words

param(
    [switch]$DryRun,           # Preview mode - don't rename
    [int]$Limit = 0,          # Limit number of files to process (0 = all)
    [string]$Category = "all" # "all", "allcaps", "lowercase", "firstword"
)

# --- Configuration ---

# Minor words that stay lowercase unless they're the first word
# Includes English minor words and common foreign particles
$minorWords = @('a','an','the','and','but','or','for','nor','at','by','in','of','on','to','with','from',
    'vs','vs.','is','it','as',
    'da','el','la','de','del','di','du','le','les','von','van','der','den','ka')  # Foreign particles

# Directories to exclude from scanning
$excludeDirs = @('.obsidian','.smart-env','00 - Images','00 - Journal','Templates','.resources')

# Known acronyms - these ALL CAPS words are correct and should NOT be changed
$acronyms = @(
    # Standard acronyms
    'MOC','LSA','UHJ','NLP','TX','CIT','GCCMA','WT','FEIN','AI','CNN','NFL','PDF','URL','PKM','FOL',
    'DIY','DNS','VPN','HTTP','HTTPS','API','CSS','HTML','JS','SQL','JSON','XML','YAML','USB','GPU',
    'CPU','RAM','SSD','HDD','LED','LCD','OLED','ADHD','OCD','PTSD','IQ','EQ','BMI','DNA','RNA',
    'FDA','CDC','WHO','UN','EU','UK','US','USA','NYC','LA','DC','ATX','DFW','HVAC','IRS','SSN',
    'LLC','INC','CEO','CFO','CTO','COO','VP','HR','IT','QA','PM','PR','FAQ','TL','DR','TLDR',
    'ETA','FYI','ASAP','RSA','MVP','POC','KPI','ROI','SaaS','PaaS','SEO','SEM','CRM','ERP',
    'PhD','MD','JD','MBA','BA','BS','MA','MS','LLM','II','III','IV','VI','VII','VIII','IX','XI','XII',
    'USDA','BBC','PBS','NPR','GOP','NATO','NASA','JPEG','PNG','GIF','MP3','MP4',
    # Vault-specific acronyms
    'FM','USAA','HCAS','CC','LGL','USPS','HP','BPH','MRI','HOA','GTX','USI','FC','NLT','NSA',
    'DEI','FEMA','UCLA','WWII','AA','PCB','IFTTT','LIT','PD','DVD','PC','NRPE','SCORM','SIMH',
    'KVM','VBA','KB','XP','XBMC','OS','RV','NM','TSA','LICSW','BBQ','HSH','MCP','MLK','ASCII',
    'DHCP','GISD','IBM','TRMNL','USMT','DIR','WFPB','XJ','TP','WCWBF','ROET','PT','REXCPM',
    'NRPE','ACDF','CMD','DOS','CSV','EPUB','DRM','FTP','DVR','CMON','NLT','PARA','BLDGBLOG',
    'SCORM','TSA','LICSW','MCP','EM','WKRP',
    # Additional acronyms discovered during review
    'TV','DDM','DCF','ID','DHS','GI','ICYMI','PRC','GUI','SUV','SIP','CO2','QRS','NYT','FW',
    'HOWTO','NEED','LG','ORDER','AND','SMART','SCORE','HOW','WEBER','NM','NRPE','RC',
    'MAKE','FUN','HERE','ESRD','YO','SMS','MMS'
)

# Plural/variant forms of acronyms (e.g., SUVs, URLs, SIPs) - strip trailing 's' for matching
$acronymVariants = @('SUVs','SIPs','URLs')

# Files/patterns to skip entirely - intentional lowercase brand names or special names
$skipPatterns = @(
    '^iTunes',         # Brand name starts lowercase
    '^xkcd',           # Brand name
    '^eMail',          # Intentional camelCase
    '^eMClient',       # Brand name
    '^iRex',           # Brand name
    '^firefox',        # Brand name
    '^dupeGuru',       # Brand name
    '^glasswire',      # Brand name
    '^minibin',        # Brand name/tool name
    '^piwheels',       # Brand name
    '^calibre',        # Brand name
    '^meta-iPod',      # Compound brand name
    '^mind\.Depositor',# Brand name
    '^lgldatadictionary$', # Technical name
    '^README$',        # Convention
    '^medical$',       # Single word, intentional
    '^justice$',       # Single word, intentional
    '^micrometeorites$', # Single word, intentional
    '^regex',          # Technical term
    '^chronic',        # Truncated medical term
    '^bronchopulmonary', # Truncated medical term
    '^industrial workers', # Truncated
    '^my knee$',       # Personal note
    '^how do i suspend', # Truncated
    '^shore excursion', # Truncated
    '^linux -',        # Technical context
    '^windows -',      # Technical context
    '^quinoa and toasted p', # Truncated recipe
    '^eggplant and tomato$', # Truncated recipe
    # Specific filenames that should not be changed
    '^ORDER BY',       # SQL syntax
    '^Using AND and OR', # SQL syntax
    '^MD-MD-Keep',     # Intentional format
    '^37d03d',         # Hash/code identifier
    '^\[pidp8\].*VC8E', # Product code in brackets
    '^\[pidp8\].*pde$', # File extension reference
    '^Folder Structure P\.A', # Intentional abbreviation
    '^Vera Irene Talbot -I', # Truncated with dash-I
    '^Easy, Healthy.*Da y$', # Broken/truncated filename
    '^Javanese.*Aya m\)$', # Broken/truncated filename
    '^Cool Tools - 15 x', # Dimension format
    '^Vegan Carrot Halwa', # Foreign title words handled differently
    '^Ras el Hanout',  # Foreign title with "el"
    # Q&A and D&R patterns - the & causes issues
    '^Q&A ',           # Q&A is a standard abbreviation
    '^D&R '            # D&R is initials
)

# Words that are brand names with mixed case - never change these
$mixedCaseBrands = @(
    'iPhone','iPad','iPod','iMac','iOS','iTunes','iCloud',  # Apple products
    'eBook','eBay','eMail','eMClient',                       # e-prefixed brands
    'YouTube','LinkedIn','GitHub','WordPress','JavaScript',   # Tech brands
    'PowerShell','FileZilla','LiveCode','FiberFirst',         # Software
    'DiddyBorg','BlueTooth','BluRay','ChatGPT',              # Tech terms
    'VMware','NSClient','NSClient++',                        # Enterprise software
    'IGoogle','iGoogle','XSplit','VCam',                     # More brands
    'CPUville','MAGAbert',                                   # Compound names
    'PiDP8','PiDP_8','SimH','ImageFiles',                    # Retro computing
    'WD-40','MS-DOS','RC2014','RC-3',                        # Hyphenated products
    'microSD','MicroSD',                                     # Storage
    'waynetalbot@gmail.com',                                 # Email address
    'LG---','CO2','OS8','FW_','Fw_','Re_',                    # Misc - FW_ is email forward prefix
    'feedly','dpkg','pidp8','buildroot',                     # Lowercase software names
    'RVer','RVers',                                          # Derived from acronym
    'cat5','ebay',                                           # Lowercase tech terms
    'iCC','NYT',                                             # Mixed acronyms
    'vbscript',                                              # Programming language
    'sms'                                                    # Should be SMS but original is lowercase
)

# ALL CAPS words that should be converted to regular Title Case (not acronyms)
$capsToConvert = @{
    'CORONA'    = 'Corona'
    'LUCY'      = 'Lucy'
    'DAD'       = 'Dad'
    'OZ'        = 'Oz'
    'BEAST'     = 'Beast'
    'READ'      = 'Read'
    'ACCESS'    = 'Access'
    'HEALTHIER' = 'Healthier'
    'EFFICIENT' = 'Efficient'
    'FORWARD'   = 'Forward'
    'REVIEW'    = 'Review'
}

# --- Functions ---

# Convert a filename to proper title case
function ConvertTo-TitleCase {
    param([string]$Name)

    # Split on spaces while preserving the delimiters structure
    $words = $Name -split '(\s+)'
    $result = @()
    $wordIndex = 0  # Track actual word index (not counting spaces)

    for ($i = 0; $i -lt $words.Count; $i++) {
        $w = $words[$i]

        # Preserve whitespace as-is
        if ($w -match '^\s+$') {
            $result += $w
            continue
        }

        # Skip empty strings
        if ($w -eq '') { continue }

        # Check if it's a number-starting word - leave as-is
        if ($w -match '^\d') {
            $result += $w
            $wordIndex++
            continue
        }

        # Check if it's a known mixed-case brand/product name - keep EXACT case
        if ($mixedCaseBrands -ccontains $w) {
            $result += $w
            $wordIndex++
            continue
        }

        # Check if word contains @ (email address) - keep as-is
        if ($w -match '@') {
            $result += $w
            $wordIndex++
            continue
        }

        # Strip leading and trailing punctuation for acronym matching
        $leading = ''
        $trailing = ''
        if ($w -match '^([\(\[\'']+)') {
            $leading = $Matches[1]
        }
        if ($w -match '([,;:!?\.\)\]\''_]+)$') {
            $trailing = $Matches[1]
        }
        $stripped = $w
        if ($leading) { $stripped = $stripped.Substring($leading.Length) }
        if ($trailing -and $stripped.Length -gt $trailing.Length) {
            $stripped = $stripped.Substring(0, $stripped.Length - $trailing.Length)
        } elseif ($trailing -and $stripped.Length -le $trailing.Length) {
            # Word is entirely punctuation - keep as-is
            $result += $w
            $wordIndex++
            continue
        }

        # Check if it's a known acronym variant (e.g., SUVs, URLs)
        if ($acronymVariants -ccontains $stripped) {
            $result += $w
            $wordIndex++
            continue
        }

        # Check if it's a known acronym (exact ALL CAPS match)
        if ($acronyms -contains $stripped.ToUpper() -and $stripped -ceq $stripped.ToUpper()) {
            $result += $w
            $wordIndex++
            continue
        }

        # Check for dotted abbreviations like U.S., Q.E.D., etc.
        if ($stripped -cmatch '^([A-Z]\.)+[A-Z]?\.?$') {
            $result += $w
            $wordIndex++
            continue
        }

        # Check if word has internal mixed case (like iPhone, eBay) - preserve it
        # Pattern: has at least one lowercase followed by uppercase somewhere
        if ($w -cmatch '[a-z][A-Z]' -or $w -cmatch '^[a-z]+[A-Z]') {
            $result += $w
            $wordIndex++
            continue
        }

        # Check capsToConvert for ALL CAPS words that need specific conversion
        if ($stripped -ceq $stripped.ToUpper() -and $stripped.Length -gt 1 -and $capsToConvert.ContainsKey($stripped)) {
            $replacement = $capsToConvert[$stripped]
            $result += $leading + $replacement + $trailing
            $wordIndex++
            continue
        }

        # Check if it's ALL CAPS and not a known acronym - convert to Title Case
        if ($stripped -ceq $stripped.ToUpper() -and $stripped.Length -gt 1 -and $stripped -cmatch '[A-Z]') {
            $converted = $stripped.Substring(0,1).ToUpper() + $stripped.Substring(1).ToLower()
            $result += $leading + $converted + $trailing
            $wordIndex++
            continue
        }

        # For the first word, always capitalize
        if ($wordIndex -eq 0) {
            if ($w.Length -gt 0 -and $w.Substring(0,1) -cmatch '[a-z]') {
                $result += $w.Substring(0,1).ToUpper() + $w.Substring(1)
            } else {
                $result += $w
            }
            $wordIndex++
            continue
        }

        # Check if it's a minor word - leave as-is (preserve current case)
        $lower = $w.ToLower()
        if ($minorWords -contains $lower) {
            $result += $w
            $wordIndex++
            continue
        }

        # Major word - capitalize first letter if lowercase
        if ($w.Length -gt 0 -and $w.Substring(0,1) -cmatch '[a-z]') {
            $result += $w.Substring(0,1).ToUpper() + $w.Substring(1)
        } else {
            $result += $w
        }
        $wordIndex++
    }

    return ($result -join '')
}

# --- Main Logic ---

$vaultPath = 'D:\Obsidian\Main'

Write-Host "Scanning vault for title case issues..." -ForegroundColor Cyan

# Collect all files needing fixes
$filesToFix = @()

Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse |
  Where-Object {
    $skip = $false
    foreach ($d in $excludeDirs) {
      if ($_.FullName -match [regex]::Escape($d)) { $skip = $true; break }
    }
    -not $skip
  } |
  ForEach-Object {
    $file = $_
    $name = $file.BaseName

    # Check skip patterns
    $shouldSkip = $false
    foreach ($pattern in $skipPatterns) {
        if ($name -match $pattern) {
            $shouldSkip = $true
            break
        }
    }
    if ($shouldSkip) { return }

    # Simply compute the title case version and compare
    $newBaseName = ConvertTo-TitleCase $name

    # Only include if the name actually changed
    if ($newBaseName -cne $name) {
        $filesToFix += [PSCustomObject]@{
            OldName     = $name
            NewName     = $newBaseName
            FullPath    = $file.FullName
            Directory   = $file.DirectoryName
            Extension   = $file.Extension
        }
    }
  }

# Apply limit if specified
if ($Limit -gt 0 -and $filesToFix.Count -gt $Limit) {
    $filesToFix = $filesToFix | Select-Object -First $Limit
}

Write-Host "`nFound $($filesToFix.Count) files to rename" -ForegroundColor Yellow

if ($filesToFix.Count -eq 0) {
    Write-Host "No files to fix!" -ForegroundColor Green
    exit
}

# Display the rename plan
Write-Host "`n=== RENAME PLAN ===" -ForegroundColor Cyan
$filesToFix | ForEach-Object {
    Write-Host "  $($_.OldName)" -ForegroundColor Red -NoNewline
    Write-Host " -> " -NoNewline
    Write-Host "$($_.NewName)" -ForegroundColor Green
}

if ($DryRun) {
    Write-Host "`n[DRY RUN] No files were renamed." -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes." -ForegroundColor Yellow
    exit
}

# --- Apply renames and update links ---

Write-Host "`nPhase 1: Renaming files..." -ForegroundColor Cyan

# Build a lookup of old name -> new name for link updates
$renameMap = @{}
$renamedCount = 0
$errorCount = 0

foreach ($fix in $filesToFix) {
    $oldPath = $fix.FullPath
    $finalName = $fix.NewName + $fix.Extension

    # Use two-step rename to handle Windows case-insensitive filesystem
    # Step 1: rename to a temporary name
    # Step 2: rename from temporary to final name
    $tempName = $fix.NewName + '_TITLECASE_TEMP_' + $fix.Extension

    try {
        Rename-Item -LiteralPath $oldPath -NewName $tempName -ErrorAction Stop
        $tempPath = Join-Path $fix.Directory $tempName
        Rename-Item -LiteralPath $tempPath -NewName $finalName -ErrorAction Stop
        $renameMap[$fix.OldName] = $fix.NewName
        $renamedCount++
        Write-Host "  OK: $($fix.OldName) -> $($fix.NewName)" -ForegroundColor Green
    }
    catch {
        # If step 2 failed, try to restore the original name
        $tempPath = Join-Path $fix.Directory $tempName
        if (Test-Path $tempPath) {
            try { Rename-Item -LiteralPath $tempPath -NewName ($fix.OldName + $fix.Extension) -ErrorAction Stop } catch {}
        }
        Write-Host "  ERROR: $($fix.OldName) - $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`nRenamed $renamedCount files ($errorCount errors)" -ForegroundColor Cyan

# Phase 2: Update wikilinks across the vault
if ($renameMap.Count -gt 0) {
    Write-Host "`nPhase 2: Updating wikilinks across vault..." -ForegroundColor Cyan

    # Get all markdown files in the vault
    $allFiles = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse |
        Where-Object {
            $skip = $false
            foreach ($d in @('.obsidian','.smart-env')) {
                if ($_.FullName -match [regex]::Escape($d)) { $skip = $true; break }
            }
            -not $skip
        }

    $linkUpdates = 0
    $filesUpdated = 0

    foreach ($file in $allFiles) {
        # Read file content
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        $originalContent = $content

        # Replace each old name with new name in wikilinks and YAML
        foreach ($oldName in $renameMap.Keys) {
            $newName = $renameMap[$oldName]

            # Replace [[OldName]] with [[NewName]]
            $pattern1 = [regex]::Escape("[[" + $oldName + "]]")
            if ($content -match $pattern1) {
                $content = $content -replace $pattern1, ("[[" + $newName + "]]")
                $linkUpdates++
            }

            # Replace [[OldName|display]] with [[NewName|display]]
            $pattern2 = [regex]::Escape("[[" + $oldName + "|")
            if ($content -match $pattern2) {
                $content = $content -replace $pattern2, ("[[" + $newName + "|")
                $linkUpdates++
            }

            # Replace in YAML nav property: "[[OldName]]"
            # Already covered by the general replacement above
        }

        # Write back if changed
        if ($content -ne $originalContent) {
            [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
            $filesUpdated++
        }
    }

    Write-Host "Updated $linkUpdates links across $filesUpdated files" -ForegroundColor Green
}

Write-Host "`n=== COMPLETE ===" -ForegroundColor Cyan
Write-Host "Files renamed: $renamedCount"
Write-Host "Link updates: $linkUpdates"
Write-Host "Errors: $errorCount"
