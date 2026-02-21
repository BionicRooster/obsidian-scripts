# Comprehensive Gmail file processing
# 1. Move recipe files to 03 - Recipes
# 2. Move other categorized files to 01 subdirectories
# 3. Identify duplicate email threads

$vault = "D:\Obsidian\Main"
$gmail = "$vault\04 - GMail"
$recipesFolder = "$vault\03 - Recipes"

$moved = @()
$duplicates = @()

# ============================================
# PART 1: Identify recipe files
# ============================================
Write-Host "=== PART 1: Recipe Files ===" -ForegroundColor Cyan

# Recipe filename patterns (files with "recipe" in name)
$recipePatterns = @(
    "recipe",
    "Recipe"
)

$recipeFiles = Get-ChildItem -Path $gmail -Filter "*.md" | Where-Object {
    $name = $_.Name
    foreach ($pattern in $recipePatterns) {
        if ($name -match $pattern) { return $true }
    }
    return $false
}

Write-Host "Found $($recipeFiles.Count) potential recipe files"
foreach ($file in $recipeFiles | Select-Object -First 50) {
    Write-Host "  - $($file.Name)"
}

# ============================================
# PART 2: Other category patterns
# ============================================
Write-Host "`n=== PART 2: Other Categories ===" -ForegroundColor Cyan

$otherCategories = @{
    # Music
    "iTunes Single of the Week" = @{ Dest = "01\Music"; MOC = "MOC - Music & Record" }

    # Travel/RV
    "Long Long Honeymoon" = @{ Dest = "01\Travel"; MOC = "MOC - Travel & Exploration" }
    "The Fit RV" = @{ Dest = "01\Travel"; MOC = "MOC - Travel & Exploration" }
    "Cool Tears" = @{ Dest = "01\Travel"; MOC = "MOC - Travel & Exploration" }
    "shore excursion" = @{ Dest = "01\Travel"; MOC = "MOC - Travel & Exploration" }

    # Vintage computing/collectibles
    "replicas muddy" = @{ Dest = "01\Technology"; MOC = "MOC - Technology & Computers" }
    "collectability" = @{ Dest = "01\Technology"; MOC = "MOC - Technology & Computers" }

    # PKM/Productivity
    "Evernote" = @{ Dest = "01\PKM"; MOC = "MOC - Personal Knowledge Management" }
    "IFTTT" = @{ Dest = "01\Technology"; MOC = "MOC - Technology & Computers" }

    # Bahá'í
    "Nassem and Neda Khozein" = @{ Dest = "01\Baha'i"; MOC = "MOC - Bahá'í Faith" }
}

foreach ($pattern in $otherCategories.Keys) {
    $info = $otherCategories[$pattern]
    $files = Get-ChildItem -Path $gmail -Filter "*.md" | Where-Object { $_.Name -match $pattern }

    if ($files.Count -gt 0) {
        Write-Host "`nPattern '$pattern' -> $($info.Dest): $($files.Count) files"
        foreach ($file in $files) {
            Write-Host "  - $($file.Name)"
        }
    }
}

# ============================================
# PART 3: Identify duplicate email threads
# ============================================
Write-Host "`n=== PART 3: Duplicate Email Threads ===" -ForegroundColor Cyan

# Find files that are replies/forwards (Re:, Fwd:, RE:, FW:)
$threadFiles = Get-ChildItem -Path $gmail -Filter "*.md" | Where-Object {
    $_.Name -match "^(Re_|Fwd_|RE_|FW_)"
}

# Group by base subject (remove Re_, Fwd_, and numbered suffixes)
$threads = @{}
foreach ($file in $threadFiles) {
    $baseName = $file.Name -replace "^(Re_|Fwd_|RE_|FW_)\s*", ""
    $baseName = $baseName -replace "\s*\(\d+\)\.md$", ".md"
    $baseName = $baseName -replace "\.md$", ""

    if (-not $threads.ContainsKey($baseName)) {
        $threads[$baseName] = @()
    }
    $threads[$baseName] += $file
}

# Find threads with multiple files
$duplicateThreads = $threads.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | Sort-Object { $_.Value.Count } -Descending

Write-Host "Found $($duplicateThreads.Count) threads with duplicates"
foreach ($thread in $duplicateThreads | Select-Object -First 20) {
    Write-Host "`n  Thread: $($thread.Key) ($($thread.Value.Count) files)"
    foreach ($file in $thread.Value | Select-Object -First 5) {
        Write-Host "    - $($file.Name)"
    }
    if ($thread.Value.Count -gt 5) {
        Write-Host "    ... and $($thread.Value.Count - 5) more"
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Recipe files found: $($recipeFiles.Count)"
Write-Host "Duplicate thread groups: $($duplicateThreads.Count)"
