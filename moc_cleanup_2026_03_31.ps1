# MOC Cleanup Script - 2026-03-31
# Fixes misplaced links in MOC files and moves misallocated files in 01/ subdirectories
# All file reads/writes use UTF-8 encoding (no BOM)
# Uses LiteralPath for special character safety

$enc = [System.Text.Encoding]::UTF8  # UTF-8 encoder used throughout
$log = @()  # Accumulates change log entries for final summary

# Helper function: read a file safely as UTF-8
function Read-Vault {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

# Helper function: write a file safely as UTF-8 (no BOM)
function Write-Vault {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding $false))
}

# Helper: log a change
function Log-Change {
    param([string]$Type, [string]$Item, [string]$From, [string]$To)
    $script:log += [PSCustomObject]@{
        Type = $Type
        Item = $Item
        From = $From
        To   = $To
    }
}

Write-Host "=== MOC Cleanup Script ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PART 1: MOC FILE FIXES
# ============================================================

$mocDir = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard"  # Folder containing all MOC files

# ---- 1. Bahá'í Faith MOC ----
# Issues found:
#   - [[MOC Subsection Index]] is a system/nav file, not content - remove
#   - [[Transactions Screen]] in Administrative Guidance - financial/admin tool, marginal but keep (it's LSA-related)
#   - Duplicate: [[Ascension of Bahá'u'lláh]] and [[Ascension of Bahá-u-lláh]] - keep canonical
#   - [[16 - Organizations]] in Bahá'í Institutions - folder link, remove
#   - [[Georgetown Local Spiritual Assembly]] vs [[Local Spiritual Assembly]] - keep both, they're different
#   - [[RaceAmity]] in Related Topics - fine, it's a tag index but acceptable as cross-ref
#   - [[Style Sheet – Wilmet]] in Books & Resources - seems like admin/editorial, keep in Bahá'í

$bahaiFaithMocPath = Join-Path $mocDir "MOC - Bahá'í Faith.md"

Write-Host "Processing: MOC - Bahá'í Faith.md" -ForegroundColor Yellow
$bahaiContent = Read-Vault $bahaiFaithMocPath

# Remove [[16 - Organizations]] — folder link, not content
if ($bahaiContent -match '\[\[16 - Organizations\]\]') {
    $bahaiContent = $bahaiContent -replace "- \[\[16 - Organizations\]\]\r?\n", ""
    Log-Change "MOC Remove" "[[16 - Organizations]]" "MOC - Bahá'í Faith > Bahá'í Institutions" "REMOVED (folder link)"
    Write-Host "  Removed [[16 - Organizations]] (folder link)" -ForegroundColor Red
}

# Remove duplicate [[Ascension of Bahá-u-lláh]] — keep [[Ascension of Bahá'u'lláh]] (canonical)
if ($bahaiContent -match '\[\[Ascension of Bah' + [char]0x00E1 + '-u-ll' + [char]0x00E1 + 'h\]\]') {
    $bahaiContent = $bahaiContent -replace "- \[\[Ascension of Bah\u00e1-u-ll\u00e1h\]\]\r?\n", ""
    Log-Change "MOC Remove" "[[Ascension of Bahá-u-lláh]]" "MOC - Bahá'í Faith > Social Issues & Unity" "REMOVED (duplicate of [[Ascension of Bahá'u'lláh]])"
    Write-Host "  Removed duplicate [[Ascension of Baha-u-llah]]" -ForegroundColor Red
}

Write-Vault $bahaiFaithMocPath $bahaiContent
Write-Host "  Saved MOC - Baha'i Faith.md" -ForegroundColor Green

# ---- 2. Technology & Computers MOC ----
# Issues:
#   - [[MOC Subsection Index]] — system file embedded in list, remove
#   - [[David Packard]] — technology biography, ok to keep under People
#   - The flat structure has embedded ## headings in list items (formatting artifact) - not fixing structure here
#   - All links are tech-related; no obvious misplacements in subject matter

