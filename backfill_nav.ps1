# Backfill nav property to all notes missing it under 01\
param(
    [switch]$DryRun
)

$vault = 'C:\Users\awt\Sync\Obsidian'
$notesRoot = Join-Path $vault '01'

# Folder-name to MOC wikilink mapping
$folderMocMap = @{
    'Finance'    = '[[MOC - Finance & Investment]]'
    'FOL'        = '[[MOC - Friends of the Georgetown Public Library]]'
    'Genealogy'  = '[[MOC - Genealogy]]'
    'Health'     = '[[MOC - Health & Nutrition]]'
    'Home'       = '[[MOC - Home & Practical Life]]'
    'Japan'      = '[[MOC - Japan & Japanese Culture]]'
    'Music'      = '[[MOC - Music & Record]]'
    'NLP'        = '[[MOC - NLP & Psychology]]'
    'PKM'        = '[[MOC - Personal Knowledge Management]]'
    'Psychology' = '[[MOC - NLP & Psychology]]'
    'Reading'    = '[[MOC - Reading & Literature]]'
    'Recipes'    = '[[MOC - Recipes]]'
    'Religion'   = '[[MOC - Social Issues]]'
    'Science'    = '[[MOC - Science & Nature]]'
    'Soccer'     = '[[MOC - Soccer]]'
    'Social'     = '[[MOC - Social Issues]]'
    'Technology' = '[[MOC - Technology & Computers]]'
    'Travel'     = '[[MOC - Travel & Exploration]]'
}

# Resolve Bahai folder (diacritics need wildcard)
$bahaiFolders = Get-ChildItem -Path $notesRoot -Directory | Where-Object { $_.Name -like 'Bah*' }
foreach ($bf in $bahaiFolders) {
    $mocName = 'MOC - Bah' + [char]0x00e1 + [char]0x2019 + [char]0x00ed + ' Faith'
    $folderMocMap[$bf.Name] = "[[${mocName}]]"
}

$updated    = 0
$skipped    = 0
$noFM       = 0
$errors     = 0

$subfolders = Get-ChildItem -Path $notesRoot -Directory

foreach ($folder in $subfolders) {
    $folderName = $folder.Name
    $moc = $folderMocMap[$folderName]

    if (-not $moc) {
        Write-Output "SKIP (no MOC mapping): $folderName"
        continue
    }

    $files = Get-ChildItem -Path $folder.FullName -Filter '*.md' -File

    foreach ($file in $files) {
        try {
            $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

            # Already has nav — skip
            if ($content -match '(?m)^nav:') {
                $skipped++
                continue
            }

            $newContent = $null

            # Has frontmatter: find closing --- and insert nav before it
            if ($content.StartsWith('---')) {
                $secondDash = $content.IndexOf('---', 3)
                if ($secondDash -gt 0) {
                    $before = $content.Substring(0, $secondDash)
                    $after  = $content.Substring($secondDash)
                    $navLine = "nav: `"$moc`"`r`n"
                    $newContent = $before + $navLine + $after
                }
            }

            # No frontmatter — prepend a new block
            if (-not $newContent) {
                $noFM++
                $newContent = "---`r`nnav: `"$moc`"`r`n---`r`n`r`n" + $content
            }

            if (-not $DryRun) {
                [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.UTF8Encoding]::new($false))
            }
            $updated++

        } catch {
            $errors++
            Write-Output "ERROR: $($file.FullName) - $_"
        }
    }
}

Write-Output ""
Write-Output "=== Nav Backfill Summary ==="
Write-Output "  Updated:          $updated"
Write-Output "  Already had nav:  $skipped"
Write-Output "  Needed new FM:    $noFM"
Write-Output "  Errors:           $errors"
if ($DryRun) { Write-Output "  *** DRY RUN - no files written ***" }
