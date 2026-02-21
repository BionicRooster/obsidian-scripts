# fetch_recipe_urls.ps1
# Fetches recipe URLs and creates/updates recipe files in Obsidian vault

param(
    # Path to the URLs file
    [string]$UrlsFile = "D:\Obsidian\Main\04 - GMail\_recipe_urls_to_fetch.txt",

    # Destination folder for recipe files
    [string]$RecipeFolder = "D:\Obsidian\Main\03 - Recipes",

    # Maximum number of URLs to fetch (0 = all)
    [int]$Limit = 10,

    # Skip the first N URLs
    [int]$Skip = 0,

    # If set, only show what would be done
    [switch]$DryRun
)

# Claude Code will need to process URLs using WebFetch
# This script outputs the URLs that need to be fetched

Write-Host "Recipe URL Fetcher" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

if (-not (Test-Path $UrlsFile)) {
    Write-Host "URL file not found: $UrlsFile" -ForegroundColor Red
    exit 1
}

# Read URLs
$lines = Get-Content $UrlsFile -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }

Write-Host "Found $($lines.Count) URLs total" -ForegroundColor Green

# Apply skip and limit
if ($Skip -gt 0) {
    $lines = $lines | Select-Object -Skip $Skip
}
if ($Limit -gt 0) {
    $lines = $lines | Select-Object -First $Limit
}

Write-Host "Processing $($lines.Count) URLs (after skip/limit)" -ForegroundColor Green

# Filter for recipe-looking URLs (exclude images, feeds, etc.)
$recipeUrls = @()
foreach ($line in $lines) {
    $parts = $line -split "`t"
    if ($parts.Count -ge 2) {
        $subject = $parts[0]
        $url = $parts[1]

        # Skip non-recipe URLs
        if ($url -match '\.(jpg|jpeg|png|gif|webp)$') { continue }
        if ($url -match 'feedproxy\.google\.com') { continue }
        if ($url -match 'feeds\.feedburner\.com') { continue }
        if ($url -match 'photobucket\.com') { continue }
        if ($url -match 'amazon\.com') { continue }
        if ($url -match 'ifttt\.com') { continue }
        if ($url -match 'instagram\.com') { continue }
        if ($url -match 'facebook\.com') { continue }
        if ($url -match 'pinterest\.com') { continue }
        if ($url -match 'twitter\.com') { continue }

        $recipeUrls += @{
            Subject = $subject
            Url = $url
        }
    }
}

Write-Host "Filtered to $($recipeUrls.Count) recipe URLs" -ForegroundColor Green
Write-Host ""

# Output the URLs for manual processing
foreach ($item in $recipeUrls) {
    Write-Host "Subject: $($item.Subject)" -ForegroundColor Yellow
    Write-Host "URL: $($item.Url)" -ForegroundColor White
    Write-Host ""
}

# Save filtered URLs to a new file
$filteredFile = Join-Path (Split-Path $UrlsFile) "_filtered_recipe_urls.txt"
$recipeUrls | ForEach-Object { "$($_.Subject)`t$($_.Url)" } | Out-File -FilePath $filteredFile -Encoding UTF8
Write-Host "Filtered URLs saved to: $filteredFile" -ForegroundColor Green
