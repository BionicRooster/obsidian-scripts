# find_duplicates.ps1
# Scans the Obsidian vault for duplicate note filenames (same name, different folders)
# Writes results to a markdown note at the vault root.

$vaultPath   = "D:\Obsidian\Main"          # Vault root
$outputFile  = "$vaultPath\Duplicate Notes.md"  # Output note path
$excludeDirs = @('.smart-env', '.obsidian', '.git', '.trash')  # Folders to skip

Write-Host "Scanning vault for duplicate filenames..." -ForegroundColor Cyan

# Collect all .md files, skipping system folders
$allFiles = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md" | Where-Object {
    $skip = $false
    foreach ($ex in $excludeDirs) {
        if ($_.FullName -like "*\$ex\*") { $skip = $true; break }
    }
    -not $skip
}

Write-Host "  Total notes found: $($allFiles.Count)" -ForegroundColor Gray

# Group by filename (case-insensitive)
$groups = $allFiles | Group-Object { $_.Name.ToLower() } | Where-Object { $_.Count -gt 1 } | Sort-Object Name

Write-Host "  Duplicate groups found: $($groups.Count)" -ForegroundColor Yellow

# Build markdown output
$lines = @()
$lines += "---"
$lines += "created: $(Get-Date -Format 'yyyy-MM-dd')"
$lines += "tags:"
$lines += "  - maintenance"
$lines += "  - duplicates"
$lines += "---"
$lines += ""
$lines += "# Duplicate Notes"
$lines += ""
$lines += ("> Generated " + (Get-Date -Format 'yyyy-MM-dd HH:mm') + " | " + $groups.Count + " duplicate groups found across " + $allFiles.Count + " total notes.")
$lines += ""
$lines += "---"
$lines += ""

if ($groups.Count -eq 0) {
    $lines += "_No duplicate filenames found._"
} else {
    foreach ($group in $groups) {
        # Use the actual (non-lowercased) name from the first file
        $displayName = $group.Group[0].Name -replace '\.md$', ''
        $lines += "## $displayName"
        $lines += ""
        foreach ($file in $group.Group | Sort-Object FullName) {
            # Make path relative to vault root for readability
            $rel = $file.FullName.Substring($vaultPath.Length + 1) -replace '\\', '/'
            $lines += "- ``$rel``"
        }
        $lines += ""
    }
}

# Write output with UTF-8 encoding (no BOM)
$content = $lines -join "`r`n"
[System.IO.File]::WriteAllText($outputFile, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Output written to: $outputFile" -ForegroundColor Green
Write-Host "Duplicate groups: $($groups.Count)" -ForegroundColor Cyan
