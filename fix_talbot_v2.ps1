<#
.SYNOPSIS
    Fixes the corrupted Talbot Heredity file by removing mojibake patterns.

.DESCRIPTION
    Uses character-by-character filtering to remove non-printable and
    corrupted characters while preserving readable text.
#>

# $inputPath: Path to the corrupted file
$inputPath = 'D:\Obsidian\Main\20 - Permanent Notes\Talbot Heredity - Living Descendants of Blood Royal.md'

# $backupPath: Path for backup
$backupPath = $inputPath + '.corrupted'

Write-Host "Reading corrupted file..." -ForegroundColor Yellow

# Read as bytes to avoid encoding issues
$bytes = [System.IO.File]::ReadAllBytes($inputPath)
Write-Host "Original file size: $($bytes.Length) bytes" -ForegroundColor Cyan

# Create backup of corrupted version
Write-Host "Creating backup at: $backupPath" -ForegroundColor Yellow
Copy-Item -Path $inputPath -Destination $backupPath -Force

# Convert to string for pattern matching
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

# $cleaned: Build clean content by removing garbage patterns
$cleaned = $content

# Pattern 1: Remove the main mojibake sequence (A followed by high-byte chars and punctuation)
# This pattern appears as: A��'A+'A��? etc.
$cleaned = $cleaned -replace "A[^\x00-\x7F]+'A\+'A[^\x00-\x7F]+\?[^\x00-\x7F\w]*", ""

# Pattern 2: Remove remaining high-byte sequences
$cleaned = $cleaned -replace "'A[^\x00-\x7F]+", ""

# Pattern 3: Remove isolated high-byte characters
$cleaned = $cleaned -replace "[^\x00-\x7F]{2,}", " "

# Pattern 4: Clean up A followed by special chars
$cleaned = $cleaned -replace "A[^\x00-\x7F]+", ""

# Pattern 5: Remove leftover special single chars
$cleaned = $cleaned -replace "[^\x00-\x7F]", ""

# Clean up excessive whitespace
$cleaned = $cleaned -replace '\s{3,}', ' '
$cleaned = $cleaned -replace '(\r?\n){3,}', "`n`n"
$cleaned = $cleaned -replace '^\s+', ''  # trim leading whitespace from lines

Write-Host "Cleaned file size: $($cleaned.Length) characters" -ForegroundColor Cyan
Write-Host "Removed $(($content.Length - $cleaned.Length)) characters of garbage" -ForegroundColor Green

# Show preview
Write-Host "`n--- Preview of cleaned content (first 3000 chars) ---" -ForegroundColor Magenta
$preview = $cleaned.Substring(0, [Math]::Min(3000, $cleaned.Length))
Write-Host $preview
Write-Host "--- End preview ---`n" -ForegroundColor Magenta

# Save the cleaned file
Write-Host "Saving cleaned file..." -ForegroundColor Yellow
[System.IO.File]::WriteAllText($inputPath, $cleaned, [System.Text.Encoding]::UTF8)
Write-Host "File saved successfully!" -ForegroundColor Green
Write-Host "Backup of corrupted version: $backupPath" -ForegroundColor Gray