$techMocPath = Join-Path $mocDir "MOC - Technology & Computers.md"
Write-Host "Processing: MOC - Technology & Computers.md" -ForegroundColor Yellow
$techContent = Read-Vault $techMocPath

# Remove [[MOC Subsection Index]] - system nav file, not content
if ($techContent -match '\[\[MOC Subsection Index\]\]') {
    $techContent = $techContent -replace "- \[\[MOC Subsection Index\]\]\r?\n", ""
    Log-Change "MOC Remove" "[[MOC Subsection Index]]" "MOC - Technology & Computers > Computer Sciences" "REMOVED (system file)"
    Write-Host "  Removed [[MOC Subsection Index]] (system file)" -ForegroundColor Red
}

Write-Vault $techMocPath $techContent
Write-Host "  Saved MOC - Technology & Computers.md" -ForegroundColor Green

# ---- 3. FOL MOC ----
# Issues:
#   - [[15 - People]] — folder link, not content note
#   - [[Bryan Burrough HCAS 2026-02]] listed TWICE (duplicate)
#   - [[GCCMA Meeting Pictures]] — GCCMA is social/community, not FOL

$folMocPath = Join-Path $mocDir "MOC - Friends of the Georgetown Public Library.md"
Write-Host "Processing: MOC - Friends of the Georgetown Public Library.md" -ForegroundColor Yellow
$folContent = Read-Vault $folMocPath

# Remove [[15 - People]] folder link
if ($folContent -match '\[\[15 - People\]\]') {
    $folContent = $folContent -replace "- \[\[15 - People\]\]\r?\n", ""
    Log-Change "MOC Remove" "[[15 - People]]" "MOC - FOL > Related" "REMOVED (folder link)"
    Write-Host "  Removed [[15 - People]] (folder link)" -ForegroundColor Red
}

# Fix duplicate [[Bryan Burrough HCAS 2026-02]] - keep first, remove second
$bbPattern = "- \[\[Bryan Burrough HCAS 2026-02\]\]"
$bbCount = ([regex]::Matches($folContent, [regex]::Escape("[[Bryan Burrough HCAS 2026-02]]"))).Count
if ($bbCount -gt 1) {
    # Replace content to keep only one occurrence
    # Find second occurrence by splitting
    $firstIdx = $folContent.IndexOf("- [[Bryan Burrough HCAS 2026-02]]")
    if ($firstIdx -ge 0) {
        $afterFirst = $folContent.Substring($firstIdx + "- [[Bryan Burrough HCAS 2026-02]]".Length)
        $secondIdx = $afterFirst.IndexOf("- [[Bryan Burrough HCAS 2026-02]]")
        if ($secondIdx -ge 0) {
            $absSecond = $firstIdx + "- [[Bryan Burrough HCAS 2026-02]]".Length + $secondIdx
            # Remove the duplicate line (include trailing newline)
            $lineEnd = $folContent.IndexOf("`n", $absSecond)
            if ($lineEnd -lt 0) { $lineEnd = $folContent.Length }
            $folContent = $folContent.Substring(0, $absSecond) + $folContent.Substring($lineEnd + 1)
            Log-Change "MOC Remove" "[[Bryan Burrough HCAS 2026-02]] (duplicate)" "MOC - FOL > Hill Country Authors Series" "REMOVED (duplicate)"
            Write-Host "  Removed duplicate [[Bryan Burrough HCAS 2026-02]]" -ForegroundColor Red
        }
    }
}

# Remove [[GCCMA Meeting Pictures]] - it belongs in Home/Social, not FOL
if ($folContent -match '\[\[GCCMA Meeting Pictures\]\]') {
    $folContent = $folContent -replace "- \[\[GCCMA Meeting Pictures\]\]\r?\n", ""
    Log-Change "MOC Remove" "[[GCCMA Meeting Pictures]]" "MOC - FOL > FOL Operations" "REMOVED (GCCMA is social/community, not FOL)"
    Write-Host "  Removed [[GCCMA Meeting Pictures]] (GCCMA != FOL)" -ForegroundColor Red
}

