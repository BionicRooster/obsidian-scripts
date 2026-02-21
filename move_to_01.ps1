# Move unclassified notes to appropriate 01 subdirectories
$vault = 'D:\Obsidian\Main'

# Define moves: source relative path => destination relative path
$moves = @(
    @{ From = '10 - Clippings\Eye Day.md'; To = '01\Health\Eye Day.md' },
    @{ From = '10 - Clippings\Mathematics in Everyday Life.md'; To = '01\Home\Mathematics in Everyday Life.md' },
    @{ From = '10 - Clippings\Several Ice Agents Were Arrested in Recent Months, Showing Risk of Misconduct.md'; To = '01\Social\Several Ice Agents Were Arrested in Recent Months, Showing Risk of Misconduct.md' },
    @{ From = '10 - Clippings\Trump Administration Working to Expand Effort to Strip Citizenship from Foreign-born Americans.md'; To = '01\Social\Trump Administration Working to Expand Effort to Strip Citizenship from Foreign-born Americans.md' },
    @{ From = '10 - Clippings\Why Some People Think in Words, While Others Think in Pictures & Feelings.md'; To = '01\NLP_Psy\Why Some People Think in Words, While Others Think in Pictures & Feelings.md' },
    @{ From = '10 - Clippings\Williamson Tax  Property Detail.md'; To = '01\Home\Williamson Tax  Property Detail.md' },
    @{ From = "20 - Permanent Notes\After Shoghi Effendi -  Guardianship, Lineage, and the Limits of Claim.md"; To = "01\Bah$(([char]0x00E1))'$(([char]0x00ED))\After Shoghi Effendi -  Guardianship, Lineage, and the Limits of Claim.md" },
    @{ From = '20 - Permanent Notes\Black August.md'; To = '01\Social\Black August.md' },
    @{ From = '20 - Permanent Notes\Implementation for SMS MMS Service.md'; To = '01\Technology\Implementation for SMS MMS Service.md' },
    @{ From = '20 - Permanent Notes\Obsidian Won the PKM Wars.md'; To = '01\PKM\Obsidian Won the PKM Wars.md' },
    @{ From = '20 - Permanent Notes\Recommendation for SMS MMS Service.md'; To = '01\Technology\Recommendation for SMS MMS Service.md' },
    @{ From = '20 - Permanent Notes\Software Tools.md'; To = '01\Technology\Software Tools.md' }
)

# Get the actual Baha'i folder name
$bahaiFolder = Get-ChildItem -Path "$vault\01" -Directory | Where-Object { $_.Name -match 'Bah' }
if ($bahaiFolder) {
    Write-Host "Found Baha'i folder: $($bahaiFolder.Name)"
    # Fix the Baha'i entry
    for ($i = 0; $i -lt $moves.Count; $i++) {
        if ($moves[$i].From -match 'After Shoghi') {
            $moves[$i].To = "01\$($bahaiFolder.Name)\After Shoghi Effendi -  Guardianship, Lineage, and the Limits of Claim.md"
        }
    }
}

$moved = 0
$errors = 0

foreach ($m in $moves) {
    $src = Join-Path $vault $m.From
    $dst = Join-Path $vault $m.To

    if (-not (Test-Path $src)) {
        Write-Host "SKIP (not found): $($m.From)"
        continue
    }

    if (Test-Path $dst) {
        Write-Host "SKIP (already exists): $($m.To)"
        continue
    }

    try {
        Move-Item -Path $src -Destination $dst -ErrorAction Stop
        Write-Host "MOVED: $($m.From) -> $($m.To)"
        $moved++
    } catch {
        Write-Host "ERROR: $($m.From) -> $($_.Exception.Message)"
        $errors++
    }
}

Write-Host ""
Write-Host "Done. Moved: $moved, Errors: $errors"
