# Fix remaining _1 files by copying content and deleting source
$Path = "D:\Obsidian\Main\20 - Permanent Notes"

# Get all _1 files
$files = Get-ChildItem -Path $Path -Filter "*_1.md" -ErrorAction SilentlyContinue

$fixed = 0

foreach ($file in $files) {
    if (-not $file.DirectoryName) { continue }
    if (-not ($file.BaseName -match '_1$')) { continue }

    $baseName = $file.BaseName -replace '_1$', ''
    $newPath = Join-Path $file.DirectoryName "$baseName.md"

    Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan

    # Read content from _1 file
    $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue

    # Write to target (overwrite if exists)
    Write-Host "  Writing content to: $baseName.md" -ForegroundColor Green
    Set-Content -LiteralPath $newPath -Value $content -NoNewline -Encoding UTF8 -Force

    # Delete source _1 file
    Write-Host "  Deleting: $($file.Name)" -ForegroundColor Yellow
    Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue

    $fixed++
}

Write-Host "`n========== SUMMARY ==========" -ForegroundColor Green
Write-Host "Files processed: $fixed"

# Check remaining
$remaining = Get-ChildItem -Path $Path -Filter "*_1.md" -ErrorAction SilentlyContinue
Write-Host "Remaining _1 files: $($remaining.Count)"
if ($remaining.Count -gt 0) {
    $remaining | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Red }
}