Write-Vault $folMocPath $folContent
Write-Host "  Saved MOC - Friends of the Georgetown Public Library.md" -ForegroundColor Green

# ---- 4. Health & Nutrition MOC ----
# Issues:
#   - [[The Dyslexie Font Makes Reading Easier for People with Dyslexia]] — NLP/Psychology, not Health
#   - [[IBM Research Thinks]] — technology, not health
#   - Duplicate entries: [[Diet Info for Cindy']] appears in both Medical & Health AND Health Articles
#   - Duplicate: [[Hibiclens Uses, Side Effects & Warnings]] and [[Hibiclens Uses, Side Effects]] — keep full title
#   - [[How to Use Google Maps to Find Fresher Air]] and [[How to Use Google Maps]] — duplicates
#   - [[How to Tell If Your]] appears twice in Health Articles

$healthMocPath = Join-Path $mocDir "MOC - Health & Nutrition.md"
Write-Host "Processing: MOC - Health & Nutrition.md" -ForegroundColor Yellow
$healthContent = Read-Vault $healthMocPath

# Remove [[The Dyslexie Font Makes Reading Easier for People with Dyslexia]] - belongs in NLP/Psychology
if ($healthContent -match '\[\[The Dyslexie Font Makes Reading Easier for People with Dyslexia\]\]') {
    $healthContent = $healthContent -replace "- \[\[The Dyslexie Font Makes Reading Easier for People with Dyslexia\]\]\r?\n", ""
    Log-Change "MOC Move" "[[The Dyslexie Font Makes Reading Easier for People with Dyslexia]]" "MOC - Health & Nutrition > Medical & Health" "MOC - NLP & Psychology > Cognitive Science"
    Write-Host "  Moved [[The Dyslexie Font...]] from Health to NLP" -ForegroundColor Magenta
}

# Remove [[IBM Research Thinks]] - technology, not health
if ($healthContent -match '\[\[IBM Research Thinks\]\]') {
    $healthContent = $healthContent -replace "- \[\[IBM Research Thinks\]\]\r?\n", ""
    Log-Change "MOC Move" "[[IBM Research Thinks]]" "MOC - Health & Nutrition > Medical & Health" "MOC - Technology & Computers"
    Write-Host "  Moved [[IBM Research Thinks]] from Health to Technology" -ForegroundColor Magenta
}

# Remove duplicate [[Diet Info for Cindy']] from Health Articles (keep in Medical & Health)
# Find second occurrence in Health Articles section
$dietCount = ([regex]::Matches($healthContent, [regex]::Escape("[[Diet Info for Cindy']]"))).Count
if ($dietCount -gt 1) {
    # Remove from Health Articles section (second occurrence)
    $firstIdx2 = $healthContent.IndexOf("- [[Diet Info for Cindy']]")
    if ($firstIdx2 -ge 0) {
        $afterFirst2 = $healthContent.Substring($firstIdx2 + "- [[Diet Info for Cindy']]".Length)
        $secondIdx2 = $afterFirst2.IndexOf("- [[Diet Info for Cindy']]")
        if ($secondIdx2 -ge 0) {
            $absSecond2 = $firstIdx2 + "- [[Diet Info for Cindy']]".Length + $secondIdx2
            $lineEnd2 = $healthContent.IndexOf("`n", $absSecond2)
            if ($lineEnd2 -lt 0) { $lineEnd2 = $healthContent.Length }
            $healthContent = $healthContent.Substring(0, $absSecond2) + $healthContent.Substring($lineEnd2 + 1)
            Log-Change "MOC Remove" "[[Diet Info for Cindy']] (duplicate)" "MOC - Health & Nutrition > Health Articles" "REMOVED (kept in Medical & Health)"
            Write-Host "  Removed duplicate [[Diet Info for Cindy']]" -ForegroundColor Red
        }
    }
}

