# move_clippings_batch.ps1
# Moves specified files from 10 - Clippings to appropriate 01\ subdirectories.
# Checks for existence at source and destination before moving.
# Uses UTF-8 encoding for any file reads/writes if needed.

# Source directory — all files come from here
$sourceDir = "C:\Users\awt\Sync\Obsidian\10 - Clippings"

# Destination directories
$destTech   = "C:\Users\awt\Sync\Obsidian\01\Technology"
$destBahai  = $null   # will be resolved via real path below
$destSocial = "C:\Users\awt\Sync\Obsidian\01\Social"
$destTravel = "C:\Users\awt\Sync\Obsidian\01\Travel"

# Resolve the Baha'i folder by scanning 01\ for its actual name
$vaultRoot = "C:\Users\awt\Sync\Obsidian\01"
$bahaiFolder = Get-ChildItem -LiteralPath $vaultRoot -Directory |
    Where-Object { $_.Name -like "Bah*" } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $bahaiFolder) {
    Write-Host "ERROR: Could not find Baha'i folder under $vaultRoot" -ForegroundColor Red
    exit 1
}

Write-Host "Resolved Baha'i folder: $bahaiFolder" -ForegroundColor Cyan

# -----------------------------------------------------------------------
# File lists per destination
# Key: destination path variable  Value: array of filenames
# -----------------------------------------------------------------------

# Technology files
$techFiles = @(
    "Delete all folders except 2 latest folders in Windows.md",
    "How to Delete Files Older than X Days on Windows.md",
    "windows - Batch file to delete files older than N days - Stack Overflow.md",
    "How to automate Word with Visual Basic to create a Mail Merge - Office.md",
    "Use mail merge to send Access data to Word - Access.md",
    "Customize the Navigation Pane - Microsoft Support.md",
    "Grouping Objects in Access_ An Organizational Tip You Can't Miss - MicroKnowledge, Inc.md",
    "Documenting query dependencies in Access - Home - DataWright Information Services 1.md",
    "Documenting tables - DataWright Information Services - Home - DataWright Information Services.md",
    "Documenting query dependencies in Access - Home - DataWright Information Services.md",
    "Row Numbers in Query Result Using Microsoft Access - ITCodar.md",
    "NAS OS options.md",
    "Microsoft Office 2021 License Personal.md",
    "Automatically Format Numbers in Thousands, Millions, Billions in Excel 2 Techniques.md",
    "Apply color to alternate rows or columns - Microsoft Support.md",
    "How to Scan Removable Drives With Microsoft Defender.md",
    "Add Months to Date in MSExcel.md",
    "How to find the disk and volume GUID on Windows 10.md",
    "TurboTax 2021 Key.md",
    "Merge Instructions for Changing Case for Word 2016 & Word 2008 _ NC State Extension.md",
    "Mount and dismount hard drive through a script or software.md",
    "How to Copy Only New Files and Changed Files With XCopy on Windows.md",
    "Windows variables.md",
    "Convert the Text in the Field of a Microsoft Access Table to Proper Case with a Query.md",
    "HP calculator Batteries.md",
    "These Pivot Table tricks massively save your time \u2013 Excel Tips & Tricks.md",
    "Access VBA check if Query is empty.md",
    "Acronis True Image order.md",
    "CSV-to-ICS Converter Format.md",
    "SQLite3 SQL Commands Explained with Examples.md",
    "AccessBlog.net Access System Tables Tips and tricks, news, links, downloads on Microsoft Access.md",
    "Access Wizard Finding Information on All Linked Tables - The Easy Way.md",
    "Search For Text, A2000+ - UtterAccess Forums.md",
    "Rick Fisher Consulting (Find and Replace for Microsoft Access).md",
    "Handbrake Documentation - Audio and Subtitle Defaults.md",
    "ExpressVPN Password.md",
    "Windows 11 Pro Unused.md",
    "Stellar repair for Access.md",
    "Stardock Groupy License Key.md",
    "Purchase CSV ICS converter.md",
    "Print Artist Gold 25 Receipt.md",
    "Assistant DBA Job Description.md",
    "Microsoft Office 2024 Professional Plus keys.md",
    "Restore old Right-click Context menu in Windows 11.md"
)

