# Script to move orphan clipping files to their correct vault subdirectories
# Uses char codes to avoid diacritic issues in inline PowerShell strings

# Build the Bah<U+00E1>'<U+00ED> folder path safely
$bahai = "C:\Users\awt\Sync\Obsidian\01\Bah" + [char]0x00e1 + "'" + [char]0x00ed

# Define source files and destinations
$moves = @(
    @{
        Src  = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Five Ways to Optimize the Powerful Tool of Baha'i Consultation.md"
        Dest = $bahai
    },
    @{
        Src  = "C:\Users\awt\Sync\Obsidian\10 - Clippings\How a `$300 Amish Earth Tube System Can Keep Your Home Cool at 55" + [char]0x00B0 + "F Year-Round Without Electricity.md"
        Dest = "C:\Users\awt\Sync\Obsidian\01\Home"
    },
    @{
        Src  = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Two Paths.md"
        Dest = "C:\Users\awt\Sync\Obsidian\01\Social"
    },
    @{
        Src  = "C:\Users\awt\Sync\Obsidian\10 - Clippings\Searching for Lee.md"
        Dest = "C:\Users\awt\Sync\Obsidian\01\Genealogy"
    }
)

foreach ($m in $moves) {
    $src  = $m.Src
    $dest = $m.Dest

    if (Test-Path -LiteralPath $src) {
        Move-Item -LiteralPath $src -Destination $dest -Force
        Write-Host "Moved: $src -> $dest"
    } else {
        Write-Host "NOT FOUND: $src"
    }
}

Write-Host "Done."