# Remove duplicate [[How to Tell If Your]] - appears twice in Health Articles
$howTellCount = ([regex]::Matches($healthContent, [regex]::Escape("[[How to Tell If Your]]"))).Count
if ($howTellCount -gt 1) {
    $firstIdx3 = $healthContent.IndexOf("- [[How to Tell If Your]]")
    if ($firstIdx3 -ge 0) {
        $afterFirst3 = $healthContent.Substring($firstIdx3 + "- [[How to Tell If Your]]".Length)
        $secondIdx3 = $afterFirst3.IndexOf("- [[How to Tell If Your]]")
        if ($secondIdx3 -ge 0) {
            $absSecond3 = $firstIdx3 + "- [[How to Tell If Your]]".Length + $secondIdx3
            $lineEnd3 = $healthContent.IndexOf("`n", $absSecond3)
            if ($lineEnd3 -lt 0) { $lineEnd3 = $healthContent.Length }
            $healthContent = $healthContent.Substring(0, $absSecond3) + $healthContent.Substring($lineEnd3 + 1)
            Log-Change "MOC Remove" "[[How to Tell If Your]] (duplicate)" "MOC - Health & Nutrition > Health Articles" "REMOVED (duplicate)"
            Write-Host "  Removed duplicate [[How to Tell If Your]]" -ForegroundColor Red
        }
    }
}

# Remove duplicate [[How to Use Google Maps]] (shorter truncated version) - keep full title version
if ($healthContent -match '\[\[How to Use Google Maps\]\]') {
    $healthContent = $healthContent -replace "- \[\[How to Use Google Maps\]\]\r?\n", ""
    Log-Change "MOC Remove" "[[How to Use Google Maps]] (truncated duplicate)" "MOC - Health & Nutrition > Health Articles" "REMOVED (keep [[How to Use Google Maps to Find Fresher Air]])"
    Write-Host "  Removed truncated duplicate [[How to Use Google Maps]]" -ForegroundColor Red
}

# Remove duplicate [[Hibiclens Uses, Side Effects]] (truncated) - keep full title
if ($healthContent -match '\[\[Hibiclens Uses, Side Effects\]\]') {
    $healthContent = $healthContent -replace "- \[\[Hibiclens Uses, Side Effects\]\]\r?\n", ""
    Log-Change "MOC Remove" "[[Hibiclens Uses, Side Effects]] (truncated duplicate)" "MOC - Health & Nutrition > Health Articles" "REMOVED (keep [[Hibiclens Uses, Side Effects & Warnings]])"
    Write-Host "  Removed truncated duplicate [[Hibiclens Uses, Side Effects]]" -ForegroundColor Red
}

Write-Vault $healthMocPath $healthContent
Write-Host "  Saved MOC - Health & Nutrition.md" -ForegroundColor Green

# ---- 5. NLP & Psychology MOC ----
# Issues:
#   - [[HP Retiree Dave Packard]] — management article, fits Psychology/Behavior broadly (leadership), keep
#   - Everything else looks appropriate

Write-Host "Processing: MOC - NLP & Psychology.md - no changes needed" -ForegroundColor Gray

# ---- 6. PKM MOC ----
# Issues:
#   - [[04 - Indexes]] — folder link at bottom of file, remove
#   - [[Link Recommendations for 10 Additional Obsidian Notes Batch 2]] — AI output artifact, minor

$pkmMocPath = Join-Path $mocDir "MOC - Personal Knowledge Management.md"
Write-Host "Processing: MOC - Personal Knowledge Management.md" -ForegroundColor Yellow
$pkmContent = Read-Vault $pkmMocPath

