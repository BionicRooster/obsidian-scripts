# Copy Badí Calendar Class materials to vault
$src = "D:\Documents\Baha'i\Badí Calendar Class\Class Materials"
$dst = "D:\Obsidian\Main\00 - Images\BadíCalendarClass"

# Create destination if needed
New-Item -ItemType Directory -Path $dst -Force | Out-Null

# Copy PDFs, video, and image
$files = @(
    "Bahai-Dates-172-to-221-B-E-_UK-December-2014.pdf",
    "Chart of Calendars.pdf",
    "Days of Remembrance.pdf",
    "Nakhjavani Bahai Calendar.pdf",
    "Twin Holy Birthdays Bringing two calendars together.mp4",
    "Wayne Talbot In Bluebonnets Cropped.jpg"
)

foreach ($f in $files) {
    $srcPath = Join-Path $src $f
    $dstPath = Join-Path $dst $f
    if (Test-Path $srcPath) {
        Copy-Item $srcPath $dstPath
        Write-Host "Copied: $f"
    } else {
        Write-Host "NOT FOUND: $srcPath"
    }
}

Write-Host ""
Write-Host "Destination contents:"
Get-ChildItem $dst | Select-Object Name
