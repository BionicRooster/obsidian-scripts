# read_classify.ps1 - Read recent notes for classification
# Each file read with UTF-8 encoding, first 40 lines shown

$files = @(
    'D:\Obsidian\Main\01\Bah??\All Religions Are One Bahai - Bahaullah.md',
    'D:\Obsidian\Main\01\Finance\IRS Wash Sale Rules.md',
    'D:\Obsidian\Main\01\Home\Simplifying Complex Ideas in Sketches.md',
    'D:\Obsidian\Main\01\Home\Build Your Panel of Advisors to Ask for Advice.md',
    'D:\Obsidian\Main\01\Technology\Digi-comp Esr and Evil Mad Scientist Items on eBay.md',
    'D:\Obsidian\Main\01\Bah??\Is World Peace Just a Pipe Dream.md',
    "D:\Obsidian\Main\01\Home\'Clean Freak' Shares 2-ingredient Solution to Eliminate Tile Grout 'Check Out This Before and After'.md"
)

# Find actual Baha'i folder name
$bahaiFolder = Get-ChildItem 'D:\Obsidian\Main\01' -Directory | Where-Object { $_.Name -match 'Bah' } | Select-Object -First 1 -ExpandProperty FullName

$files2 = @(
    (Join-Path $bahaiFolder 'All Religions Are One Bahai - Bahaullah.md'),
    'D:\Obsidian\Main\01\Finance\IRS Wash Sale Rules.md',
    'D:\Obsidian\Main\01\Home\Simplifying Complex Ideas in Sketches.md',
    'D:\Obsidian\Main\01\Home\Build Your Panel of Advisors to Ask for Advice.md',
    'D:\Obsidian\Main\01\Technology\Digi-comp Esr and Evil Mad Scientist Items on eBay.md',
    (Join-Path $bahaiFolder 'Is World Peace Just a Pipe Dream.md'),
    "D:\Obsidian\Main\01\Home\'Clean Freak' Shares 2-ingredient Solution to Eliminate Tile Grout 'Check Out This Before and After'.md"
)

foreach ($f in $files2) {
    Write-Host "`n=== $f ===" -ForegroundColor Cyan
    if (Test-Path $f) {
        Get-Content $f -Encoding UTF8 | Select-Object -First 30
    } else {
        Write-Host "NOT FOUND: $f" -ForegroundColor Red
    }
}