# Remove [[04 - Indexes]] folder link (dangling at bottom after ---)
if ($pkmContent -match '\[\[04 - Indexes\]\]') {
    $pkmContent = $pkmContent -replace "- \[\[04 - Indexes\]\]\r?\n", ""
    # Also remove if it appears without bullet
    $pkmContent = $pkmContent -replace "\r?\n\[\[04 - Indexes\]\]\r?\n", "`n"
    Log-Change "MOC Remove" "[[04 - Indexes]]" "MOC - Personal Knowledge Management" "REMOVED (folder link)"
    Write-Host "  Removed [[04 - Indexes]] (folder link)" -ForegroundColor Red
}

Write-Vault $pkmMocPath $pkmContent
Write-Host "  Saved MOC - Personal Knowledge Management.md" -ForegroundColor Green

# ---- 7. Social Issues MOC ----
# Issues:
#   - [[Swipe]] — appears in Justice & Politics section but is ambiguous (tech app?)
#   - Everything else looks topically appropriate

Write-Host "Processing: MOC - Social Issues.md - reviewing [[Swipe]]..." -ForegroundColor Yellow
$socialMocPath = Join-Path $mocDir "MOC - Social Issues.md"
$socialContent = Read-Vault $socialMocPath

# Check if [[Swipe]] is a politics note or something else - given context (politics section), leave it

Write-Host "  No changes to MOC - Social Issues.md" -ForegroundColor Gray

# ---- 8. Add [[The Dyslexie Font]] to NLP MOC ----
$nlpMocPath = Join-Path $mocDir "MOC - NLP & Psychology.md"
Write-Host "Processing: Adding Dyslexie Font to MOC - NLP & Psychology.md" -ForegroundColor Yellow
$nlpContent = Read-Vault $nlpMocPath

# Add to Cognitive Science section
if ($nlpContent -notmatch '\[\[The Dyslexie Font') {
    $nlpContent = $nlpContent -replace "(## Cognitive Science\r?\n)((?:- \[\[.*?\]\].*?\r?\n)*)", `
        "`$1`$2- [[The Dyslexie Font Makes Reading Easier for People with Dyslexia]]`n"
    Log-Change "MOC Add" "[[The Dyslexie Font Makes Reading Easier for People with Dyslexia]]" "MOC - Health & Nutrition" "MOC - NLP & Psychology > Cognitive Science"
    Write-Host "  Added [[The Dyslexie Font...]] to NLP > Cognitive Science" -ForegroundColor Green
    Write-Vault $nlpMocPath $nlpContent
}

# ---- 9. Add [[IBM Research Thinks]] to Technology MOC ----
Write-Host "Processing: Adding IBM Research Thinks to MOC - Technology & Computers.md" -ForegroundColor Yellow
$techContent2 = Read-Vault $techMocPath

# Only add if not already there (it may already be there given the flat list)
if ($techContent2 -notmatch '\[\[IBM Research Thinks\]\]') {
    # Add near AI & Machine Learning section (it was there before under tech)
    # Actually the tech MOC is a huge flat list - add to Computer Sciences at top
    $techContent2 = $techContent2 -replace "(## Computer Sciences\r?\n)", "`$1- [[IBM Research Thinks]]`n"
    Log-Change "MOC Add" "[[IBM Research Thinks]]" "removed from Health" "MOC - Technology & Computers > Computer Sciences"
    Write-Vault $techMocPath $techContent2
    Write-Host "  Added [[IBM Research Thinks]] to Technology MOC" -ForegroundColor Green
} else {
    Write-Host "  [[IBM Research Thinks]] already in Technology MOC" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== PART 2: 01/ Subdirectory File Moves ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PART 2: MOVE MISALLOCATED FILES IN 01/ SUBDIRECTORIES
# ============================================================

# Helper: Move a file safely, handling smart apostrophes in names
function Move-VaultFile {
    param(
        [string]$SourcePath,     # Full path to source file
        [string]$DestDir,        # Destination directory
        [string]$Description     # Human-readable description for log
    )
    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-Host "  SKIP (not found): $SourcePath" -ForegroundColor Gray
        return
    }
    $fileName = Split-Path $SourcePath -Leaf
    $destPath = Join-Path $DestDir $fileName
    if (Test-Path -LiteralPath $destPath) {
        Write-Host "  SKIP (exists at dest): $fileName" -ForegroundColor DarkYellow
        return
    }
    try {
        Move-Item -LiteralPath $SourcePath -Destination $destPath -ErrorAction Stop
        Write-Host "  MOVED: $fileName" -ForegroundColor Magenta
        Write-Host "    -> $DestDir" -ForegroundColor DarkMagenta
        $script:log += [PSCustomObject]@{
            Type = "File Move"
            Item = $fileName
            From = (Split-Path $SourcePath -Parent)
            To   = $DestDir
        }
    } catch {
        Write-Host "  ERROR moving $fileName : $_" -ForegroundColor Red
    }
}

