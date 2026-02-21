# Move reformatted notes to appropriate 01 subdirectories
$vault = "D:\Obsidian\Main"

# Define moves: source filename -> destination subfolder
$moves = @(
    @{ Source = "Grants for Gravestones.md"; Dest = "01\Genealogy" },
    @{ Source = "health advantages of Rooibos Tea.md"; Dest = "01\Health" },
    @{ Source = "Portland vs Vancouver.md"; Dest = "01\Travel" },
    @{ Source = "The Barren Grounds Book Synopsis.md"; Dest = "01\Reading" },
    @{ Source = "What is Curry.md"; Dest = "01\Recipes" }
)

$moved = 0
$errors = 0

foreach ($m in $moves) {
    $srcPath = Join-Path $vault $m.Source
    $destDir = Join-Path $vault $m.Dest
    $destPath = Join-Path $destDir $m.Source

    if (-not (Test-Path $srcPath)) {
        Write-Output "SKIP: $($m.Source) - source not found"
        continue
    }

    if (-not (Test-Path $destDir)) {
        Write-Output "ERROR: Destination folder not found: $($m.Dest)"
        $errors++
        continue
    }

    try {
        Move-Item -Path $srcPath -Destination $destPath -Force
        Write-Output "MOVED: $($m.Source) -> $($m.Dest)"
        $moved++
    } catch {
        Write-Output "ERROR moving $($m.Source): $($_.Exception.Message)"
        $errors++
    }
}

# Now fix title case on 'health advantages of Rooibos Tea.md'
$oldName = Join-Path $vault "01\Health\health advantages of Rooibos Tea.md"
$tempName = Join-Path $vault "01\Health\TEMP_rooibos_rename.md"
$newName = Join-Path $vault "01\Health\Health Advantages of Rooibos Tea.md"

if (Test-Path $oldName) {
    # Two-step rename for Windows case-insensitive filesystem
    Move-Item -Path $oldName -Destination $tempName -Force
    Move-Item -Path $tempName -Destination $newName -Force
    Write-Output "RENAMED: health advantages of Rooibos Tea.md -> Health Advantages of Rooibos Tea.md"
}

Write-Output "`nDone: $moved moved, $errors errors"
