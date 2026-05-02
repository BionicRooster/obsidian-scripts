# Script to list and read recent clippings files
$clippings = "D:\Obsidian\Main\10 - Clippings"

# List files with Forest in name
$files = Get-ChildItem $clippings | Where-Object { $_.Name -like "*Forest*" -or $_.Name -like "*forest*" }
foreach ($f in $files) { Write-Host "FOUND: $($f.FullName)" }

# Read all recent files and output their full paths and content
$recent = @(
    "Greenscreen backdrop folding instructions.md",
    "The Daniel Norris Code for Success - The Simple Dollar.md",
    "Bloom's Taxonomy of Learning.md",
    "Clean Air Floor Removal.md",
    "Contracting with DIR.md",
    "Do liberals want to destroy America.md",
    "A Fan Asks Mike Rowe For Career Advice...He Didn't Expect This Response, But It's Brilliant.md",
    "Me and Jo Photo H.md",
    "Me and Jo photo h1.md",
    "Uni Kuru Toga - The Best Pencil in the World.md",
    "How Clutter Affects Your Brain (and What You Can Do About It).md",
    "Obituary - John Henry White.md",
    "Matthew Talbot Ancestry.md",
    "Col Mathew Talbot  1699-1758.md",
    "Alfred W. Talbot Sr Military record.md",
    "Vera Irene Talbot - Intellus.md",
    "AC Waldrep.md",
    "Lee Etta Stanard.md",
    "Matthew Talbot 01.md"
)

foreach ($name in $recent) {
    $path = Join-Path $clippings $name
    if (Test-Path $path) {
        Write-Host "=== FILE: $path ==="
        Get-Content $path -Encoding UTF8 | Select-Object -First 30 | ForEach-Object { Write-Host $_ }
        Write-Host "---END---"
    } else {
        Write-Host "=== MISSING: $name ==="
    }
}