# Resolve folder paths using Get-ChildItem to handle Unicode correctly
$bahaiFolder   = (Get-ChildItem -LiteralPath 'C:\Users\awt\Sync\Obsidian\01' -Directory | Where-Object { $_.Name -like '*Bah*' }).FullName
$healthFolder  = 'C:\Users\awt\Sync\Obsidian\01\Health'
$homeFolder    = 'C:\Users\awt\Sync\Obsidian\01\Home'
$nlpFolder     = 'C:\Users\awt\Sync\Obsidian\01\NLP'
$scienceFolder = 'C:\Users\awt\Sync\Obsidian\01\Science'
$socialFolder  = 'C:\Users\awt\Sync\Obsidian\01\Social'
$techFolder    = 'C:\Users\awt\Sync\Obsidian\01\Technology'
$travelFolder  = 'C:\Users\awt\Sync\Obsidian\01\Travel'
$financeFolder = 'C:\Users\awt\Sync\Obsidian\01\Finance'
$pkmFolder     = 'C:\Users\awt\Sync\Obsidian\01\PKM'
$recipeFolder  = 'C:\Users\awt\Sync\Obsidian\01\Recipes'
$folFolder     = 'C:\Users\awt\Sync\Obsidian\01\FOL'

Write-Host "Bahá'í folder: $bahaiFolder" -ForegroundColor DarkCyan

# --- FILES MISPLACED IN 01\Bahá'í ---
# MOC Subsection Tags Reference.md → PKM (nav confirms: MOC - Personal Knowledge Management)
Move-VaultFile (Join-Path $bahaiFolder "MOC Subsection Tags Reference.md") $pkmFolder "PKM system file misplaced in Bahai"

# --- FILES MISPLACED IN 01\Health ---
# Grass Poisioning.md → Home (lawn/garden, nav: MOC - Home & Practical Life)
Move-VaultFile (Join-Path $healthFolder "Grass Poisioning.md") $homeFolder "Lawn care → Home"

# Lo Mein - A Healthy Makeover to a Takeout Staple.md → Recipes (recipe, not health article)
Move-VaultFile (Join-Path $healthFolder "Lo Mein - A Healthy Makeover to a Takeout Staple.md") $recipeFolder "Recipe misplaced in Health"

# Low-cost Multipurpose Minibuilding Made with Earthbags.md → Home (construction/building)
Move-VaultFile (Join-Path $healthFolder "Low-cost Multipurpose Minibuilding Made with Earthbags.md") $homeFolder "Building construction → Home"

# TX Process to Remove.md → Home (nav: MOC - Home & Practical Life, about TX ETJ process)
Move-VaultFile (Join-Path $healthFolder "TX Process to Remove.md") $homeFolder "TX ETJ process → Home"

# XJ Unisex Running Socks.md → Home (clothing/receipt, nav erroneously points to Health)
Move-VaultFile (Join-Path $healthFolder "XJ Unisex Running Socks.md") $homeFolder "Socks receipt → Home"

# Japanese Cherry Blossom Body Oil.md → Home (beauty product, nav: MOC - Japan → could be Home)
Move-VaultFile (Join-Path $healthFolder "Japanese Cherry Blossom Body Oil.md") $homeFolder "Body oil product → Home"

