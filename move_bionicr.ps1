# Move BionicR contents up one level and fix links

param(
    [switch]$DryRun = $false
)

$vaultPath = 'D:\Obsidian\Main'
$bionicPath = Join-Path $vaultPath '11 - Evernote\BionicR'
$targetPath = Join-Path $vaultPath '11 - Evernote'

Write-Host "=== BionicR Migration ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

# Step 1: Count and list files
$allFiles = Get-ChildItem -Path $bionicPath -File -Recurse
$allDirs = Get-ChildItem -Path $bionicPath -Directory -Recurse
$mdFiles = $allFiles | Where-Object { $_.Extension -eq '.md' }

Write-Host "`nFiles in BionicR:"
Write-Host "  Total files: $($allFiles.Count)"
Write-Host "  Markdown files: $($mdFiles.Count)"
Write-Host "  Subdirectories: $($allDirs.Count)"

if ($allDirs.Count -gt 0) {
    Write-Host "  Subdirectories:"
    foreach ($dir in $allDirs) {
        Write-Host "    - $($dir.FullName.Replace($bionicPath + '\', ''))"
    }
}

# Step 2: Find all links referencing BionicR
Write-Host "`nSearching for links referencing BionicR..." -ForegroundColor Gray
$vaultMdFiles = Get-ChildItem -Path $vaultPath -Filter '*.md' -Recurse | Where-Object {
    $_.FullName -notmatch '\\\.obsidian|\\\.trash|\\\.smart-env'
}

$linkPattern = '\[\[([^\]]*BionicR[^\]]*)\]\]'
$filesWithLinks = @()
$totalLinksToFix = 0

foreach ($file in $vaultMdFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($content -and $content -match 'BionicR') {
        $matches = [regex]::Matches($content, $linkPattern)
        if ($matches.Count -gt 0) {
            $filesWithLinks += @{
                Path = $file.FullName
                LinkCount = $matches.Count
            }
            $totalLinksToFix += $matches.Count
        }
    }
}

Write-Host "Files with BionicR links: $($filesWithLinks.Count)"
Write-Host "Total links to fix: $totalLinksToFix"

# Step 3: Move files
Write-Host "`nMoving files..." -ForegroundColor Gray
$movedCount = 0

foreach ($file in $allFiles) {
    # Calculate relative path from BionicR
    $relativePath = $file.FullName.Replace($bionicPath + '\', '')
    $newPath = Join-Path $targetPath $relativePath
    $newDir = Split-Path $newPath -Parent

    # Create target directory if needed
    if (-not (Test-Path $newDir)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $newDir -Force | Out-Null
        }
        Write-Host "  Created directory: $newDir" -ForegroundColor DarkGray
    }

    # Check for existing file at target
    if (Test-Path $newPath) {
        Write-Host "  WARNING: File already exists: $relativePath" -ForegroundColor Yellow
        continue
    }

    if (-not $DryRun) {
        Move-Item -Path $file.FullName -Destination $newPath -Force
    }
    $movedCount++
}

Write-Host "Moved $movedCount files" -ForegroundColor Green

# Step 4: Fix links in all files
Write-Host "`nFixing links..." -ForegroundColor Gray
$fixedLinks = 0

foreach ($fileInfo in $filesWithLinks) {
    $content = Get-Content -Path $fileInfo.Path -Raw -Encoding UTF8
    $originalContent = $content

    # Replace BionicR paths - various patterns
    # Pattern 1: 11 - Evernote/BionicR/filename -> 11 - Evernote/filename
    $content = $content -replace '11 - Evernote/BionicR/', '11 - Evernote/'
    $content = $content -replace '11 - Evernote\\BionicR\\', '11 - Evernote/'

    # Pattern 2: BionicR/filename -> 11 - Evernote/filename (for relative links)
    $content = $content -replace '\[\[BionicR/', '[[11 - Evernote/'

    if ($content -ne $originalContent) {
        if (-not $DryRun) {
            Set-Content -Path $fileInfo.Path -Value $content -Encoding UTF8 -NoNewline
        }
        $fixedLinks++
        Write-Host "  Fixed links in: $($fileInfo.Path.Replace($vaultPath + '\', ''))" -ForegroundColor DarkGray
    }
}

Write-Host "Fixed links in $fixedLinks files" -ForegroundColor Green

# Step 5: Remove empty BionicR directory
if (-not $DryRun) {
    $remainingFiles = Get-ChildItem -Path $bionicPath -Recurse -File -ErrorAction SilentlyContinue
    if ($remainingFiles.Count -eq 0) {
        Remove-Item -Path $bionicPath -Recurse -Force
        Write-Host "`nRemoved empty BionicR directory" -ForegroundColor Green
    } else {
        Write-Host "`nWARNING: BionicR still has $($remainingFiles.Count) files" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Migration Complete ===" -ForegroundColor Cyan
Write-Host "Files moved: $movedCount"
Write-Host "Files with links fixed: $fixedLinks"
