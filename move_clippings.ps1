# Move files from 10 - Clippings to appropriate 01 subdirectories
$src = "C:\Users\awt\Sync\Obsidian\10 - Clippings"

# Define moves: filename => destination folder
$moves = @{
    # Social Issues (7 files)
    "Announcements - Community Service Newsletter Sep 1986.md" = "C:\Users\awt\Sync\Obsidian\01\Social"
    "Bioregionalism Conference - Jane Morgan.md" = "C:\Users\awt\Sync\Obsidian\01\Social"
    "Commentary - Response to Victor Tauferner - Jann Rucquoi.md" = "C:\Users\awt\Sync\Obsidian\01\Social"
    "Readers Write - Community Service Newsletter Sep 1986.md" = "C:\Users\awt\Sync\Obsidian\01\Social"
    "Selling the New Age Message.md" = "C:\Users\awt\Sync\Obsidian\01\Social"
    "This School Principal's Song Went Viral and Became the Black National Anthem.md" = "C:\Users\awt\Sync\Obsidian\01\Social"
    "What About the Children.md" = "C:\Users\awt\Sync\Obsidian\01\Social"
    # Technology (3 files)
    "Free Online PDF Editor.md" = "C:\Users\awt\Sync\Obsidian\01\Technology"
    "How to Email to sms Address - Google Search.md" = "C:\Users\awt\Sync\Obsidian\01\Technology"
    "I Didn't Realize This Tiny Letter on My microSD Card Was So Important.md" = "C:\Users\awt\Sync\Obsidian\01\Technology"
    # Reading (1 file)
    "Book Review - From the Roots Up - Brian Fallon.md" = "C:\Users\awt\Sync\Obsidian\01\Reading"
    # Home (5 files)
    "Bosses vs Leaders.md" = "C:\Users\awt\Sync\Obsidian\01\Home"
    "Leading From Any Chair.md" = "C:\Users\awt\Sync\Obsidian\01\Home"
    "When There's a Gold Rush, Sell Shovels.md" = "C:\Users\awt\Sync\Obsidian\01\Home"
}

# Handle Bahá'í separately due to special characters
$bahaiDest = "C:\Users\awt\Sync\Obsidian\01\Bah" + [char]0x00E1 + "'" + [char]0x00ED
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

# New moves for today's classification session (2026-04-10)
$newMoves = @(
    @{ Src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Wit, Unker, Git The Lost Medieval Pronouns of English Intimacy.md";
       Dst = "C:\Users\awt\Sync\Obsidian\01\Science\Wit, Unker, Git The Lost Medieval Pronouns of English Intimacy.md" },
    @{ Src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Nhs Epaulette Rankss.md";
       Dst = "C:\Users\awt\Sync\Obsidian\01\Home\NHS Epaulette Ranks.md" },
    @{ Src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Nhs Epaulette Rankss North West Ambulance Service.md";
       Dst = "C:\Users\awt\Sync\Obsidian\01\Home\NHS Epaulette Ranks - North West Ambulance Service.md" },
    @{ Src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Relationship Rupture and the Limbic System The Physiology of Abandonment and Separation.md";
       Dst = "C:\Users\awt\Sync\Obsidian\01\Psychology\Relationship Rupture and the Limbic System The Physiology of Abandonment and Separation.md" },
    @{ Src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\So Nothing Rhymes with Orange.md";
       Dst = "C:\Users\awt\Sync\Obsidian\01\Home\So Nothing Rhymes with Orange.md" }
)

foreach ($move in $newMoves) {
    if (Test-Path -LiteralPath $move.Src) {
        if (Test-Path -LiteralPath $move.Dst) {
            Write-Host "SKIP (exists at dest): $($move.Src | Split-Path -Leaf)" -ForegroundColor Yellow
        } else {
            try {
                Move-Item -LiteralPath $move.Src -Destination $move.Dst -ErrorAction Stop
                Write-Host "OK: $($move.Src | Split-Path -Leaf) -> $(Split-Path $move.Dst -Parent | Split-Path -Leaf)" -ForegroundColor Green
                $moved++
            } catch {
                Write-Host "ERROR: $($move.Src | Split-Path -Leaf) - $($_.Exception.Message)" -ForegroundColor Red
                $errors++
            }
        }
    } else {
        Write-Host "SKIP (not found): $($move.Src | Split-Path -Leaf)" -ForegroundColor Yellow
    }
}

# New moves for 2026-04-17 classification session
$bahaiFolder = (Get-ChildItem 'C:\Users\awt\Sync\Obsidian\01' -Directory | Where-Object { $_.Name -like 'Bah*' } | Select-Object -First 1).FullName

# Build the ellipsis filename for the Baha'i article
$bahaiArticleSrc = "C:\Users\awt\Sync\Obsidian\10 - Clippings\If You Can't Say Something Nice" + [char]0x2026 + ".md"

$newMoves2 = @(
    @{ Src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Lost Lincoln Portrait From Teddy Roosevelt's Office Reemerges After a Century.md";
       Dst = "C:\Users\awt\Sync\Obsidian\01\Social\" },
    @{ Src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\How Mobile Phone Cameras Have Helped Unearth a Mysterious Kingdom.md";
       Dst = "C:\Users\awt\Sync\Obsidian\01\Science\" },
    @{ Src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\A Lost Icon The American Chestnut and Its Central Place in the Eastern Landscape.md";
       Dst = "C:\Users\awt\Sync\Obsidian\01\Science\" },
    @{ Src = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Good Vibrations.md";
       Dst = "C:\Users\awt\Sync\Obsidian\01\Health\" },
    @{ Src = $bahaiArticleSrc;
       Dst = "$bahaiFolder\" }
)

foreach ($move in $newMoves2) {
    # Skip if Dst is null (e.g., Baha'i folder not found)
    if ($null -eq $move.Dst -or $move.Dst -eq '\') {
        Write-Host "SKIP (no dest): $($move.Src | Split-Path -Leaf)" -ForegroundColor Yellow
        continue
    }
    $srcFile = Get-Item -LiteralPath $move.Src -ErrorAction SilentlyContinue
    if ($null -eq $srcFile) {
        Write-Host "SKIP (not found): $($move.Src | Split-Path -Leaf)" -ForegroundColor Yellow
        continue
    }
    $dstPath = Join-Path $move.Dst $srcFile.Name
    if (Test-Path -LiteralPath $dstPath) {
        Write-Host "SKIP (exists at dest): $($srcFile.Name)" -ForegroundColor Yellow
        continue
    }
    try {
        Move-Item -LiteralPath $srcFile.FullName -Destination $move.Dst -Force -ErrorAction Stop
        Write-Host "MOVED: $($srcFile.Name) -> $($move.Dst)" -ForegroundColor Green
        $moved++
    } catch {
        Write-Host "ERROR: $($srcFile.Name) - $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`nDone: $moved moved, $errors errors" -ForegroundColor Cyan

# Show anything remaining
$remaining = Get-ChildItem -Path $src -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "10 - Clippings.md" }
if ($remaining) {
    Write-Host "`nRemaining in 10 - Clippings:" -ForegroundColor Yellow
    foreach ($r in $remaining) {
        Write-Host "  $($r.Name)"
    }
} else {
    Write-Host "10 - Clippings is now empty of .md files" -ForegroundColor Green
}