# How Copyright Restri.md → Music (tags: music, art, movie - licensing/IP for art/music)
Move-VaultFile (Join-Path $healthFolder "How Copyright Restri.md") (Join-Path 'C:\Users\awt\Sync\Obsidian\01' 'Music') "Copyright/music → Music"

# --- FILES MISPLACED IN 01\Finance ---
# A Year in the Round Why a Tipi.md → Home (home/travel/tipi, nav: MOC - Home & Practical Life)
Move-VaultFile (Join-Path $financeFolder "A Year in the Round Why a Tipi.md") $homeFolder "Tipi living → Home"

# How to Sort Mail.md → Home (home organization, tags: Home)
Move-VaultFile (Join-Path $financeFolder "How to Sort Mail.md") $homeFolder "Mail sorting → Home"

# Turn an FM Transmitter Into a Micro Pirate Radio.md → Technology (maker/tech project)
Move-VaultFile (Join-Path $financeFolder "Turn an FM Transmitter Into a Micro Pirate Radio.md") $techFolder "FM transmitter hack → Technology"

# WCWBF 2021-08-12 035.md → Home (nav: MOC - Home & Practical Life, community meeting)
Move-VaultFile (Join-Path $financeFolder "WCWBF 2021-08-12 035.md") $homeFolder "WCWBF community meeting → Home"

# --- FILES MISPLACED IN 01\PKM ---
# Cinnamon Orange Spice Tea.md → Recipes (food/tea/recipe tags)
Move-VaultFile (Join-Path $pkmFolder "Cinnamon Orange Spice Tea.md") $recipeFolder "Tea recipe → Recipes"

# Hot Fruit Compote.md → Recipes (recipe tag)
Move-VaultFile (Join-Path $pkmFolder "Hot Fruit Compote.md") $recipeFolder "Compote recipe → Recipes"

# How To Fold a Dress.md → Home (clothing/home tags)
Move-VaultFile (Join-Path $pkmFolder "How To Fold a Dress.md") $homeFolder "Clothing care → Home"

# Library.md → FOL (tags: Library, FOL)
Move-VaultFile (Join-Path $pkmFolder "Library.md") $folFolder "Library/FOL content → FOL"

# Turn Coat - Wikipedi.md → Reading (it's a Dresden Files novel Wikipedia article)
Move-VaultFile (Join-Path $pkmFolder "Turn Coat - Wikipedi.md") (Join-Path 'C:\Users\awt\Sync\Obsidian\01' 'Reading') "Novel article → Reading"

# --- FILES MISPLACED IN 01\Psychology ---
# HP Retiree Dave Packard.md → Technology (management rules at HP - tech company, person in tech)
# Note: This is already in the NLP MOC Psychology section; moving to Tech folder
Move-VaultFile (Join-Path 'C:\Users\awt\Sync\Obsidian\01\Psychology' "HP Retiree Dave Packard.md") $techFolder "HP/Packard management → Technology"

# The Oral History of.md → Home (tags: Home, TV, StarTrek - entertainment)
Move-VaultFile (Join-Path 'C:\Users\awt\Sync\Obsidian\01\Psychology' "The Oral History of.md") $homeFolder "Star Trek oral history → Home (Entertainment)"

# Contentment - What You Have Relative to What You Want.md → Home (Sketchplanations tag - in Home MOC Sketchplanations)
Move-VaultFile (Join-Path 'C:\Users\awt\Sync\Obsidian\01\Psychology' "Contentment - What You Have Relative to What You Want.md") $homeFolder "Sketchplanations → Home"

# --- FILES MISPLACED IN 01\Home ---
# Make Perfectly Crispy Tofu with a Waffle Iron.md → Recipes
Move-VaultFile (Join-Path $homeFolder "Make Perfectly Crispy Tofu with a Waffle Iron.md") $recipeFolder "Tofu recipe → Recipes"

