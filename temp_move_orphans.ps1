# Move classified orphan files to appropriate 01 subdirectories
$vault = 'D:\Obsidian\Main'

# Define moves: source -> destination directory
$moves = @(
    @{
        Source = "$vault\01\Home\Discover Kōlams, the.md"
        Dest   = "$vault\01\Social"
    },
    @{
        Source = "$vault\01\Music\2024-11-06.md"
        Dest   = "$vault\01\Social"
    },
    @{
        Source = "$vault\10 - Clippings\8 Best SMS Messaging Services for Small Businesses in 2026.md"
        Dest   = "$vault\01\Technology"
    },
    @{
        Source = "$vault\00 - Home Dashboard\PowerShell Support for Obsidian.md"
        Dest   = "$vault\01\PKM"
    }
)

foreach ($move in $moves) {
    $src = $move.Source
    $dst = $move.Dest
    $fileName = Split-Path $src -Leaf
    $destFile = Join-Path $dst $fileName

    if (Test-Path $src) {
        if (-not (Test-Path $dst)) {
            Write-Host "ERROR: Destination directory does not exist: $dst"
            continue
        }
        Move-Item -Path $src -Destination $destFile -Force
        Write-Host "MOVED: $fileName -> $dst"
    } else {
        Write-Host "ERROR: Source file not found: $src"
    }
}

Write-Host "`nDone."
