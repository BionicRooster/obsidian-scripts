# Quick test script to run just Phase 20
$vaultPath = "D:\Obsidian\Main"
$dryRun = $false

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Path to MOC files
$mocPath = Join-Path $vaultPath "00 - Home Dashboard"
$filesFixed = 0
$totalFixed = 0

# Get all MOC markdown files
$mocFiles = Get-ChildItem -Path $mocPath -Filter "*MOC*.md" -ErrorAction SilentlyContinue

Write-Host "Checking $($mocFiles.Count) MOC files" -ForegroundColor Yellow

foreach ($file in $mocFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    if ([string]::IsNullOrEmpty($content)) { continue }

    $relativePath = $file.Name

    # Pattern: line starting with - followed immediately by [[ (no space)
    $bulletPattern = '(?m)^-(\[\[)'

    $matches = [regex]::Matches($content, $bulletPattern)

    if ($matches.Count -gt 0) {
        $totalFixed += $matches.Count

        # Fix by adding space after the dash
        $fixedContent = $content -replace $bulletPattern, '- $1'

        # Write the fixed content back with UTF-8 encoding (no BOM)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($file.FullName, $fixedContent, $utf8NoBom)

        $filesFixed++
        Write-Host "  Fixed $($matches.Count) bullet point(s) in: $relativePath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Fixed $totalFixed bullet points in $filesFixed MOC files" -ForegroundColor Cyan
