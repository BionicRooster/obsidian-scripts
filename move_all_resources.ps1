# Find and move all "resources" or "_resources" folders to 00 - Images
$vaultPath = "D:\Obsidian\Main"
$destBase = "D:\Obsidian\Main\00 - Images"

# Find all directories named "resources" or "_resources"
Write-Host "Searching for resources folders..."
$resourceFolders = @()

# Use cmd /c dir to handle long paths better
$allDirs = cmd /c "dir /s /b /ad `"$vaultPath`" 2>nul" | Where-Object { $_ -match '\\(_resources|resources)$' }

foreach ($dir in $allDirs) {
    if (-not [string]::IsNullOrWhiteSpace($dir)) {
        $resourceFolders += $dir
    }
}

Write-Host "Found $($resourceFolders.Count) resources folder(s):"
foreach ($folder in $resourceFolders) {
    Write-Host "  - $folder"
}
Write-Host ""

$totalFiles = 0
$totalFolders = 0

foreach ($sourceFolder in $resourceFolders) {
    if ([string]::IsNullOrWhiteSpace($sourceFolder)) { continue }
    if (-not (Test-Path $sourceFolder -ErrorAction SilentlyContinue)) { continue }

    # Create a unique destination folder name based on parent path
    $relativePath = $sourceFolder.Replace($vaultPath, "").TrimStart("\")
    $parentName = Split-Path (Split-Path $sourceFolder -Parent) -Leaf
    $folderName = Split-Path $sourceFolder -Leaf

    # Create destination path
    $destFolder = Join-Path $destBase "$parentName-$folderName"

    Write-Host "Moving: $sourceFolder"
    Write-Host "    To: $destFolder"

    # Use robocopy to move (handles long paths)
    $robocopyArgs = @(
        "`"$sourceFolder`"",
        "`"$destFolder`"",
        "/E",
        "/MOVE",
        "/R:1",
        "/W:1",
        "/NFL",
        "/NDL",
        "/NP"
    )

    $process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -lt 8) {
        Write-Host "    Success!"

        # Count moved items
        $fileCount = (Get-ChildItem $destFolder -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        $folderCount = (Get-ChildItem $destFolder -Recurse -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
        $totalFiles += $fileCount
        $totalFolders += $folderCount

        # Try to remove empty source
        if (Test-Path $sourceFolder) {
            Remove-Item $sourceFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "    Warning: Some errors occurred (exit code: $($process.ExitCode))"
    }
    Write-Host ""
}

Write-Host "================================"
Write-Host "Total files moved: $totalFiles"
Write-Host "Total folders moved: $totalFolders"
