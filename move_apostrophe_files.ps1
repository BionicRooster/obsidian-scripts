# Move two 10-Clippings files with smart apostrophes (U+2019) in their names
# Step 1: Find and rename in-place, Step 2: Move to destination

$clippings = 'C:\Users\awt\Sync\Obsidian\10 - Clippings'
$socialDest = 'C:\Users\awt\Sync\Obsidian\01\Social'
$techDest   = 'C:\Users\awt\Sync\Obsidian\01\Technology'

# Define the two target files and their destinations
$targets = @(
    @{
        Pattern = "Mitch Landrieu"
        Dest    = $socialDest
    },
    @{
        Pattern = "Programming Principles"
        Dest    = $techDest
    }
)

foreach ($t in $targets) {
    # Find the file matching the pattern (may have smart apostrophe in name)
    $file = Get-ChildItem -Path $clippings -Filter '*.md' | Where-Object { $_.Name -like "*$($t.Pattern)*" } | Select-Object -First 1

    if ($null -eq $file) {
        Write-Output "NOT FOUND: pattern '$($t.Pattern)'"
        continue
    }

    Write-Output "Found: $($file.Name)"

    # Replace smart apostrophe (U+2019) with standard apostrophe in filename
    $newName = $file.Name -replace [char]0x2019, "'"

    if ($newName -ne $file.Name) {
        # Rename in-place using two-step to avoid Windows case-insensitive collision
        $tempName = $file.Name + '.tmp'
        Rename-Item -LiteralPath $file.FullName -NewName $tempName
        $tempPath = Join-Path $clippings $tempName
        Rename-Item -LiteralPath $tempPath -NewName $newName
        Write-Output "Renamed to: $newName"
    } else {
        Write-Output "No smart apostrophe found in name, skipping rename"
    }

    # Move to destination
    $sourcePath = Join-Path $clippings $newName
    $destPath   = Join-Path $t.Dest $newName

    if (Test-Path $destPath) {
        Write-Output "SKIPPED (already exists at dest): $newName"
    } else {
        Move-Item -LiteralPath $sourcePath -Destination $t.Dest
        Write-Output "Moved to: $($t.Dest)"
    }
}

Write-Output "Done."