# Miso - The Different Colors & Substitutions.md → Recipes
Move-VaultFile (Join-Path $homeFolder "Miso - The Different Colors & Substitutions.md") $recipeFolder "Miso cooking guide → Recipes"

# Scientists Found the Temperature That Makes Cookies Turn Out Better.md → Recipes
Move-VaultFile (Join-Path $homeFolder "Scientists Found the Temperature That Makes Cookies Turn Out Better.md") $recipeFolder "Cookie baking science → Recipes"

# Turkey Recipe for You.md → Recipes (it's a recipe)
Move-VaultFile (Join-Path $homeFolder "Turkey Recipe for You.md") $recipeFolder "Turkey recipe → Recipes"

# Why Some Rice Cooker.md → Recipes (cooking technique)
Move-VaultFile (Join-Path $homeFolder "Why Some Rice Cooker.md") $recipeFolder "Rice cooker cooking → Recipes"

# You All NEED These Obsidian Community Plugins.md → PKM (PKM/Obsidian content)
Move-VaultFile (Join-Path $homeFolder "You All NEED These Obsidian Community Plugins.md") $pkmFolder "Obsidian plugins → PKM"

# Teaching Tuesday - Tofu Guide.md → Recipes (food guide)
Move-VaultFile (Join-Path $homeFolder "Teaching Tuesday - Tofu Guide.md") $recipeFolder "Tofu guide → Recipes"

# Leading From Any Chair.md → Music (it's about orchestral leadership/music ensemble)
Move-VaultFile (Join-Path $homeFolder "Leading From Any Chair.md") (Join-Path 'C:\Users\awt\Sync\Obsidian\01' 'Music') "Orchestra leadership → Music"

# --- FILES MISPLACED IN 01\Science ---
# Build With SIPs.md → Home (structural insulated panels for home building)
Move-VaultFile (Join-Path $scienceFolder "Build With SIPs.md") $homeFolder "SIP construction → Home"

# Finding the Fabulous.md → Travel (likely travel content - check name)
# Skip without reading - name is ambiguous, leave in place

# How to Build a Rocket Stove Using Cement Blocks.md → Home (home/DIY building)
Move-VaultFile (Join-Path $scienceFolder "How to Build a Rocket Stove Using Cement Blocks.md") $homeFolder "Rocket stove DIY → Home"

# Is Cordwood Masonry.md → Home (alternative home building)
Move-VaultFile (Join-Path $scienceFolder "Is Cordwood Masonry.md") $homeFolder "Cordwood construction → Home"

# Top 8 Insulation Opt.md → Home (home building/insulation)
Move-VaultFile (Join-Path $scienceFolder "Top 8 Insulation Opt.md") $homeFolder "Insulation → Home"

# How to Make a Tipi.md → Home (home/shelter building)
Move-VaultFile (Join-Path $scienceFolder "How to Make a Tipi.md") $homeFolder "Tipi construction → Home"

# How to Grow Potatoes.md → Home > Gardening (gardening content, fine in Science/Gardening but Home also has gardening)
# This could go either way - leave in Science (Gardening & Botany section)

# Key Data Perspective for Autosomal DNA.md → needs to check - could be Genealogy
# Leave it - Science deals with genetics broadly

Write-Host ""
Write-Host "=== Cleanup Complete ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# SUMMARY TABLE
# ============================================================
Write-Host "SUMMARY OF CHANGES:" -ForegroundColor Cyan
Write-Host ""

$mocChanges = $log | Where-Object { $_.Type -like "MOC*" }
$fileChanges = $log | Where-Object { $_.Type -eq "File Move" }

Write-Host "--- MOC Changes ($($mocChanges.Count)) ---" -ForegroundColor Yellow
$mocChanges | Format-Table -AutoSize -Property Type, Item, From, To

Write-Host "--- File Moves ($($fileChanges.Count)) ---" -ForegroundColor Yellow
$fileChanges | Format-Table -AutoSize -Property Item, From, To
