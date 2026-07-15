[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---- Step 1: Extract names from **From:** lines in NLP forum files ----
$nlpDir = 'C:\Users\awt\Sync\Obsidian\01\NLP'
$nlpFiles = Get-ChildItem -Path $nlpDir -Filter '*.md' -Recurse

# nameFiles maps name -> list of distinct source files
$nameFiles = @{}

foreach ($file in $nlpFiles) {
    $lines = Get-Content $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        # Match **From:** patterns like: **From:** Joel P. Bowman **To:** ...
        if ($line -match '\*\*From:\*\*\s+([A-Z][a-zA-Z.]+(?:\s+[A-Z][a-zA-Z.]+){1,4})') {
            $raw = $Matches[1].Trim()
            # Stop at ** bold markers
            $raw = $raw -replace '\s*\*\*.*$', ''
            $name = $raw.Trim()

            if ($name.Length -gt 4 -and $name -notmatch '^\d') {
                if (-not $nameFiles.ContainsKey($name)) {
                    $nameFiles[$name] = [System.Collections.Generic.List[string]]::new()
                }
                if (-not $nameFiles[$name].Contains($file.Name)) {
                    $nameFiles[$name].Add($file.Name)
                }
            }
        }
    }
}

Write-Output "=== NLP FORUM FROM: NAMES ==="
$nameFiles.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object {
    $ct = $_.Value.Count
    $fs = ($_.Value -join '; ')
    Write-Output "$($_.Key) | Files: $ct | $fs"
}

# ---- Step 2: Extract author: YAML fields across vault ----
Write-Output ""
Write-Output "=== AUTHOR YAML FIELDS ==="
$vaultRoot = 'C:\Users\awt\Sync\Obsidian'
$allFiles = Get-ChildItem -Path $vaultRoot -Filter '*.md' -Recurse -ErrorAction SilentlyContinue

$authors = @{}
foreach ($file in $allFiles) {
    $lines = Get-Content $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        if ($line -match '^author:\s+["\x27]?([A-Z][a-zA-Z.\x27\s,]+)["\x27]?') {
            $raw = $Matches[1].Trim().TrimEnd("'`"")
            # Skip empty, short, or institutional names
            if ($raw.Length -gt 5 -and $raw -notmatch '^(National|Collins|Fiola|Nicole|Papa|Josh|Sam|Kait|veggi|Char|Robin|Lazy)') {
                if (-not $authors.ContainsKey($raw)) {
                    $authors[$raw] = [System.Collections.Generic.List[string]]::new()
                }
                if (-not $authors[$raw].Contains($file.Name)) {
                    $authors[$raw].Add($file.Name)
                }
            }
        }
    }
}

$authors.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object {
    $ct = $_.Value.Count
    $fs = ($_.Value -join '; ')
    Write-Output "$($_.Key) | Files: $ct | $fs"
}
