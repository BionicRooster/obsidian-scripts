# Move remaining unclassified files from 20 - Permanent Notes
# Manual classification based on content analysis

$vaultPath = "D:\Obsidian\Main"
$sourcePath = "$vaultPath\20 - Permanent Notes"
$destBase = "$vaultPath\01"

# File mappings based on manual review
$fileMap = @{
    # Bahá'í related
    "Badí Calendar Class.md" = "Bahá'í"

    # Genealogy related
    "Probate more than a Will.md" = "Genealogy"
    "Delores Joiner Photo.md" = "Genealogy"
    "Jack Horn Death Notification.md" = "Genealogy"
    "HP Retiree  Dave Packard.md" = "Genealogy"

    # Technology related
    "Garage Sales, Yard &.md" = "Technology"
    "GISD Student Calenda.md" = "Technology"
    "LG--- dishwasher.md" = "Home"
    "MAKE Blog QRS halts.md" = "Technology"
    "Supported Devices -.md" = "Technology"
    "Texas Television, Te.md" = "Technology"
    "WKRP Turkey Drop T-S.md" = "Music"

    # Home/Personal
    "Beautiful sunrise.md" = "Home"
    "Brunson Fencing.md" = "Home"
    "Grass Poisioning.md" = "Health"
    "Pinkish background.md" = "Home"
    "Shopping List.md" = "Home"
    "Sigora Solar.md" = "Home"
    "What a wonderful world T-Shirt.md" = "Home"

    # Art/Culture
    "Discover Kolams, the.md" = "Home"
    "Dragon TP Hoard.md" = "Home"
    "gapingvoid cartoons.md" = "Home"
    "Imaginary Foundation.md" = "Home"
    "Sweet Juniper!.md" = "Home"
    "The Soap Factory - C.md" = "Home"

    # People Pictures - likely genealogy
    "People Pictures 1.md" = "Genealogy"
    "People Pictures 2.md" = "Genealogy"
    "People Pictures 3.md" = "Genealogy"

    # NLP/Psychology
    "Nightingale Group.md" = "NLP_Psy"
    "Where Are Your Keys.md" = "NLP_Psy"

    # Military
    "Request for military.md" = "Genealogy"

    # Religion
    "Judaism.md" = "Religion"

    # Health
    "Coronavirus chart.md" = "Health"
}

$moved = 0
$failed = 0

foreach ($fileName in $fileMap.Keys) {
    $category = $fileMap[$fileName]
    $srcFile = Join-Path $sourcePath $fileName
    $destFolder = Join-Path $destBase $category

    if (Test-Path $srcFile) {
        $destFile = Join-Path $destFolder $fileName

        if (Test-Path $destFile) {
            Write-Host "DUPLICATE: $fileName already exists in $category" -ForegroundColor Yellow
            $failed++
        } else {
            try {
                Move-Item -Path $srcFile -Destination $destFolder -ErrorAction Stop
                Write-Host "MOVED: $fileName -> $category" -ForegroundColor Green
                $moved++
            }
            catch {
                Write-Host "ERROR moving $fileName : $($_.Exception.Message)" -ForegroundColor Red
                $failed++
            }
        }
    } else {
        Write-Host "NOT FOUND: $fileName" -ForegroundColor Gray
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Moved: $moved"
Write-Host "Failed/Skipped: $failed"

# List remaining files
$remaining = Get-ChildItem -Path $sourcePath -Filter "*.md" | Where-Object { $_.Name -ne "20 - Permanent Notes.md" }
Write-Host "`nRemaining files: $($remaining.Count)"
$remaining | ForEach-Object { Write-Host "  - $($_.Name)" }
