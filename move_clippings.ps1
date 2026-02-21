# Move files from 10 - Clippings to appropriate 01 subdirectories
$src = "D:\Obsidian\Main\10 - Clippings"

# Define moves: filename => destination folder
$moves = @{
    # Social Issues (7 files)
    "Announcements - Community Service Newsletter Sep 1986.md" = "D:\Obsidian\Main\01\Social"
    "Bioregionalism Conference - Jane Morgan.md" = "D:\Obsidian\Main\01\Social"
    "Commentary - Response to Victor Tauferner - Jann Rucquoi.md" = "D:\Obsidian\Main\01\Social"
    "Readers Write - Community Service Newsletter Sep 1986.md" = "D:\Obsidian\Main\01\Social"
    "Selling the New Age Message.md" = "D:\Obsidian\Main\01\Social"
    "This School Principal's Song Went Viral and Became the Black National Anthem.md" = "D:\Obsidian\Main\01\Social"
    "What About the Children.md" = "D:\Obsidian\Main\01\Social"
    # Technology (3 files)
    "Free Online PDF Editor.md" = "D:\Obsidian\Main\01\Technology"
    "How to Email to sms Address - Google Search.md" = "D:\Obsidian\Main\01\Technology"
    "I Didn't Realize This Tiny Letter on My microSD Card Was So Important.md" = "D:\Obsidian\Main\01\Technology"
    # Reading (1 file)
    "Book Review - From the Roots Up - Brian Fallon.md" = "D:\Obsidian\Main\01\Reading"
    # Home (3 files)
    "Bosses vs Leaders.md" = "D:\Obsidian\Main\01\Home"
    "Leading From Any Chair.md" = "D:\Obsidian\Main\01\Home"
    "When There's a Gold Rush, Sell Shovels.md" = "D:\Obsidian\Main\01\Home"
}

# Handle Bahá'í separately due to special characters
$bahaiDest = "D:\Obsidian\Main\01\Bah" + [char]0x00E1 + "'" + [char]0x00ED
$moves["How Do Baha'is Plan to Change the World.md"] = $bahaiDest

$moved = 0
$errors = 0

foreach ($file in $moves.Keys) {
    $sourcePath = Join-Path $src $file
    $destDir = $moves[$file]

    # Check source exists
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        Write-Host "SKIP (not found): $file" -ForegroundColor Yellow
        continue
    }

    # Check destination directory exists
    if (-not (Test-Path -LiteralPath $destDir)) {
        Write-Host "SKIP (no dest dir): $file -> $destDir" -ForegroundColor Yellow
        continue
    }

    $destPath = Join-Path $destDir $file

    # Check if already exists at destination
    if (Test-Path -LiteralPath $destPath) {
        Write-Host "SKIP (exists at dest): $file" -ForegroundColor Yellow
        continue
    }

    try {
        Move-Item -LiteralPath $sourcePath -Destination $destPath -ErrorAction Stop
        Write-Host "OK: $file -> $destDir" -ForegroundColor Green
        $moved++
    }
    catch {
        Write-Host "ERROR: $file - $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`nDone: $moved moved, $errors errors" -ForegroundColor Cyan

# Show anything remaining
$remaining = Get-ChildItem -Path $src -Filter "*.md" -ErrorAction SilentlyContinue
if ($remaining) {
    Write-Host "`nRemaining in 10 - Clippings:" -ForegroundColor Yellow
    foreach ($r in $remaining) {
        Write-Host "  $($r.Name)"
    }
} else {
    Write-Host "10 - Clippings is now empty of .md files" -ForegroundColor Green
}
