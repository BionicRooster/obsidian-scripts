# Script to remove the Unicode replacement character (U+FFFD) from markdown files
# The replacement character "�" appears when encoding fails

param(
    [string]$Path = "D:\Obsidian\Main",  # Directory to scan
    [switch]$DryRun                       # Preview changes without saving
)

# The replacement character (U+FFFD, code 65533)
$replacementChar = [char]0xFFFD

Write-Host "Scanning for files containing replacement character..." -ForegroundColor Cyan

# Find all markdown files recursively
$files = Get-ChildItem -Path $Path -Filter "*.md" -Recurse -File

# Track affected files
$affectedFiles = @()

foreach ($file in $files) {
    # Read file content
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    }
    catch {
        Write-Host "  Error reading: $($file.FullName)" -ForegroundColor Red
        continue
    }

    # Check if file contains the replacement character
    if ($content.Contains($replacementChar)) {
        # Count occurrences
        $count = ($content.ToCharArray() | Where-Object { $_ -eq $replacementChar }).Count
        $affectedFiles += @{
            Path = $file.FullName
            Count = $count
            Content = $content
        }
    }
}

Write-Host ""
Write-Host "Found $($affectedFiles.Count) files with replacement character" -ForegroundColor Yellow
Write-Host ""

if ($affectedFiles.Count -eq 0) {
    Write-Host "No files need fixing!" -ForegroundColor Green
    exit 0
}

# Display affected files
$index = 1
foreach ($file in $affectedFiles) {
    $relativePath = $file.Path.Replace($Path, "").TrimStart("\", "/")
    Write-Host "  [$index] $relativePath - $($file.Count) occurrence(s)" -ForegroundColor White
    $index++
}

Write-Host ""

# Fix the files
$fixed = 0
foreach ($file in $affectedFiles) {
    # Remove the replacement character
    $newContent = $file.Content -replace $replacementChar, ""

    # Also clean up any resulting double spaces
    $newContent = $newContent -replace "  +", " "

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would fix: $($file.Path)" -ForegroundColor Yellow
    }
    else {
        # Write the cleaned content back
        try {
            [System.IO.File]::WriteAllText($file.Path, $newContent, [System.Text.Encoding]::UTF8)
            Write-Host "  Fixed: $($file.Path)" -ForegroundColor Green
            $fixed++
        }
        catch {
            Write-Host "  Error writing: $($file.Path) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host "Dry run complete. Run without -DryRun to apply changes." -ForegroundColor Cyan
}
else {
    Write-Host "Fixed $fixed files!" -ForegroundColor Green
}
