# Delete files using 8.3 short names
$vaultPath = "D:\Obsidian\Main\00 - Images"

Write-Host "Finding .md files in .resources folders using short names..."

# Get short path for the vault
$fso = New-Object -ComObject Scripting.FileSystemObject

# Find .resources directories with long names
$resourceDirs = Get-ChildItem -Path $vaultPath -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '\.resources$' }

$deleted = 0
$failed = 0

foreach ($dir in $resourceDirs) {
    try {
        # Get files in this directory
        $mdFiles = Get-ChildItem -Path $dir.FullName -Filter "*.md" -File -ErrorAction SilentlyContinue

        foreach ($file in $mdFiles) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                $deleted++
            } catch {
                # Try using short path
                try {
                    $shortPath = $fso.GetFile($file.FullName).ShortPath
                    cmd /c "del /f `"$shortPath`" 2>nul"
                    if ($LASTEXITCODE -eq 0) {
                        $deleted++
                    } else {
                        $failed++
                    }
                } catch {
                    $failed++
                }
            }
        }
    } catch {
        # Directory itself may have long path issues
        continue
    }
}

# Now try the brute force approach - delete all .md in Evernote-Resources subfolders
Write-Host ""
Write-Host "Trying brute force deletion in Evernote-Resources..."

$paths = @(
    "D:\Obsidian\Main\00 - Images\Evernote-Resources",
    "D:\Obsidian\Main\00 - Images\Entertainment-_resources",
    "D:\Obsidian\Main\00 - Images\Food-_resources",
    "D:\Obsidian\Main\00 - Images\Politics-_resources",
    "D:\Obsidian\Main\00 - Images\Programming-_resources",
    "D:\Obsidian\Main\00 - Images\Science-_resources"
)

foreach ($basePath in $paths) {
    if (Test-Path $basePath) {
        # Use cmd del with wildcards in subdirectories
        cmd /c "for /r `"$basePath`" %f in (*.md) do del /f `"%f`" 2>nul"
    }
}

Write-Host ""
Write-Host "================================"
Write-Host "Files deleted: $deleted"
Write-Host "Failed: $failed"
Write-Host "================================"
