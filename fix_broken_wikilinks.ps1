# fix_broken_wikilinks.ps1
# Fixes broken wiki-link syntax where closing brackets are missing
# Example: [[Link|Alias] -> [[Link|Alias]]

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
$filesWithIssues = 0     # Files with broken wiki-links
$filesFixed = 0          # Files actually fixed
$totalIssues = 0         # Total broken links found

# Get all markdown files in the vault
$mdFiles = Get-ChildItem -Path $VaultPath -Filter "*.md" -Recurse -File

Write-Host "Scanning for broken wiki-link syntax..." -ForegroundColor Cyan
Write-Host "Vault: $VaultPath" -ForegroundColor Gray
Write-Host ""

foreach ($file in $mdFiles) {
    # Check if we've hit the limit
    if ($Limit -gt 0 -and $filesScanned -ge $Limit) {
        break
    }

    $filesScanned++

    # Read the file content with UTF-8 encoding
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    } catch {
        continue
    }

    # Skip empty files
    if ([string]::IsNullOrEmpty($content)) {
        continue
    }

    # Pattern to find wiki-links with only one closing bracket
    # Matches: [[something] followed by | or whitespace or end of content
    # Excludes: [[text]( which is a valid Markdown link format
    # This catches: [[Link] , [[Link|Alias]| , [[Link|Alias] text etc.
    $brokenLinkPattern = '\[\[([^\[\]]+)\]([^\]\(])'

    $matches = [regex]::Matches($content, $brokenLinkPattern)

    if ($matches.Count -gt 0) {
        $filesWithIssues++
        $totalIssues += $matches.Count

        $relativePath = $file.FullName.Replace($VaultPath + "\", "")

        if ($Verbose -or -not $Fix) {
            Write-Host "Found: $relativePath" -ForegroundColor Yellow
            foreach ($match in $matches) {
                # Show the broken link
                $brokenLink = $match.Value
                Write-Host "  Broken: $brokenLink" -ForegroundColor Gray
            }
        }

        if ($Fix) {
            # Fix all broken wiki-links by adding the missing closing bracket
            # Replace [[something]X with [[something]]X (where X is not ])
            $fixedContent = [regex]::Replace($content, $brokenLinkPattern, '[[$1]]$2')

            # Write the fixed content back with UTF-8 encoding (no BOM)
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
Write-Host "Files with broken links: $filesWithIssues" -ForegroundColor $(if ($filesWithIssues -gt 0) { "Yellow" } else { "Green" })
Write-Host "Total broken links: $totalIssues" -ForegroundColor $(if ($totalIssues -gt 0) { "Yellow" } else { "Green" })

if ($Fix) {
    Write-Host "Files fixed: $filesFixed" -ForegroundColor Green
} else {
    if ($filesWithIssues -gt 0) {
        Write-Host ""
        Write-Host "Run with -Fix to apply changes" -ForegroundColor Magenta
    }
}