# Baha'i files
$bahaiFiles = @(
    "19th Century Religious Movements.md",
    "The Religious Mission of the English-Speaking Nations.md",
    "Seeker.md"
)

# Social files
$socialFiles = @(
    "Christians - More Like Jesus or Pharisees.md"
)

# Travel files
$travelFiles = @(
    "Santa Fe Scenic Railroad.md",
    "Cumbres & Toltec Scenic Railroad.md",
    "Turquoise Trail National Scenic Byway.md",
    "Santa Fe Plaza.md",
    "Acoma Sky City - 60 mi w of Alb.md",
    "Pecos National Historical Park.md"
)

# -----------------------------------------------------------------------
# Build a combined move list: array of [filename, destDir] pairs
# -----------------------------------------------------------------------
$moveList = @()

foreach ($f in $techFiles)   { $moveList += ,@($f, $destTech) }
foreach ($f in $bahaiFiles)  { $moveList += ,@($f, $bahaiFolder) }
foreach ($f in $socialFiles) { $moveList += ,@($f, $destSocial) }
foreach ($f in $travelFiles) { $moveList += ,@($f, $destTravel) }

# -----------------------------------------------------------------------
# Result tracking
# -----------------------------------------------------------------------
$moved   = [System.Collections.Generic.List[string]]::new()  # files successfully moved
$skipped = [System.Collections.Generic.List[string]]::new()  # files skipped (dest exists)
$missing = [System.Collections.Generic.List[string]]::new()  # files not found at source

# -----------------------------------------------------------------------
# Process each file
# -----------------------------------------------------------------------
foreach ($pair in $moveList) {
    $fileName = $pair[0]   # original filename
    $destDir  = $pair[1]   # destination directory path

    # Normalize smart/curly apostrophes in filename before operations
    # U+2019 RIGHT SINGLE QUOTATION MARK -> standard apostrophe
    $safeFileName = $fileName -replace [char]0x2019, "'"

    # Build full source path using LiteralPath-safe join
    $sourcePath = Join-Path -Path $sourceDir -ChildPath $safeFileName

    # Build full destination path
    $destPath = Join-Path -Path $destDir -ChildPath $safeFileName

    # --- Check 1: Does source file exist? ---
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        Write-Host "NOT FOUND:  $safeFileName" -ForegroundColor Yellow
        $missing.Add("$safeFileName  [looked in: $sourceDir]")
        continue
    }

    # --- Check 2: Does destination already have this file? ---
    if (Test-Path -LiteralPath $destPath) {
        Write-Host "SKIP (exists at dest): $safeFileName" -ForegroundColor DarkYellow
        $skipped.Add("$safeFileName  [dest: $destDir]")
        continue
    }

    # --- Move the file ---
    try {
        Move-Item -LiteralPath $sourcePath -Destination $destPath -ErrorAction Stop
        Write-Host "MOVED:  $safeFileName  ->  $destDir" -ForegroundColor Green
        $moved.Add("$safeFileName  ->  $destDir")
    }
    catch {
        Write-Host "ERROR moving $safeFileName`: $_" -ForegroundColor Red
        $missing.Add("$safeFileName  [ERROR: $_]")
    }
}

# -----------------------------------------------------------------------
# Summary report
# -----------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "           MOVE RESULTS SUMMARY         " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "MOVED ($($moved.Count)):" -ForegroundColor Green
foreach ($item in $moved) { Write-Host "  + $item" }

Write-Host ""
Write-Host "SKIPPED - already at destination ($($skipped.Count)):" -ForegroundColor DarkYellow
foreach ($item in $skipped) { Write-Host "  ~ $item" }

Write-Host ""
Write-Host "NOT FOUND / ERRORS ($($missing.Count)):" -ForegroundColor Yellow
foreach ($item in $missing) { Write-Host "  ? $item" }

Write-Host ""
Write-Host "Total processed: $($moveList.Count)  |  Moved: $($moved.Count)  |  Skipped: $($skipped.Count)  |  Not found: $($missing.Count)" -ForegroundColor Cyan
