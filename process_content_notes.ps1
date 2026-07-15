# Process all content notes: rename, add frontmatter, move, delete duplicates
$clippings = "C:\Users\awt\Sync\Obsidian\10 - Clippings"
$vault = "C:\Users\awt\Sync\Obsidian"

# --- Step 1: Rename Forest Gardens file (smart apostrophes -> standard) ---
$forestOld = Get-ChildItem $clippings | Where-Object { $_.Name -like "*Forest*gardens*" }
if ($forestOld) {
    $newName = "'Forest gardens' show how Native land stewardship can outdo nature.md"
    $newPath = Join-Path $clippings $newName
    if (-not (Test-Path $newPath)) {
        Rename-Item $forestOld.FullName $newPath
        Write-Host "Renamed: $($forestOld.Name) -> $newName"
    } else {
        Write-Host "Already renamed or target exists: $newName"
    }
}

# --- Step 2: Delete 10-Clippings duplicates (already processed in 01/ or replaced by 15-People) ---
$duplicates = @(
    "Alfred W. Talbot Sr Military record.md",
    "Col Mathew Talbot  1699-1758.md",
    "Vera Irene Talbot - Intellus.md",
    "Obituary - John Henry White.md",
    "Lee Etta Stanard.md",
    "The Daniel Norris Code for Success - The Simple Dollar.md",
    "A Fan Asks Mike Rowe For Career Advice...He Didn't Expect This Response, But It's Brilliant.md"
)
foreach ($dup in $duplicates) {
    $path = Join-Path $clippings $dup
    if (Test-Path $path) {
        Remove-Item $path -Force
        Write-Host "Deleted duplicate: $dup"
    }
}

# --- Step 3: Delete old 01/ versions replaced by 15-People person notes ---
$old01 = @(
    "C:\Users\awt\Sync\Obsidian\01\Genealogy\Alfred W. Talbot Sr.md",
    "C:\Users\awt\Sync\Obsidian\01\Genealogy\Col Mathew Talbot.md",
    "C:\Users\awt\Sync\Obsidian\01\Genealogy\Vera Irene Talbot.md",
    "C:\Users\awt\Sync\Obsidian\01\Technology\Vera Irene Talbot -I.md",
    "C:\Users\awt\Sync\Obsidian\01\Genealogy\Dr. Alfred Carson Waldrep Jr.md",
    "C:\Users\awt\Sync\Obsidian\01\Genealogy\Obituary - John Henry White.md",
    "C:\Users\awt\Sync\Obsidian\01\Genealogy\Lee Etta Stanard.md",
    "C:\Users\awt\Sync\Obsidian\01\Finance\The Daniel Norris Code for Success - The Simple Dollar.md",
    "C:\Users\awt\Sync\Obsidian\01\Finance\The Daniel Norris Co.md"
)
foreach ($path in $old01) {
    if (Test-Path $path) {
        Remove-Item $path -Force
        Write-Host "Deleted old 01 version: $path"
    }
}

# --- Step 4: Move content notes to appropriate 01/ folders ---
# Helper function to add/update nav and tags in frontmatter
function Update-Frontmatter {
    param($filePath, $nav, $newTags)
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

    # Check if frontmatter exists
    if ($content -match '(?s)^---\r?\n(.+?)\r?\n---') {
        # Update nav if not present
        if ($content -notmatch 'nav:') {
            $content = $content -replace '(^---\r?\n)', "`$1nav: `"$nav`"`n"
        }
        # Update tags - add new tags to existing
        foreach ($tag in $newTags) {
            if ($content -notmatch "- `"?$tag`"?") {
                if ($content -match 'tags:\r?\n') {
                    $content = $content -replace '(tags:\r?\n)', "`$1  - `"$tag`"`n"
                }
            }
        }
    } else {
        # Add frontmatter
        $tagsYaml = ($newTags | ForEach-Object { "  - `"$_`"" }) -join "`n"
        $fm = "---`nnav: `"$nav`"`ntags:`n$tagsYaml`n---`n"
        $content = $fm + $content
    }
    [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
}

# Define moves: filename -> [destination folder, nav link, additional tags]
$moves = @{
    "'Forest gardens' show how Native land stewardship can outdo nature.md" = @("01\Science", "[[00 - Home Dashboard/MOC - Science & Nature]]", @("Nature", "Indigenous", "Ecology", "ForestGardening"))
    "Greenscreen backdrop folding instructions.md" = @("01\Home", "[[00 - Home Dashboard/MOC - Home & Practical Life]]", @("Photography", "Greenscreen", "DIY", "HomeProjects"))
    "Bloom's Taxonomy of Learning.md" = @("01\PKM", "[[00 - Home Dashboard/MOC - Personal Knowledge Management]]", @("Education", "Learning", "PKM", "Taxonomy"))
    "Clean Air Floor Removal.md" = @("01\Home", "[[00 - Home Dashboard/MOC - Home & Practical Life]]", @("Flooring", "HomeRepair", "Contractor"))
    "Contracting with DIR.md" = @("01\Home", "[[00 - Home Dashboard/MOC - Home & Practical Life]]", @("Consulting", "Career", "Texas", "DIR"))
    "Do liberals want to destroy America.md" = @("01\Social", "[[00 - Home Dashboard/MOC - Social Issues]]", @("Politics", "Liberals", "America"))
    "Me and Jo Photo H.md" = @("01\Home", "[[00 - Home Dashboard/MOC - Home & Practical Life]]", @("PersonalPhoto", "Family"))
    "Me and Jo photo h1.md" = @("01\Home", "[[00 - Home Dashboard/MOC - Home & Practical Life]]", @("PersonalPhoto", "Family"))
    "Uni Kuru Toga - The Best Pencil in the World.md" = @("01\Home", "[[00 - Home Dashboard/MOC - Home & Practical Life]]", @("Tools", "Pencil", "Stationery", "CoolTools"))
    "How Clutter Affects Your Brain (and What You Can Do About It).md" = @("01\NLP_Psy", "[[00 - Home Dashboard/MOC - NLP & Psychology]]", @("Psychology", "Clutter", "Cognition", "Brain"))
    "Matthew Talbot Ancestry.md" = @("01\Genealogy", "[[00 - Home Dashboard/MOC - Genealogy]]", @("Genealogy", "Talbot", "Ancestry", "NobleLines"))
    "Matthew Talbot 01.md" = @("01\Genealogy", "[[00 - Home Dashboard/MOC - Genealogy]]", @("Genealogy", "Talbot"))
}

foreach ($filename in $moves.Keys) {
    $src = Join-Path $clippings $filename
    if (-not (Test-Path $src)) {
        Write-Host "MISSING: $filename"
        continue
    }
    $destFolder = Join-Path $vault $moves[$filename][0]
    $nav = $moves[$filename][1]
    $tags = $moves[$filename][2]
    $dest = Join-Path $destFolder $filename

    # Update frontmatter before moving
    Update-Frontmatter -filePath $src -nav $nav -newTags $tags

    # Move
    if (-not (Test-Path $destFolder)) { New-Item -ItemType Directory -Path $destFolder | Out-Null }
    Move-Item $src $dest -Force
    Write-Host "Moved: $filename -> $($moves[$filename][0])"
}

Write-Host "`nDone!"
