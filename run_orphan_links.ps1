# Batch orphan linker — 42 files approved 2026-07-14
# Skips: 3 system files + 3 files in 11 - Review

$script = "C:\Users\awt\moc_orphan_linker.ps1"  # path to the linker script

# MOC paths
$moc_bahai   = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Bahá'í Faith.md"
$moc_pkm     = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Personal Knowledge Management.md"
$moc_health  = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Health & Nutrition.md"
$moc_home    = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Home & Practical Life.md"
$moc_music   = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Music & Record.md"
$moc_nlp     = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - NLP & Psychology.md"
$moc_reading = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Reading & Literature.md"
$moc_social  = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Social Issues.md"
$moc_tech    = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Technology & Computers.md"
$moc_travel  = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Travel & Exploration.md"
$moc_genea   = "C:\Users\awt\Sync\Obsidian\00 - Home Dashboard\MOC - Genealogy.md"

# Base vault path
$vault = "C:\Users\awt\Sync\Obsidian"

# Each entry: OrphanPath, MOCPath, SubsectionName
$links = @(
    # Bahá'í Faith — Daily Quotes (19)
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2024-03.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2024-04.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2024-06.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2024-07.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2024-08.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2024-09.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2024-10.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2024-12.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2025-01.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2025-02.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2025-03.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2025-06.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2025-07.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2025-08.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2025-09.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2025-12.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2026-02.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2026-03.md";  M = $moc_bahai; S = "Daily Quotes" },
    @{ O = "$vault\01\Bahá'í\Daily Quotes\2026-07.md";  M = $moc_bahai; S = "Daily Quotes" },

    # Bahá'í Faith — other subsections
    @{ O = "$vault\01\Bahá'í\20210603 NSA Call to Action.md";        M = $moc_bahai; S = "Administrative Guidance" },
    @{ O = "$vault\01\Bahá'í\Bahá'í -  Life on Other Planets.md";   M = $moc_bahai; S = "Core Teachings" },
    @{ O = "$vault\30 - Synthesis\Bahai Prayer — Practice and Theology.md"; M = $moc_bahai; S = "Synthesis Pages" },

    # Health & Nutrition
    @{ O = "$vault\01\Health\Re_ We Know the Answer to This Question_.md"; M = $moc_health; S = "Health Articles & Clippings" },

    # Home & Practical Life
    @{ O = "$vault\01\Home\If This Isnt Nice I Dont Know What Is.md";  M = $moc_home; S = "Sketchplanations" },
    @{ O = "$vault\01\Home\Little Openings.md";                         M = $moc_home; S = "Sketchplanations" },
    @{ O = "$vault\01\Home\Every Time Zone Converter.md";               M = $moc_home; S = "Cool Tools" },
    @{ O = "$vault\01\Home\Get a Replacement Voter Registration Card.md"; M = $moc_home; S = "Practical Tips & Life Hacks" },
    @{ O = "$vault\01\Home\Support Now Chat About Overcharging.md";      M = $moc_home; S = "Practical Tips & Life Hacks" },
    @{ O = "$vault\01\Home\Top 7 Wood Corner Joinery Techniques by a 65-Year-Old Carpenter That Amazed Millions.md"; M = $moc_home; S = "Home Projects & Repairs" },
    @{ O = "$vault\01\Home\WCWBF 2021-08-12 03_58 PM Advisory Committee.md"; M = $moc_home; S = "Georgetown Cultural Citizens Memorial Association" },

    # Music & Record
    @{ O = "$vault\01\Music\New in Top Free MP3 Albums_ #10_ Praise His Name.md"; M = $moc_music; S = "Music Performances & Articles" },

    # NLP & Psychology
    @{ O = "$vault\01\NLP\NLP Forum — Taste #2 Alt.psy.nlp (December 1994).md"; M = $moc_nlp; S = "CompuServe Forum Threads (1995)" },
    @{ O = "$vault\02 - Working Projects\Book\Chapter 02 - How We Come to Believe What We Believe.md"; M = $moc_nlp; S = "Book Projects" },

    # Reading & Literature
    @{ O = "$vault\01\Reading\Microfiction #6_ The Good People – Jim Butcher.md"; M = $moc_reading; S = "Chrome/Web Clippings" },

    # Social Issues
    @{ O = "$vault\01\Religion\Anthony Flaccavento - Obama Santorum and Religion.md"; M = $moc_social; S = "Religion & Society" },
    @{ O = "$vault\01\Social\Conversation with an Expert on Race.md";                  M = $moc_social; S = "Race & Equity" },
    @{ O = "$vault\01\Social\Did Trump Administration Fire the US Pandemic Response Team.md"; M = $moc_social; S = "Justice & Politics" },
    @{ O = "$vault\01\Social\Psst What No One Will Tell You About the National Debt (But I Will).md"; M = $moc_social; S = "Justice & Politics" },

    # Technology & Computers
    @{ O = "$vault\01\Technology\Install Windows 11 on Unsupported Hardware Using Rufus.md"; M = $moc_tech; S = "Troubleshooting & Guides" },
    @{ O = "$vault\01\Technology\Re_ Will Replicas Muddy the Waters of Collectability_.md";  M = $moc_tech; S = "Retrocomputing" },

    # Travel & Exploration
    @{ O = "$vault\01\Travel\Two Winters in a Tip.md"; M = $moc_travel; S = "RV & Alternative Living" },

    # Genealogy
    @{ O = "$vault\02 - Working Projects\Land of Good Water.md"; M = $moc_genea; S = "Resources & How-Tos" }
)

# Track results
$success = 0  # count of successful links
$failed  = @()  # list of failed file names

foreach ($link in $links) {
    Write-Host "Linking: $($link.O | Split-Path -Leaf) → $($link.S)" -ForegroundColor Cyan
    $result = powershell -ExecutionPolicy Bypass -File $script `
        -Action link-orphan `
        -OrphanPath $link.O `
        -MOCPath $link.M `
        -SubsectionName $link.S 2>&1

    if ($LASTEXITCODE -eq 0) {
        $success++
        Write-Host "  OK" -ForegroundColor Green
    } else {
        $failed += $link.O | Split-Path -Leaf
        Write-Host "  FAILED: $result" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== DONE: $success linked, $($failed.Count) failed ===" -ForegroundColor Yellow
if ($failed.Count -gt 0) {
    Write-Host "Failed files:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
