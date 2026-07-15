# List files in each 01/ subdirectory for review
# Uses UTF-8 safe paths and LiteralPath for special chars

$dirs = @(
    "C:\Users\awt\Sync\Obsidian\01\Bah`u00e1`u2019`u00ed",  # We'll resolve below
    "C:\Users\awt\Sync\Obsidian\01\Social",
    "C:\Users\awt\Sync\Obsidian\01\Technology",
    "C:\Users\awt\Sync\Obsidian\01\Health",
    "C:\Users\awt\Sync\Obsidian\01\NLP",
    "C:\Users\awt\Sync\Obsidian\01\Science",
    "C:\Users\awt\Sync\Obsidian\01\Music",
    "C:\Users\awt\Sync\Obsidian\01\Home",
    "C:\Users\awt\Sync\Obsidian\01\Travel",
    "C:\Users\awt\Sync\Obsidian\01\FOL"
)

# Get all actual subdirectories of 01/
$allDirs = Get-ChildItem -LiteralPath "C:\Users\awt\Sync\Obsidian\01" -Directory
foreach ($dir in $allDirs) {
    Write-Host "=== $($dir.Name) ===" -ForegroundColor Cyan
    # List .md files only (names)
    Get-ChildItem -LiteralPath $dir.FullName -Filter "*.md" |
        Select-Object -ExpandProperty Name |
        Sort-Object |
        ForEach-Object { Write-Host "  $_" }
    Write-Host ""
}
