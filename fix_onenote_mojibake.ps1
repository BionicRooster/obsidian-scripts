# PowerShell script to fix mojibake in OneNote folder files
# Fixes multi-encoded apostrophes, quotes, and special characters

$VaultPath = "D:\Obsidian\Main\12 - OneNote"

# Common mojibake patterns and their replacements
# These are multi-encoded UTF-8 characters that need to be fixed
$replacements = @{
    # Apostrophe patterns (')
    "ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢" = "'"

    # Half character (½)
    "ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â½" = "½"

    # Three-quarters character (¾)
    "ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¾" = "¾"

    # One-quarter character (¼)
    "ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬ ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã†'Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã¢â‚¬ 'ÃƒÆ'Ã†'Ãƒâ€šÃ‚Â¢ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ'Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ'Ã†'Ãƒâ€ 'ÃƒÆ'Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ'Ã†'ÃƒÂ¢Ã¢â€šÂ¬Ã...Â¡ÃƒÆ'Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¼" = "¼"
}

# Get all markdown files in OneNote folder
$files = Get-ChildItem -Path $VaultPath -Recurse -Filter "*.md"

$totalFixed = 0
$filesModified = 0

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $modified = $false

    # Check for any mojibake pattern (ÃƒÆ)
    if ($content -match "ÃƒÆ") {
        # Apply known replacements
        foreach ($pattern in $replacements.Keys) {
            if ($content.Contains($pattern)) {
                $content = $content.Replace($pattern, $replacements[$pattern])
                $modified = $true
                $totalFixed++
            }
        }

        # If still contains mojibake, try to fix remaining patterns
        # This regex matches the common multi-encoded pattern prefix
        $remainingPattern = "ÃƒÆ'[^'""½¾¼]*"
        $matches = [regex]::Matches($content, $remainingPattern)

        if ($matches.Count -gt 0 -and $modified -eq $false) {
            Write-Host "File still has unrecognized mojibake: $($file.FullName)" -ForegroundColor Yellow
        }

        if ($modified) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
            $filesModified++
            Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Files scanned: $($files.Count)"
Write-Host "Files modified: $filesModified"
Write-Host "Total patterns fixed: $totalFixed"
