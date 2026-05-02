# List files in each 01/ subdirectory for review
# Uses UTF-8 safe paths and LiteralPath for special chars

$dirs = @(
    "D:\Obsidian\Main\01\Bah`u00e1`u2019`u00ed",  # We'll resolve below
    "D:\Obsidian\Main\01\Social",
    "D:\Obsidian\Main\01\Technology",
    "D:\Obsidian\Main\01\Health",
    "D:\Obsidian\Main\01\NLP",
    "D:\Obsidian\Main\01\Science",
    "D:\Obsidian\Main\01\Music",
    "D:\Obsidian\Main\01\Home",
    "D:\Obsidian\Main\01\Travel",
    "D:\Obsidian\Main\01\FOL"
)

# Get all actual subdirectories of 01/
$allDirs = Get-ChildItem -LiteralPath "D:\Obsidian\Main\01" -Directory
foreach ($dir in $allDirs) {
    Write-Host "=== $($dir.Name) ===" -ForegroundColor Cyan
    # List .md files only (names)
    Get-ChildItem -LiteralPath $dir.FullName -Filter "*.md" |
        Select-Object -ExpandProperty Name |
        Sort-Object |
        ForEach-Object { Write-Host "  $_" }
    Write-Host ""
}
