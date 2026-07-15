# =============================================================================
# NLP / Psychology Folder Reorganization
# - Creates 01\NLP
# - Moves NLP Master Class subfolder to 01\NLP\NLP Master Class
# - Moves all NLP-tagged files from 01\NLP_Psy to 01\NLP
# - Updates nav headers in all affected files
# - Renames 01\NLP_Psy to 01\Psychology
# =============================================================================

$nlpPsyDir = 'C:\Users\awt\Sync\Obsidian\01\NLP_Psy'
$nlpDir    = 'C:\Users\awt\Sync\Obsidian\01\NLP'
$psyDir    = 'C:\Users\awt\Sync\Obsidian\01\Psychology'
$mcSrc     = 'C:\Users\awt\Sync\Obsidian\01\NLP_Psy\NLP Master Class'
$mcDst     = 'C:\Users\awt\Sync\Obsidian\01\NLP\NLP Master Class'

# ── Step 1: Create 01\NLP ────────────────────────────────────────────────────
Write-Host "Step 1: Creating 01\NLP..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $nlpDir -Force | Out-Null
Write-Host "  Created: $nlpDir" -ForegroundColor Green

# ── Step 2: Move NLP Master Class subfolder ──────────────────────────────────
Write-Host "Step 2: Moving NLP Master Class..." -ForegroundColor Cyan
Move-Item -Path $mcSrc -Destination $mcDst
Write-Host "  Moved: NLP Master Class -> 01\NLP\NLP Master Class" -ForegroundColor Green

# ── Step 3: Update nav in NLP Master Class files ─────────────────────────────
Write-Host "Step 3: Updating nav in NLP Master Class files..." -ForegroundColor Cyan
$mcFiles = Get-ChildItem -Path $mcDst -File -Filter '*.md'
$mcUpdated = 0
foreach ($f in $mcFiles) {
    $content = Get-Content $f.FullName -Encoding UTF8 -Raw
    if ($content -match '\[\[01/NLP_Psy\]\]') {
        $content = $content -replace '\[\[01/NLP_Psy\]\]', '[[01/NLP]]'
        [System.IO.File]::WriteAllText($f.FullName, $content, [System.Text.Encoding]::UTF8)
        $mcUpdated++
    }
}
Write-Host "  Updated nav in $mcUpdated NLP Master Class files" -ForegroundColor Green

# ── Step 4: Move NLP-tagged files from NLP_Psy to NLP ───────────────────────
Write-Host "Step 4: Moving NLP-tagged files to 01\NLP..." -ForegroundColor Cyan
$movedFiles = @()
$stayFiles  = @()

$allFiles = Get-ChildItem -Path $nlpPsyDir -File
foreach ($f in $allFiles) {
    # Read first 25 lines to check for NLP tag
    $lines = Get-Content $f.FullName -Encoding UTF8 -TotalCount 25
    $hasNLP = ($lines | Where-Object { $_ -match '\bNLP\b' }).Count -gt 0

    if ($hasNLP) {
        $dst = Join-Path $nlpDir $f.Name
        Move-Item -Path $f.FullName -Destination $dst
        $movedFiles += $f.Name
    } else {
        $stayFiles += $f.Name
    }
}
Write-Host "  Moved $($movedFiles.Count) NLP-tagged files to 01\NLP" -ForegroundColor Green
Write-Host "  Leaving $($stayFiles.Count) files in NLP_Psy (-> Psychology)" -ForegroundColor Yellow

# ── Step 5: Update nav in moved NLP files ───────────────────────────────────
Write-Host "Step 5: Updating nav in moved NLP files..." -ForegroundColor Cyan
$nlpNavUpdated = 0
Get-ChildItem -Path $nlpDir -File -Filter '*.md' | ForEach-Object {
    $content = Get-Content $_.FullName -Encoding UTF8 -Raw
    if ($content -match '\[\[01/NLP_Psy\]\]') {
        $content = $content -replace '\[\[01/NLP_Psy\]\]', '[[01/NLP]]'
        [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.Encoding]::UTF8)
        $nlpNavUpdated++
    }
}
Write-Host "  Updated nav in $nlpNavUpdated NLP files" -ForegroundColor Green

# ── Step 6: Update nav in remaining Psychology files ────────────────────────
Write-Host "Step 6: Updating nav in remaining Psychology files..." -ForegroundColor Cyan
$psyNavUpdated = 0
Get-ChildItem -Path $nlpPsyDir -File -Filter '*.md' | ForEach-Object {
    $content = Get-Content $_.FullName -Encoding UTF8 -Raw
    if ($content -match '\[\[01/NLP_Psy\]\]') {
        $content = $content -replace '\[\[01/NLP_Psy\]\]', '[[01/Psychology]]'
        [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.Encoding]::UTF8)
        $psyNavUpdated++
    }
}
Write-Host "  Updated nav in $psyNavUpdated Psychology files" -ForegroundColor Green

# ── Step 7: Rename NLP_Psy to Psychology ────────────────────────────────────
Write-Host "Step 7: Renaming NLP_Psy to Psychology..." -ForegroundColor Cyan
Rename-Item -Path $nlpPsyDir -NewName 'Psychology'
Write-Host "  Renamed: 01\NLP_Psy -> 01\Psychology" -ForegroundColor Green

# ── Summary ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  NLP files moved:         $($movedFiles.Count)"
Write-Host "  Psychology files remain: $($stayFiles.Count)"
Write-Host ""
Write-Host "Files staying in Psychology:" -ForegroundColor Yellow
$stayFiles | ForEach-Object { Write-Host "  $_" }
Write-Host ""
Write-Host "NLP Master Class files nav updated: $mcUpdated" -ForegroundColor Green
