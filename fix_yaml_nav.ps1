# fix_yaml_nav.ps1
# Fixes YAML frontmatter where nav: lines contain unquoted | characters
# The | character has special meaning in YAML and must be quoted

param(
    # Path to the Obsidian vault
    [string]$VaultPath = "D:\Obsidian\Main",

    # Maximum number of files to process (0 = unlimited)
    [int]$Limit = 0,

    # If true, actually modify files. If false, just report what would be changed.
    [switch]$Fix,

    # If true, show verbose output for each file
    [switch]$Verbose
)

# Counter for statistics
$filesScanned = 0        # Total files scanned
$filesWithIssues = 0     # Files with broken nav: YAML
$filesFixed = 0          # Files actually fixed

# Array to store files with issues for reporting
$issueFiles = @()

# Get all markdown files in the vault
$mdFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File

Write-Host "Scanning for broken YAML nav: lines..." -ForegroundColor Cyan
Write-Host "Vault: $VaultPath" -ForegroundColor Gray
Write-Host ""

foreach ($file in $mdFiles) {
    # Check if we've hit the limit
    if ($Limit -gt 0 -and $filesScanned -ge $Limit) {
        break
    }

    $filesScanned++

    # Read the file content with UTF-8 encoding
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    # Skip empty files or files that couldn't be read
    if ([string]::IsNullOrEmpty($content)) {
        continue
    }

    # Skip files without YAML frontmatter
    if (-not $content.StartsWith("---")) {
        continue
    }

    # Find the end of YAML frontmatter
    $yamlEndIndex = $content.IndexOf("`n---", 3)
    if ($yamlEndIndex -eq -1) {
        # Try Windows line endings
        $yamlEndIndex = $content.IndexOf("`r`n---", 3)
    }

    if ($yamlEndIndex -eq -1) {
        continue
    }

    # Extract the YAML section
    $yamlSection = $content.Substring(0, $yamlEndIndex)

    # Check if there's a nav: line with an unquoted | character
    # Pattern: nav: followed by content containing | that isn't already quoted
    # We need to match lines like: nav: [[Link|Alias]| Something
    # But not lines like: nav: "[[Link|Alias]] | Something"
    # Uses negative lookahead to skip already-quoted values

    $navPattern = '(?m)^nav:\s*(?!["\x27])(\[\[.+\|.+)$'

    if ($yamlSection -match $navPattern) {
        $filesWithIssues++
        $matchedLine = $Matches[0]

        # Store for reporting
        $issueFiles += [PSCustomObject]@{
            Path = $file.FullName
            RelativePath = $file.FullName.Replace($VaultPath + "\", "")
            OriginalLine = $matchedLine
        }

        if ($Verbose -or -not $Fix) {
            Write-Host "Found: $($file.FullName.Replace($VaultPath + '\', ''))" -ForegroundColor Yellow
            Write-Host "  Line: $matchedLine" -ForegroundColor Gray
        }

        if ($Fix) {
            # Fix the nav: line by wrapping the value in quotes
            # Match: nav: <value with |>
            # Replace with: nav: "<value with |>"

            $fixedContent = $content -replace '(?m)^(nav:)\s*(\[\[.+)$', '$1 "$2"'

            # Also handle cases where there might be extra spaces or variations
            # Make sure we don't double-quote already quoted values

            # Write the fixed content back
            [System.IO.File]::WriteAllText($file.FullName, $fixedContent, [System.Text.UTF8Encoding]::new($false))

            $filesFixed++

            if ($Verbose) {
                Write-Host "  Fixed!" -ForegroundColor Green
            }
        }
    }
}

# Print summary
Write-Host ""
Write-Host "========== Summary ==========" -ForegroundColor Cyan
Write-Host "Files scanned: $filesScanned" -ForegroundColor White
Write-Host "Files with broken nav: $filesWithIssues" -ForegroundColor $(if ($filesWithIssues -gt 0) { "Yellow" } else { "Green" })

if ($Fix) {
    Write-Host "Files fixed: $filesFixed" -ForegroundColor Green
} else {
    if ($filesWithIssues -gt 0) {
        Write-Host ""
        Write-Host "Run with -Fix to apply changes" -ForegroundColor Magenta
    }
}
