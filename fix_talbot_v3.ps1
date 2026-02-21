<#
.SYNOPSIS
    Final cleanup of Talbot Heredity file - removes leftover apostrophe/space patterns.
#>

# $inputPath: Path to the file
$inputPath = 'D:\Obsidian\Main\20 - Permanent Notes\Talbot Heredity - Living Descendants of Blood Royal.md'

Write-Host "Reading file..." -ForegroundColor Yellow
$content = Get-Content -Path $inputPath -Raw -Encoding UTF8
Write-Host "Current file size: $($content.Length) characters" -ForegroundColor Cyan

# $cleaned: Remove the leftover apostrophe/space/dot patterns
$cleaned = $content

# Pattern: sequences of apostrophes, spaces, and dots
$cleaned = $cleaned -replace "('\s*)+", " "
$cleaned = $cleaned -replace "(\.\.\.\s*)+", " "
$cleaned = $cleaned -replace "\s*'\s*'\s*", " "

# Clean up multiple spaces
$cleaned = $cleaned -replace '\s{2,}', ' '

# Clean up lines that are mostly whitespace
$cleaned = $cleaned -replace '(?m)^\s+$', ''

# Clean up multiple blank lines
$cleaned = $cleaned -replace '(\r?\n){3,}', "`n`n"

# Remove leading/trailing whitespace from each line
$lines = $cleaned -split "`n"
$lines = $lines | ForEach-Object { $_.Trim() }
$cleaned = $lines -join "`n"

# Remove empty lines at start
$cleaned = $cleaned -replace '^[\r\n]+', ''

Write-Host "Cleaned file size: $($cleaned.Length) characters" -ForegroundColor Cyan
Write-Host "Removed $($content.Length - $cleaned.Length) characters" -ForegroundColor Green

# Show preview
Write-Host "`n--- Preview of cleaned content (first 3000 chars) ---" -ForegroundColor Magenta
$preview = $cleaned.Substring(0, [Math]::Min(3000, $cleaned.Length))
Write-Host $preview
Write-Host "--- End preview ---`n" -ForegroundColor Magenta

# Save
Write-Host "Saving..." -ForegroundColor Yellow
[System.IO.File]::WriteAllText($inputPath, $cleaned, [System.Text.Encoding]::UTF8)
Write-Host "Done!" -ForegroundColor Green
