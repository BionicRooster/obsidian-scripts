# Consolidate duplicate email threads
# Keep the file with highest number (most recent in thread), delete others
$vault = "D:\Obsidian\Main"
$gmail = "$vault\04 - GMail"

$deleted = @()

# Define thread patterns to consolidate
$threadPatterns = @(
    "Will replicas muddy the waters of collectability",
    "Any WSU we can get the notes from these sessions",
    "Jo & Wayne - Vegan Diet",
    "We know the answer to this question",
    "7 Things That Happen When You Stop Eating Meat",
    "Kick Off 28-Day Challenge info with Whole Foods Market",
    "Cake",
    "Dal",
    "fun with the kids",
    "Jo & Wayne - Microwave ovens"
)

foreach ($pattern in $threadPatterns) {
    Write-Host "`nProcessing thread: $pattern" -ForegroundColor Cyan

    # Find all files matching this thread
    $escapedPattern = [regex]::Escape($pattern)
    $files = Get-ChildItem -Path $gmail -Filter "*.md" | Where-Object {
        $_.Name -match $escapedPattern
    } | Sort-Object Name

    if ($files.Count -le 1) {
        Write-Host "  Only $($files.Count) file(s), skipping"
        continue
    }

    Write-Host "  Found $($files.Count) files"

    # Find the "best" file to keep:
    # - Prefer files with highest number (most recent reply)
    # - Or the original if no replies
    $keepFile = $null
    $highestNum = -1

    foreach ($file in $files) {
        # Extract number from filename like "(19).md" or "(1).md"
        if ($file.Name -match '\((\d+)\)\.md$') {
            $num = [int]$matches[1]
            if ($num -gt $highestNum) {
                $highestNum = $num
                $keepFile = $file
            }
        } elseif ($file.Name -match '\((\d+)\) \(1\)\.md$') {
            # Handle duplicate naming like "(5) (1).md"
            $num = [int]$matches[1]
            if ($num -gt $highestNum) {
                $highestNum = $num
                $keepFile = $file
            }
        }
    }

    # If no numbered file found, keep the first non-Re/Fwd file, or last file
    if ($null -eq $keepFile) {
        $originals = $files | Where-Object { $_.Name -notmatch "^(Re_|Fwd_|RE_|FW_)" }
        if ($originals.Count -gt 0) {
            $keepFile = $originals | Select-Object -Last 1
        } else {
            $keepFile = $files | Select-Object -Last 1
        }
    }

    Write-Host "  Keeping: $($keepFile.Name)" -ForegroundColor Green

    # Delete the others
    foreach ($file in $files) {
        if ($file.FullName -ne $keepFile.FullName) {
            Remove-Item -LiteralPath $file.FullName -Force
            $deleted += $file.Name
            Write-Host "  Deleted: $($file.Name)" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Total files deleted: $($deleted.Count)"
