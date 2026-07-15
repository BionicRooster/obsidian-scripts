# Bulk move script for classified clippings 2026-03-31
# All files move from 10 - Clippings to their 01/ subdirectory

$vault = "C:\Users\awt\Sync\Obsidian"
$src = "$vault\10 - Clippings"

# Helper: move a file using LiteralPath to handle special characters
function Move-Clipping {
    param($name, $dest)
    $srcPath = Join-Path $src $name
    $destDir = Join-Path $vault $dest
    if (Test-Path -LiteralPath $srcPath) {
        Move-Item -LiteralPath $srcPath -Destination $destDir -Force
        Write-Host "OK: $name -> $dest"
    } else {
        Write-Host "MISSING: $name"
    }
}

# --- Technology ---
$tech = "01\Technology"
Move-Clipping "Z80 retrocomputing 11 - CPM on the RC2014 - Dr. Scott M. Baker.md" $tech
Move-Clipping "Z80 Retrocomputing 5 - Single Stepper for RC2014 - Dr. Scott M. Baker.md" $tech
Move-Clipping "Z80 Retrocomputing 6 - RC2014 TIL311 Front Panel Board - Dr. Scott M. Baker.md" $tech
Move-Clipping "RC 2014 First Time Use.md" $tech
Move-Clipping "Simple Guide To Getting CP_M Running On RC2014.md" $tech
Move-Clipping "RC2014 FTDI Cable Pinout.md" $tech
Move-Clipping "My Z80 System.md" $tech
Move-Clipping "CPM Operating System Internals.md" $tech
Move-Clipping "CPM commands.md" $tech
Move-Clipping "CPM Builtin Commands.md" $tech
Move-Clipping "Installing CP_M Applications.md" $tech
Move-Clipping "How to start with CPM.md" $tech
Move-Clipping "Introduction to CPM.md" $tech
Move-Clipping "BCR TTL SERIAL HACK - Bitchin100 DocGarden.md" $tech
Move-Clipping "M100 how to get portable disk running, came without disk or cable_.md" $tech
Move-Clipping "Recovering an Unresponsive RadioShack Model 100 Laptop.md" $tech
Move-Clipping "Club 100_ A Model 100 User Group.md" $tech
Move-Clipping "Here's how RadioShack sold its breakthrough laptop circa 1983.md" $tech
Move-Clipping "Altair-Duino - the low-cost Altair 8800.md" $tech
Move-Clipping "Fujitsu Has an Employee Who Keeps a 1959 Computer Running.md" $tech
Move-Clipping "Digi-Comp II Replica.md" $tech
Move-Clipping "Digirule 2, 2A and 2U - Brads Electronic Projects.md" $tech
Move-Clipping "PiDP8 receipt.md" $tech
Move-Clipping "Tech ExplorationsT KiCad like a Professional.md" $tech
Move-Clipping "How to Make a UART-to-Cassette-Tape Interface.md" $tech
Move-Clipping "How to Work with I2C Communication in Raspberry Pi.md" $tech
Move-Clipping "How do I power my Raspberry Pi.md" $tech
Move-Clipping "Raspberry Pi GPIO Pinout.md" $tech
Move-Clipping "GPIO Zero v1.5 is here! - Raspberry Pi.md" $tech
Move-Clipping "DIY Swarmbots.md" $tech
Move-Clipping "Lack Rack.md" $tech
Move-Clipping "Paperless for Windows.md" $tech
Move-Clipping "Macro Express 5.md" $tech
Move-Clipping "Icon Packager, CursorFX, WindowBlinds License keys.md" $tech
Move-Clipping "Microsoft Office 2024 Professional Plus keys.md" $tech
Move-Clipping "Restore old Right-click Context menu in Windows 11 - Microsoft Community.md" $tech
Move-Clipping "Tivo upgrade and new box.md" $tech
Move-Clipping "Assistant DBA.md" $tech
Move-Clipping "Free AI Photo Restoration - Repair Old Photos Online.md" $tech
Move-Clipping "DIR ITPS phones.md" $tech

# Brian K. White email — has special character in filename, find it by partial match
$brianFile = Get-ChildItem -Path $src | Where-Object { $_.Name -like "Brian K. White*" } | Select-Object -First 1
if ($brianFile) {
    Move-Item -LiteralPath $brianFile.FullName -Destination (Join-Path $vault $tech) -Force
    Write-Host "OK: $($brianFile.Name) -> $tech"
} else {
    Write-Host "MISSING: Brian K. White email file"
}

# --- Health ---
$health = "01\Health"
Move-Clipping "Infant Respiratory Distress Syndrome (Hyaline Membrane Disease).md" $health
Move-Clipping "Frontiers _ Predicting Lung Health Trajectories for Survivors of Preterm Birth _ Pediatrics.md" $health
Move-Clipping "Young adults born preterm may live with lungs of elderly -- ScienceDaily.md" $health
Move-Clipping "Lung consequences in adults born prematurely _ Thorax.md" $health
Move-Clipping "Adults Born Premature Have Lung Limitations Similar to Patients With Chronic Obstructive Pulmonary Disease.md" $health

# --- Bahá'í (use LiteralPath for diacritic filenames) ---
$bahai = "01\Bahá'í"

# Prayer for Dead - use LiteralPath
$prayerFile = Get-ChildItem -Path $src | Where-Object { $_.Name -like "Bah*Prayer*" } | Select-Object -First 1
if ($prayerFile) {
    Move-Item -LiteralPath $prayerFile.FullName -Destination (Join-Path $vault $bahai) -Force
    Write-Host "OK: $($prayerFile.Name) -> $bahai"
} else {
    Write-Host "MISSING: Baha'i Prayer file"
}

# Intro to Bahá'í Faith
$introFile = Get-ChildItem -Path $src | Where-Object { $_.Name -like "Intro to Bah*" } | Select-Object -First 1
if ($introFile) {
    Move-Item -LiteralPath $introFile.FullName -Destination (Join-Path $vault $bahai) -Force
    Write-Host "OK: $($introFile.Name) -> $bahai"
} else {
    Write-Host "MISSING: Intro to Baha'i Faith"
}

Move-Clipping "Ruth Kronick Funeral  (Allen).md" $bahai

# --- Social ---
$social = "01\Social"
Move-Clipping "Trump's Magical Thinking.md" $social
Move-Clipping "The Coronavirus Revealed America's Failures - The Atlantic.md" $social
Move-Clipping "Matthew 7_16-23 KJV - Ye shall know them by their fruits. Do - Bible Gateway.md" $social
Move-Clipping "Matthew 7_16-23 KJV - Ye shall know them by their fruits. Do - Bible Gateway_2.md" $social

# --- Science ---
$science = "01\Science"
Move-Clipping "'Forest gardens' show how Native land stewardship can outdo nature.md" $science

# --- Music ---
$music = "01\Music"
Move-Clipping "Musician Leon Redbone dies aged 69.md" $music

# --- Recipes ---
$recipes = "01\Recipes"
Move-Clipping "BANANA EVERYTHING COOKIES.md" $recipes

# --- Home / Practical ---
$home = "01\Home"
Move-Clipping "How to Fix Corroded Battery Terminals.md" $home
Move-Clipping "The Good Cemeterian.md" $home
Move-Clipping "Photos Wreck 2020-02-21.md" $home
Move-Clipping "WCWBF 2021-08-12 03_58 PM Advisory Committee.md" $home

Write-Host "`nDone."
